# encoding: UTF-8

require_relative "../../test_helper.rb"

class Identity::DeletedTest < ActiveSupport::TestCase
  
  def test_identity_provider?
    deleted = Identity::Deleted.new
    assert_false deleted.identity_provider?
  end
  
end