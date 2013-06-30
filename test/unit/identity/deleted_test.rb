require_relative "../../test_helper.rb"

class Identity::DeletedTest < ActiveSupport::TestCase
  
  def test_model_name
    assert_equal Identity::Deleted.model_name, Identity.model_name
  end
  
end