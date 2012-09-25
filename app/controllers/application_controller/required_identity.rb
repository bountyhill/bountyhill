module ApplicationController::RequiredIdentity

  def self.included(klass)
    klass.rescue_from Missing, :with => :redirect_to_identity_provider
  end
  
  def requires_identity!(*args)
    options = args.extract_options!
    kind = args.first || :any

    expect! args.length => [0, 1]
    expect! kind => [ :confirmed, :email, :twitter, :any ]
    expect! options => {
      :transfer => [ nil, ActiveRecord::Base ],
      :redirect_to => [ nil, ActiveRecord::Base, String ]
    }

    return if current_user && current_user.identity(kind)
    raise Missing, options.merge(:kind => kind)
  end

  private

  def signin(user)
    super

    return unless (signedin = session["signedin"]).is_a?(Hash)
    return unless (kind = signedin[:kind]).in?([:confirmed, :email, :twitter, :any])
    return unless @current_user.identity(kind)

    run_identity_requirement_payload
  end
  
  def run_identity_requirement_payload
    signedin = session["signedin"]
    #raise signedin.inspect
    
    if transfer = signedin[:transfer]
      @current_user.transfer! transfer
    end
    if redirect = signedin[:redirect_to]
     # raise redirect
      redirect_to! redirect
    end
  end
  
  # The Missing exception is raised by requires_identity!
  # when an identity requirement is not met. It is catched and dealt 
  # with then by redirect_to_identity_provider.
  class Missing < RuntimeError #:nodoc:
    attr_reader :options
    
    def initialize(options)
      @options = options
    end
  end
  
  # The redirect_to_identity_provider sets up the session so that the
  # run_identity_requirement_payload method gets suitable input.
  def redirect_to_identity_provider(e) #:nodoc:
    expect! e => Missing
    options = e.options

    # -- set after signin options -------------------------------------
    case transfer = options[:transfer]
    when ActiveRecord::Base
      options[:transfer] = "#{transfer.class.name}:#{transfer.id}"
    end

    case redirect = options[:redirect_to]
    when ActiveRecord::Base
      options[:redirect_to] = url_for(redirect).gsub(/^(http|https):\/\/[^\/]+/, "")
    when nil
      if request.method == "GET"
        options[:redirect_to] = request.path
      end
    end

    session["signedin"] = options

    # -- set notice text ----------------------------------------------
    if options[:kind] == :confirmed
      if current_user && current_user.identity(:email)
        notice = I18n.t("requires_identity.email")
      end
    end
    notice ||= I18n.t("requires_identity.#{options[:kind]}")

    # -- redirect to signin -------------------------------------------
    redirect_to signin_path(:req => options[:kind]), notice: notice
  end
end
