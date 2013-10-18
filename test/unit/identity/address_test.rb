# encoding: UTF-8

require_relative "../../test_helper.rb"

class Identity::AddressTest < ActiveSupport::TestCase
  def test_polymorphic_routing
    model_name = Identity::Address.model_name
    assert_equal "Identity::Address", model_name.to_s
    assert_equal "identities", model_name.route_key
    assert_equal "identity", model_name.singular_route_key
  end
  
  def test_validation
    user = Factory(:user)
    
    # non commercial users do have to provide address1, city, zipcode and country
    user.expects(:commercial?).returns(false)
    identity = Identity::Address.new
    identity.user = user
    assert_invalid identity, :address1, :city, :zipcode, :country
    
    user.expects(:commercial?).returns(false)
    identity.address1 = "street"
    identity.city     = "city"
    identity.zipcode  = "zipcode"
    identity.country  = "country"
    assert_valid identity
    
    # non commercial users do have to provide address1, city, zipcode, country, company and phone
    user.expects(:commercial?).returns(true)
    assert_invalid identity, :company, :phone
    
    user.expects(:commercial?).returns(true)
    identity.company  = "company"
    identity.phone    = "phone"
    assert_valid identity
  end
  
  def test_factory
    assert_difference "User.count", +1 do
      assert_difference "Identity.count", +1 do
        assert_difference "Identity::Address.count", +1 do
          address = Factory(:address_identity)
          assert_kind_of(Identity::Address, address)
          assert address.valid?
        end
      end
    end
  end
  
  def test_postal
    address = Identity::Address.new(
      :company  => "company",
      :address1 => "address1",
      :address2 => "address2",
      :city     => "city",
      :zipcode  => "zipcode",
      :country  => "country",
      :phone    => "phone"
    )
    assert_equal ["company", "address1", "address2", "city", "zipcode", "country"], address.postal
  end
  
  def test_commercial?
    address = Factory(:address_identity)
    address.user.expects(:commercial?)
    
    address.send :commercial?
  end
  
end