# encoding: UTF-8

require_relative "../../test_helper.rb"

class Identity::DeletedTest < ActiveSupport::TestCase
  def test_polymorphic_routing
    model_name = Identity::Deleted.model_name
    assert_equal "Identity::Deleted", model_name.to_s
    assert_equal "identities", model_name.route_key
    assert_equal "identity", model_name.singular_route_key
  end
end