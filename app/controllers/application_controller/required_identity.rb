# encoding: UTF-8

module ApplicationController::RequiredIdentity
  H = ApplicationController::RequiredIdentity

  # Make sure the user is logged in with a specific (or any) identity.
  # If the user is not logged in or if his login does not provide the
  # requested identity, she will be asked for it using the /sessions
  # controller. On success the user will be redirected to the _success_
  # target URL.
  #
  # The user might cancel providing his/her identity, in which case
  # she will be redirected to the _cancel_ target.
  #
  # Redirection targets can be passed in either as URL strings or as
  # ActiveRecord models. In the latter case the redirection
  # shows the #show action.
  #
  # Parameters:
  #  - request_identity! mode, options
  #  - request_identity! options
  #  - request_identity! mode
  #
  # The +mode+ parameter is one of the supported authentication modi
  # (e.g. <tt>:confirmed</tt>, <tt>:email</tt>, <tt>:twitter</tt>, <tt>:facebook</tt>, <tt>:google</tt>, <tt>:linkedin</tt>, <tt>:xing</tt>, <tt>:login</tt>, <tt>:any</tt>)
  # and defaults to :any.
  #
  # - <tt>:on_cancel</tt> URL to redirect to when user cancels authentication.
  # - <tt>:on_success</tt> URL to redirect to when user authentication succeeds.
  # - <tt>:notice</tt> the redirection notice to show to the user.
  #
  # Examples: Secure non-destructive (read: "GET") actions by requiring the user
  # to log in.
  #
  #   def index
  #     request_identity!
  #     ...
  #   end
  #
  # Example: request an identity before running a specific action. Note:
  # "start" usually responds to a POST request (i.e. to a form), while 
  # "do_start" must be a GET action.
  #
  #   def start
  #     # handle form data.
  #     # return if failed.
  #     do_start
  #   end
  #
  #   def do_start
  #     request_identity! :twitter, :on_cancel => root_path
  #     share.post(:twitter)
  #   end
  
  REQUESTBALE_IDENTITIES = [ :confirmed, :email, :twitter, :facebook, :google, :linkedin, :xing, :address, :login, :any ]
  
  def request_identity!(*args)
    options = args.extract_options!
    kind = args.first || options[:kind] || :any

    expect! request.method => "GET"
    expect! args.length => [0, 1]
    expect! kind => REQUESTBALE_IDENTITIES
    expect! options => {
      :on_success  => [ nil, ActiveRecord::Base, String ],
      :on_cancel   => [ nil, ActiveRecord::Base, String ],
      :notice      => [ nil, String ]
    }
    
    # does the user already provide the requested identity?
    if identity?(kind)
      if options[:on_success]
        redirect_after_identity_provided! options[:on_success] 
      end
      return
    end

    # Ask for email, if we need a *confirmed* email, but don't even have an unconfirmed yet.
    if kind == :confirmed && !identity?(:email)
      kind = :email
    end
    
    # Ask for confirmed, if we need a *login* identity, but have just an unconfirmed email yet
    if kind == :login && (email = identity?(:email)).present? && !email.confirmed?
      kind = :confirmed
    end

    # -- fetch notice text --------------------------------------------
    notice = options.delete(:notice)
    notice ||= I18n.t("identity.required.#{kind}")

    # -- prepare payload ----------------------------------------------
    
    # Normalize options: store uids instead of AR::Base objects.
    options.keys.each do |key|
      target = options[key]
      options[key] = target.uid if target.is_a?(ActiveRecord::Base)
    end

    # a default on_success redirection. This allows to secure non-
    # destructive (read: "GET") actions by just adding on top:
    #
    #   request_identity! :email
    #
    options[:on_success] ||= request.url

    # set payload
    H.set_payload session, options.merge(:kind => kind)

    # -- start signing in ---------------------------------------------
    redirect_to! signin_path(:req => kind), :notice => notice
  end

  private

  def redirect_after_identity_provided!(target) #:nodoc:
    # redirect to the target
    model = target if target.is_a?(ActiveRecord::Base)
    model ||= ActiveRecord::Base.by_uid(target)

    redirect_to! model ? url_for(model) : target
  end

  # -- storing/fetching payload ---------------------------------------

  SESSION_KEY = "identity"

  # fetch payload of a given \a kind from the \a session
  def self.payload(session) #:nodoc:
    payload = session[SESSION_KEY]
    
    # validate identity payload, just to be sure.
    return unless payload.is_a?(Hash)
    return unless payload[:kind].in?(REQUESTBALE_IDENTITIES)
    
    payload
  end

  # fetch and delete payload of a given \a kind from the \a session
  def self.delete_payload(session) #:nodoc:
    payload(session)
  ensure
    session.delete(SESSION_KEY)
  end

  # store the payload in the session. 
  def self.set_payload(session, payload) #:nodoc:
    if payload
      session[SESSION_KEY] = payload
    else
      session.delete SESSION_KEY
    end
  end
  
  #
  # checks if the given identity was requested lately
  def identity_requested?(kind)
    expect! kind => REQUESTBALE_IDENTITIES
    
    (payload = H.payload(session)) && payload[:kind] == kind
  end
  
  # -- identity provisioning result: identity_presented! and identity_cancelled!
  # are called when the user either presented an identity or cancelled the 
  # provisioning process. Both identity_cancelled! and identity_presented!
  # redirect in any case and do not return.
  
  # The user presented the specified identity.
  def identity_presented!
    unless payload = H.delete_payload(session)
      redirect_to! root_path
    end
    
    # on_success redirection if the requested identity exists now.
    if identity?(payload[:kind])
      redirect_after_identity_provided! payload[:on_success] || root_path
    end

    # Re-request the requested identity, when a wrong identity has been
    # provided, e.g.
    # - the website requests an email, user signs in via twitter instead, or
    # - a :confirmed email was requested, but the site asked for an :email first
    #
    # Note: The user *must press cancel* to cancel the identity request.
    request_identity! payload
  end

  # Call this method when the user cancelled the identity, for example
  # if the user pressed Cancel on a login form.
  def identity_cancelled!
    payload = H.delete_payload(session) || {}
    redirect_after_identity_provided! payload[:on_cancel] || root_path
  end
end
