# SQL-based access control
module ActiveRecord::AccessControl
  # returns the current user for the AccessControl module.
  def self.current_user
    Thread.current[:ar_current_user]
  end

  def self.current_user=(user)
    expect! user => [User, nil]

    Thread.current[:ar_current_user] = user
  end

  # runs a block as a specific user.
  def self.as(user, &block)
    old_user = self.current_user
    self.current_user = user
    yield
  ensure
    self.current_user = old_user
  end

  # enable SQL-based access control on objects of this class.
  # This method sets a default_scope to honor an access_control
  # scope as defined by the access_control parameters.
  #
  # In addition it adds code to maintain an owner_id column.
  def access_control(mode = nil, &block)
    expect! mode => [nil, :none, :owner, :visibility]

    setup_access_control

    self.read_access = resolve_access_proc(mode, &block)
  end
  
  # set a block for write_access_control. The block must return an
  # ActiveRecord scope, which is used to verify a user's access to a 
  # to-be-written object. If no block is returned (but false or nil
  # instead) write access is denied.
  #
  # If no write_access_control is set, the AccessControl module assumes
  # that a record was read via ActiveRecord default scope and thus has
  # read access already. 
  #
  # Use this method if you need tighter access control for writing than
  # for reading; a class with a :visibility access_control should use
  # a different write_access_control mode, e.g. :owner.
  #
  # Example:
  #
  #   write_access_control do
  #   end
  def write_access_control(mode = nil, &block)
    setup_access_control
    self.write_access = resolve_access_proc(mode, &block)
  end

  def resolve_access_proc(mode, &block) #:nodoc:
    case mode
    when nil 
      block
    when :none
      lambda do |user|
        where("TRUE")
      end
    when :owner
      lambda do |user| 
        if user
          where("owner_id=?", user.id) 
        else
          where("FALSE") 
        end
      end
    when :visibility
      lambda do |user|
        if user
          where("owner_id=? OR visibility=?", user.id, "public")
        else
          where("visibility=?", "public")
        end
      end
    end
  end
  
  # prepare class attributes, hooks, callbacks, etc. 
  def setup_access_control #:nodoc:
    include InstanceMethods
    
    belongs_to :owner, :class_name => "User"
    
    cattr_accessor :read_access
    cattr_accessor :write_access

    # returns the default scope for these models.
    default_scope do
      user = ActiveRecord::AccessControl.current_user
      if user && user.admin?
        where("TRUE")
      else
        read_access.call(user) || where("FALSE")
      end
    end
  end
  
  module InstanceMethods
    def self.included(other)
      other.after_initialize :initialize_owner
      other.before_destroy :permission_denied!, :unless => :writable?
      other.validate :permission_denied, :unless => :writable?
    end
    
    def initialize_owner
      # When an object gets loaded from the database and initialized this
      # method will be called. At this point the owner is quite likely not
      # initialized yet; the owner_id attribute, on the other hand, is. 
      # That means checking whether there is an owner results in a DB lookup.
      #
      # By testing against owner_id we save this DB lookup. If it is set
      # (because the object is loaded from the database and has an owner_id
      # value) we don't check for the owner and let Rails do that later -
      # if this is required at all.
      if self.owner_id.nil?
        self.owner ||= ActiveRecord::AccessControl.current_user
      end
    end

    def permission_denied!
      permission_denied
      raise ActiveRecord::RecordInvalid, self
    end
    
    def permission_denied
      self.errors.add :base, I18n.t(:"permission denied")
    end
      
    # Returns true if the currently logged in user may write this
    # model. Write access is granted if
    #
    # - the current_user is an admin, or
    # - a write_access_proc scope is set up and the current_user
    #   is able to access the model through it, or
    # - there is no write_access_proc, 
    # - this is a new record.
    #
    # Write access is denied if the current_user is not logged in.
    def writable?(user = ActiveRecord::AccessControl.current_user)
      if !user
        false
      elsif user.admin?
        true
      elsif user == owner
        true
      elsif (write_access = self.write_access).nil?
        true
      elsif scope = write_access.call(user)
        scope.where(:id => self.id).count == 1
      else
        false
      end
    end
  end
end

ActiveRecord::Base.extend ActiveRecord::AccessControl