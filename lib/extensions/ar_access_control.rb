# SQL-based access control
module ActiveRecord::AccessControl
  # returns the current user for the AccessControl module.
  def self.current_user
    Thread.current[:ar_current_user]
  end

  def self.current_user=(current_user)
    expect! user => [User, nil]

    Thread.current[:ar_current_user] = current_user
  end

  # runs a block as a specific user.
  def self.as(user, &block)
    self.current_user = user
    yield
  ensure
    self.current_user = nil
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
        {} 
      end
    when :owner
      lambda do |user| 
        where("owner_id=?", user.id) if user
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

    validate do |record|
      user = ActiveRecord::AccessControl.current_user
      self.owner_id ||= user && user.id  
      self.errors.add :base, :"permission denied".t unless record.writable?(user)
    end

    # returns the default scope for these models.
    default_scope do
      user = ActiveRecord::AccessControl.current_user
      if user && user.admin?
        {}
      else
        read_access.call(user) || where("FALSE")
      end
    end
  end
  
  module InstanceMethods
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
      return @is_writable unless @is_writable.nil?

      @is_writable = if !user
        false
      elsif user.admin?
        true
      elsif new_record?
        true
      elsif (write_access = self.write_access).nil?
        true
      elsif scope = write_access.call(user)
        scope.where(:id => model.id).count == 1
      else
        false
      end
    end
  end
end

ActiveRecord::Base.extend ActiveRecord::AccessControl