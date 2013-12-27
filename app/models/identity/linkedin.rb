# encoding: UTF-8

require 'linkedin'

class Identity::Linkedin < Identity
  include Identity::PolymorphicRouting
  include Identity::Provider
  
  with_metrics! "accounts.linkedin"

  #
  # post a message on user's linkedin page
  def post(text, options={})
    expect! text => String
    expect! options => { :object => [nil, Quest] }

    Deferred.linkedin(:add_share, self.class.message(text, options[:object]), oauth_hash)
  end
  
  #
  # post a message on bountyhills's linked page
  def self.post(text, options={})
    expect! text => String
    expect! options => { :object => [nil, Quest] }

    Deferred.linkedin(:add_share, message(text, options[:object]), oauth_hash)
  end

  private
  
  #
  # sets up a message hash for a linkedin post
  # this message contains the message text, a :visibility level and if an object is given
  # a content hahs with title, description, url and an image of that object
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
      :consumer_key     => consumer_key     || Bountybase.config.linkedin_app["consumer_key"],
      :consumer_secret  => consumer_secret  || Bountybase.config.linkedin_app["consumer_secret"],
      :oauth_token      => oauth_token,
      :oauth_secret     => oauth_secret
    }
  end

  # Returns the applications's linkedin auth as a Hash.
  def self.oauth_hash
    {
      :consumer_key     => Bountybase.config.linkedin_app["consumer_key"],
      :consumer_secret  => Bountybase.config.linkedin_app["consumer_secret"],
      :oauth_token      => Bountybase.config.linkedin_app["oauth_token"],
      :oauth_secret     => Bountybase.config.linkedin_app["oauth_secret"]
    }
  end
end
