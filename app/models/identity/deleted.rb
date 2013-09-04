# encoding: UTF-8

class Identity::Deleted < Identity

  # Fix Rails' polymorphic routes
  def self.model_name #:nodoc:
    Identity.model_name
  end
  
  def soft_delete_user
    return
  end
  
end
