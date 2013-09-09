# encoding: UTF-8

class Identity::Deleted < Identity
  include Identity::PolymorphicRouting
  
  def soft_delete_user
    return
  end
  
end
