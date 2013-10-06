# encoding: UTF-8

require_relative "../../test_helper.rb"

class Identity::EmailTest < ActiveSupport::TestCase
  def test_polymorphic_routing
    model_name = Identity::Email.model_name
    assert_equal "Identity::Email", model_name.to_s
    assert_equal "identities", model_name.route_key
    assert_equal "identity", model_name.singular_route_key
  end
  
  def test_authenticate
    email     = "foo.bar@example.com"
    password  = "foobar"
    Factory(:email_identity, :email => email, :password => password)
    
    assert  Identity::Email.authenticate(email, password)
    assert !Identity::Email.authenticate(email, "barfoo")
  end

  def test_confirmed?
    identity = Identity::Email.new
    assert !identity.confirmed?
    
    identity.confirmed_at = Time.now
    assert identity.confirmed?
  end
  
  def test_confirm!
    identity = Factory(:email_identity)
    assert !identity.confirmed?
    
    identity.confirm!(false)
    assert !identity.confirmed?

    identity.confirm!(true)
    assert identity.confirmed?
  end
  
  def test_create_email_identity_sends_confirmation_email
    email = Identity::Email.new(:email => "foo.bar@example.com", :password => "foobar", :password_confirmation => "foobar")
    email.expects(:send_confirmation_email)
    email.save!
  end
  
  def test_send_confirmation_email
    identity = Factory(:email_identity)
    
    Deferred.expects(:mail).with(true)
    UserMailer.expects(:confirm_email).with(identity.user).returns(true)
    
    identity.send(:send_confirmation_email)
  end
  
  def test_identity_provider?
    email = Identity::Email.new
    assert_false email.identity_provider?
  end
  
  
end