# encoding: UTF-8

require 'xing'

class Identity::Xing < Identity
  include Identity::PolymorphicRouting
  include Identity::Provider
  
  with_metrics! "accounts.xing"

  #
  # consider Xing API as accessible as long as an oauth token and an oauth secret
  # is present since these tokens are needed to access the API and do never expire
  def api_accessible?
    oauth_token.present? && oauth_secret.present?
  end

  # -- Xing actions ------------------------------------------------

  #
  # post a message on user's xing page
  def post(text, options={})
    expect! text => String
    expect! options => { :object => [nil, Quest] }
    
    Deferred.xing(:create_status_message, self.class.message(text, options[:object]), oauth_hash)
  end
  
  
  #
  # post a message on bountyhills's xing page
  # TODO: currently the Xing API does not provide any interaction on company pages
  # nevertheless there is an announcement to provide 'Company Profiles' in the API
  # see: https://dev.xing.com/overview in the 'Next to come' section
  def self.post(text, options={})
    return
    
    # expect! text => String
    # expect! options => { :object => [nil, Quest] }
    # 
    # Deferred.xing(:create_status_message, message(text, options[:object]), oauth_hash)
  end

  private
  
  #
  # sets up a message text for a xing post
  def self.message(text, object=nil)
    object.present? ? "#{text} #{object.url}" : text
  end
  
  # Returns the xing auth as a Hash. While one might be tempted to
  # just use the Identity::Facebook object to pass this around, we'll
  # need it in an extra object, because it will be passed into background
  # and should not be bound to any ActiveRecord-related objects.
  def oauth_hash
    {
      :consumer_key       => consumer_key     || Bountybase.config.xing_app["consumer_key"],
      :consumer_secret    => consumer_secret  || Bountybase.config.xing_app["consumer_secret"],
      :oauth_token        => oauth_token,
      :oauth_token_secret => oauth_secret
    }
  end

  # Returns the applications's xing auth as a Hash.
  def self.oauth_hash
    {
      :consumer_key       => Bountybase.config.xing_app["consumer_key"],
      :consumer_secret    => Bountybase.config.xing_app["consumer_secret"],
      :oauth_token        => Bountybase.config.xing_app["oauth_token"],
      :oauth_token_secret => Bountybase.config.xing_app["oauth_secret"]
    }
  end
end
