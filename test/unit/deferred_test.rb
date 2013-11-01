# encoding: UTF-8

require_relative "../test_helper.rb"

class DeferredTest < ActiveSupport::TestCase
  
  def test_in_background?
    assert !Deferred.in_background?
    Deferred.in_background = true
    assert Deferred.in_background?
  end
  
  def test_in_background
    assert !Deferred.in_background?
    Deferred.in_background(true) do
      assert Deferred.in_background?
    end
    assert !Deferred.in_background?
  end

  def test_method_missing
    # unknown method
    assert_raises NoMethodError do
      Deferred.foo
    end

    # known method
    Deferred.twitter :update, "foo bar", oauth_hash
    
    # known method in background
    Deferred.expects(:queue).with(:twitter).returns([])
    Deferred.in_background(true) do
      Deferred.twitter :update, "foo bar", oauth_hash
    end
  end
  
  def test_instance
    assert((instance = Deferred.instance).kind_of?(Object))
    %w(mail twitter facebook google linkedin xing).each do |method|
      assert instance.respond_to?(method)
    end
  end
  
  def create_queue_fails
    assert_raises ArgumentError do
      Deferred.create_queue("foo")
    end
  end
  
  def test_facebook
    Koala::Facebook::API.any_instance.expects(:put_connections).with("foo", "bar")

    Deferred.instance.facebook("foo", "bar", {
      :oauth_token      => "foo bar",
      :oauth_expires_at => Time.now,
    })
  end

  def test_google
    # TODO: leverage google client API here...
    
    Deferred.instance.google("foobar", oauth_hash)
  end

  def test_linkedin
    LinkedIn::Client.any_instance.expects(:add_share).with("foo", "bar")
  
    Deferred.instance.linkedin(:add_share, "foo", "bar", oauth_hash)
  end

  def test_xing
    # TODO: leverage xing client API here...
    
    Deferred.instance.xing(:create_status_message, "foobar", oauth_hash)
  end
  
  def test_twitter
    Twitter::Client.any_instance.expects(:update).with("foo bar")

    Deferred.instance.twitter(:update, "foo bar", oauth_hash)
  end
  
  def test_mail
    email = UserMailer.reset_password(Factory(:user))
    email.expects(:deliver).once

    Deferred.instance.mail(email)
  end
  
private
 def oauth_hash
   {
     :oauth_token        => "oauth_token",
     :oauth_token_secret => "oauth_secret",
     :consumer_key       => "consumer_key",
     :consumer_secret    => "consumer_secret"
   }
 end
end