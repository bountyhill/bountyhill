# encoding: UTF-8

require 'linkedin'

class Identity::Linkedin < Identity
  include Identity::PolymorphicRouting
  include Identity::Provider
  
  before_create :set_expiration

  with_metrics! "accounts.linkedin"

  #
  # consider Linkedin API as accessible as long as oauth token and oauth secret are given
  # and the token is not expiring within within the next hour
  def api_accessible?
    oauth_token.present? && oauth_secret.present? && (!oauth_expires || (Time.now+1.hour).to_i < oauth_expires_at.to_i)
  end

  # -- Linkedin actions ------------------------------------------------

  #
  # post a message on user's linkedin page
  def post(text, options={})
    expect! text => String
    expect! options => { :object => [nil, Quest] }

    Deferred.linkedin(:add_share, self.class.message(text, options[:object]), oauth_hash)
  end
  
  #
  # post a message on bountyhills's linkedin page, which is refered as
  # 'Creating Company Shares' - see: http://developer.linkedin.com/creating-company-shares
  def self.post(text, options={})
    expect! text => String
    expect! options => { :object => [nil, Quest] }

    Deferred.linkedin(:add_company_share, Bountybase.config.linkedin_app["page_id"], message(text, options[:object]), oauth_hash)
  end

  private
  
  #
  # sets up a message hash for a linkedin post
  # this hash contains the message text, a :visibility level and if an object is given
  # a content hash with title, description, url and an image of that object
  def self.message(text, object=nil)
    details = { :comment => text, :visibility => { :code => 'anyone' }}
    
    details[:content] = {
      :title                => object.title,
      :description          => sanitizer.sanitize(object.description, :tags=>[]),
      :submitted_url        => object.url,
      :submitted_image_url  => object.images(:width => 180, :height => 110).first
    } if object
    
    details
  end
  
  # Returns the linkedin auth as a Hash. While one might be tempted to
  # just use the Identity::Facebook object to pass this around, we'll
  # need it in an extra object, because it will be passed into background
  # and should not be bound to any ActiveRecord-related objects.
  def oauth_hash
    {
      :consumer_key       => consumer_key     || Bountybase.config.linkedin_app["consumer_key"],
      :consumer_secret    => consumer_secret  || Bountybase.config.linkedin_app["consumer_secret"],
      :oauth_token        => oauth_token,
      :oauth_token_secret => oauth_secret
    }
  end

  # Returns the applications's linkedin auth as a Hash.
  def self.oauth_hash
    {
      :consumer_key       => Bountybase.config.linkedin_app["consumer_key"],
      :consumer_secret    => Bountybase.config.linkedin_app["consumer_secret"],
      :oauth_token        => Bountybase.config.linkedin_app["oauth_token"],
      :oauth_token_secret => Bountybase.config.linkedin_app["oauth_secret"]
    }
  end
  
  def set_expiration
    return if extra.nil?
    if (expires_in = extra["access_token"] &&
        extra["access_token"].respond_to?(:params) &&
        extra["access_token"].params["oauth_expires_in"])
      self.credentials ||= {}
      self.credentials["expires"]    = true
      self.credentials["expires_at"] = Time.now.to_i + expires_in
    end
  end
end
