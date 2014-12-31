# encoding: UTF-8

module IconHelper
  
  # definition of each and every icon
  # made accessible by icon_for(scope)
  ICONS = {
    :navigation => {
      :start_quest      => :edit,
      :quests           => :list,
      :my_quests        => :list,
      :my_offers        => :outdent,
      :received_offers  => :indent,
      :my_profile       => :user,
      :signout          => :sign_out,
      :signin           => :sign_in,
      :twitter          => :twitter_square,
      :facebook         => :facebook_square,
      :google           => :google_plus_square,
      :linkedin         => :linkedin_square,
      :xing             => :xing_square
    },
    :identity => {
      :commercial => :group,
      :private    => :user,
      :confirm    => :envelope_o,
      :signup     => :user,
      :delete     => :trash_o,
      :password   => :lock,
      :address    => :home,
      :email      => :envelope,
      :facebook   => :facebook_square,
      :twitter    => :twitter_square,
      :google     => :google_plus_square,
      :linkedin   => :linkedin_square,
      :xing       => :xing_square
    },
    :interaction => {
      :new      => :edit,
      :edit     => :pencil,
      :delete   => :trash_o,
      :start    => :gear,
      :publish  => :bullhorn,
      :stop     => :power_off,
      :offer    => :share,
      :accept   => :check_square,
      :reject   => :minus_square,
      :withdraw => :undo,
      :share    => :share_alt,
      :reply    => :reply,
      :comment  => :comment,
      :follow   => :twitter,
      :send     => :envelope
    },
    :status => {
      :new        => :pencil_square,
      :created    => :share_square,
      :active     => :bar_chart_o,
      :withdrawn  => :caret_square_o_left,
      :accepted   => :check_square,
      :rejected   => :minus_square,
      :expired    => :clock_o,
      :viewed     => :eye,
      :compliance => :bar_chart_o,
      :quests     => :list,
      :offers     => :share,
      :comments   => :comment,
      :forwards   => :retweet
    },
    :other => {
      :bounty         => :money,
      :location       => :globe,
      :picture        => :picture_o,
      :load_indicator => :refresh
    }   
  }
  
  def icon_for(scope)
    expect! scope => [String]

    icon = ICONS
    scope.split(".").each do |key|
      icon = icon[key.to_sym]
      raise "No icon defined for scope: '#{scope}'" unless icon.present?
    end

    return icon if icon.kind_of?(Symbol)
    raise "Scope is too short: '#{scope}'" 
  end

  def awesome_icon(name, *args, &block)
    hash = the_awesome_icon name, *args, &block
    options = hash[:options]
    content = hash[:content].html_safe
    content = ' ' + content unless content.empty? || content[0] == '<'
    content_tag(:i, nil, options) + content
  end
  
protected

  def the_awesome_icon(name, *args, &block)
    options = args.extract_options!
    size = options.delete(:size) if options
    content = args.first unless args.blank?
    content ||= capture(&block) if block_given?
    content ||= ''

    name = name.to_s.dasherize
    name.gsub!(/^icon-/, '')

    clazz = "fa fa-#{name}"
    clazz << " fa-#{size}" if size
    clazz << " " << options.delete(:class) if options[:class]

    options.merge!(:class => clazz)

    {:options => options, :content => content}
  end
end