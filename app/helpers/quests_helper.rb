module QuestsHelper
  
  BUTTON_SECTIONS = {
    :category => [
      :people   => { :class => "user" },
      :job      => { :class => "briefcase" },
      :home     => { :class => "home" },
      :car      => { :class => "cars" },
      :gift     => { :class => "gift" },
      :help     => { :class => "support" },
      :travel   => { :class => "earth" },
      :fashion  => { :class => "button" }
    ],
    :sort => [
      :created      => { :class => "calendar" },
      :bounty       => { :class => "diamond" },
      :temporality  => { :class => "busy" },
      :locality     => { :class => "location" }
    ],
    :order => [
      :desc => { :class => "arrow-down" },
      :asc  => { :class => "arrow-up" }
    ]
  }
  def render_buttons(section)
    expect! section => BUTTON_SECTIONS.keys
    
    BUTTON_SECTIONS[section].map do |button_definition|
      button_definition.map do |button, options|
        html_class = "icon-#{options[:class]}"
        html_class += " active" if params[section].to_s == button.to_s
        link_to("", params.slice(*params_for(:quests)).update(section => button),
                  { :class => html_class, :title => t("buttons.#{section}.#{button}") })
      end
    end.join.html_safe
  end
  
  def render_bounty_ribbon(quest)
    amount = quest.bounty.to_f
    
    if amount < 100
      bounty_class = "small"
      amount = amount.round
    elsif amount < 1000
      bounty_class = "medium"
      amount = 10 * (amount / 10).round
    else 
      bounty_class = "large"
      amount = 100 * (amount / 100).round
    end

    currency = quest.bounty.currency.to_s
    if currency == "EUR"
      currency = "&euro;"
    end
    
    div :class => "ribbon-wrapper right" do
      div :class => "ribbon #{bounty_class}" do
        "#{currency} #{amount}".html_safe
      end
    end
  end
end
