module ApplicationController::RequiredIdentity
  def requires_identity!(*args)
    # validate arguments
    options = args.extract_options!
    kind = args.first || :any

    expect! args.length => [0, 1]
    expect! kind => [ :confirmed, :email, :twitter, :any ]
    expect! options => {
      :on_complete => [ nil, ActiveRecord::Base, String ],
      :on_success  => [ nil, ActiveRecord::Base, String ],
      :on_cancel   => [ nil, ActiveRecord::Base, String ]
    }

    # does the user already has the identity?
    if current_user && current_user.identity(kind)
      redirect_after_identity_provided!(options, :on_success, :on_complete)
      return
    end

    # -- prepare payload ----------------------------------------------
    
    # Normalize options: store uids instead of AR::Base objects.
    options.keys.each do |key|
      target = options[key]
      options[key] = target.uid if target.is_a?(ActiveRecord::Base)
    end

    # a default on_success redirection.
    options[:on_success] ||= request.path if request.method == "GET"

    # set payload
    H.set_payload session, kind, options

    # -- fetch notice text --------------------------------------------
    
    notice = I18n.t("requires_identity.#{kind}")

    # If we need a confirmed email, but not even have an email yet,
    # we ask for the email first.
    if kind == :confirmed
      if !current_user || !current_user.identity(:email)
        notice = I18n.t("requires_identity.email")
      end
    end

    # -- start signing in ---------------------------------------------
    redirect_to! signin_path(:req => kind), notice: notice
  end

  private

  def redirect_after_identity_provided!(payload, *args) #:nodoc:
    # find and resolve a redirection target
    return unless target = payload.values_at(*args).compact.first

    # finally redirect.
    model = target if target.is_a?(ActiveRecord::Base) 
    model ||= ActiveRecord::Base.by_uid(target)

    redirect_to! model ? url_for(model) : target
  end
  
  module H
    SESSION_KEY = "identity"

    # fetch payload of a given \a kind from the \a session
    def self.payload(session, kind) #:nodoc:
      payload = session[SESSION_KEY]

      if payload.is_a?(Hash) && payload[:kind].in?([:confirmed, :email, :twitter, :any])
        session.delete SESSION_KEY
        if kind == :any || kind == payload[:kind]
          payload 
        end
      end
    end

    def self.set_payload(session, kind, payload)
      session[SESSION_KEY] = payload.merge(:kind => kind)
    end
  end
  
  # Call this method when the user presented the specified identity,
  # e.g. logged in via the signin or signup forms.
  def identity_presented!(kind, cancelled = nil)
    return unless payload = H.payload(session, kind)
    
    unless cancelled
      expect! current_user.identity(kind) => :truish
      redirect_after_identity_provided! payload, :on_success, :on_complete
    else
      expect! current_user.identity(kind) => nil
      redirect_after_identity_provided! payload, :on_cancel, :on_complete
    end
  end

  # Call this method when the user cancelled the identity, for example
  # if the user pressed Cancel on a login form.
  def identity_cancelled!(kind)
    identity_presented! kind, :cancelled
  end
end
