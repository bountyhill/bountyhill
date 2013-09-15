# encoding: UTF-8

module Identity::PolymorphicRouting
  
  def self.included(base)

    #
    # Fix Rails' polymorphic routes
    # see http://stackoverflow.com/questions/4507149/best-practices-to-handle-routes-for-sti-subclasses-in-rails
    base.model_name.class_eval do
      def route_key
        "identities"
      end
      def singular_route_key
        "identity"
      end
    end

    #
    # Fix Rails' polymorphic routes - old version
    # base.class_eval do
    #   def self.model_name
    #     Identity.model_name
    #   end
    # end
    
  end

end