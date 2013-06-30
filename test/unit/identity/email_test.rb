require_relative "../../test_helper.rb"

class Identity::EmailTest < ActiveSupport::TestCase
  def test_model_name
    assert_equal Identity::Email.model_name, Identity.model_name
  end
  
  def test_authenticate
    email     = "foo.bar@example.com"
    password  = "foobar"
    Factory(:identity, :email => email, :password => password)
    
    assert  Identity::Email.authenticate(email, password)
    assert !Identity::Email.authenticate(email, "barfoo")
  end

  def test_avatar
    email     = "foo.bar@example.com"
    options   = { :foo => "foo", :bar => "bar" }
    identity  = Identity::Email.new(:email => email)
    
    Gravatar.expects(:url).with(options.merge(:email => email))
    identity.avatar(options)
  end

  def test_confirmed?
    identity = Identity::Email.new
    assert !identity.confirmed?
    
    identity.confirmed_at = Time.now
    assert identity.confirmed?
  end
  
  def test_confirm!
    identity = Factory(:identity)
    assert !identity.confirmed?
    
    identity.confirm!(false)
    assert !identity.confirmed?

    identity.confirm!(true)
    assert identity.confirmed?
  end
  
  def test_send_confirmation_email
    identity = Factory(:identity)
    
    Deferred.expects(:mail).with(true)
    UserMailer.expects(:confirm_email).with(identity.user).returns(true)
    
    identity.send(:send_confirmation_email)
  end
  
end