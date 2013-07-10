module OffersHelper

  def offer_box(offer, options={})
    expect! offer => Offer
    
    title =  I18n.t("offer.box.title", :precentage => offer.send(:compliance).to_s)
    box(:offer, offer, { :title => title }.merge(options))
  end
  
  def offers_list_box(offers)
    expect! offers        => ActiveRecord::Relation
    expect! offers.first  => [Offer, nil]
    
    list_box(:offers, offers)
  end
  
  def offers_list_box_buttons
    # TODO
  end

  def offer_buttons(offer)
    button_group [
      make_offer_button(offer),
      accept_offer_button(offer),
      reject_offer_button(offer),
      withdraw_offer_button(offer)
    ]
  end

  def make_offer_button(offer, options={})
    return unless current_user
    return unless offer.new? && current_user.owns?(offer)
    
    modal_awesome_button(:ok_circle, activate_offer_path(offer), options) { I18n.t("button.offer") }
  end

  def accept_offer_button(offer)
    return unless current_user
    return unless offer.active? && !current_user.owns?(offer)

    modal_awesome_button(:ok_circle, accept_offer_path(offer)) { I18n.t("button.accept") }
  end

  def reject_offer_button(offer)
    return unless current_user
    return unless offer.active? && !current_user.owns?(offer)

    modal_awesome_button(:remove_sign, reject_offer_path(offer)) { I18n.t("button.reject") }
  end
  
  def withdraw_offer_button(offer)
    return unless current_user
    return unless offer.active? && current_user.owns?(offer)

    modal_awesome_button(:remove_sign, withdraw_offer_path(offer)) { I18n.t("button.withdraw") }
  end
    
  def offer_statistic(offer)
    statistic_entries =  []
    
    statistic_entries << case offer.state
      when 'active'     then awesome_icon(:bar_chart) + I18n.t("offer.compliance", :precentage => offer.compliance)
      when 'new'        then awesome_icon(:file_alt)  + I18n.t("offer.states.new")
      when 'withdrawn'  then awesome_icon(:hand_down) + I18n.t("offer.states.withdrawn")
      when 'accepted'   then awesome_icon(:smile)     + I18n.t("offer.states.accepted")
      when 'rejected'   then awesome_icon(:frown)     + I18n.t("offer.states.rejected")
      else raise "Unknown offer state: #{offer.state}"
      end
    statistic_entries << awesome_icon(:picture)   + I18n.t("offer.list.images", :count => offer.images.size)   if offer.images.present?
    
    ul :class => "stats-list" do
      statistic_entries.map{ |entry| li(entry) }.join.html_safe
    end
  end
  
  def offer_compliance(offer, options={})
    value = options[:value] || offer.compliance.to_s
    label = options[:label] || I18n.t("offer.compliance", :precentage => value)
    css   = options[:class] || "progress"
    
    div :class => css do
      div label, :class => "bar", :style => "width: #{value}%;"
    end
  end
  
  def offers_box(offerable, options={})
    expect! offerable => [Quest]
    
    offers = offerable.offers.for_user(current_user)
    header = div :class => "header" do
      [
        div(I18n.t("offer.list.title", :count => offers.count), :class => "pull-left"),
        div(:class => "pull-right") do
          button_group [
            new_offer_button(offerable)
          ]
        end
      ].compact.join.html_safe
    end
    
    content = div :class => "content" do
      ul(:class => "offers list") do
        offers.map do |offer|
          li :class => "offer", :id => dom_id(offer) do
            partial "offers/list_item", :offer => offer
          end
        end.compact.join.html_safe
      end
    end

    div :class => "offers list box row-fluid  #{options[:class]}" do
      header + content
    end
  end
  
  def offers_state_filters(filters=[])
    filter_box(:offer, :states, filters, :title => I18n.t("filter.states.title"), :active => params[:state])
  end

  def offer_statistic_boxes(offer)
    [
      offer_compliance_statistic_box(offer),
      offer_created_statistic_box(offer),
      offer_viewed_statistic_box(offer),
      offer_comments_statistic_box(offer)
    ].compact.map{ |box| box + spacer(:class => "small") }.join.html_safe
  end

  def offer_compliance_statistic_box(offer)
    statistic_box "#{offer.compliance}%",
      I18n.t("offer.statistic.compliance"),
      awesome_icon(:bar_chart, :size => :large), :css_class => "offer"
  end
  
  def offer_viewed_statistic_box(offer)
    return unless offer.viewed_at

    days = distance_of_time_in_days_to_now(offer.viewed_at)
    statistic_box((days.zero? ? "#" : days),
      I18n.t("offer.statistic.viewed", :count => days),
      awesome_icon(:eye_open, :size => :large), :css_class => "offer"
    )
  end
  
  def offer_created_statistic_box(offer)
    return unless offer.active?
    
    days = distance_of_time_in_days_to_now(offer.created_at)
    statistic_box((days.zero? ? "#" : days),
      I18n.t("offer.statistic.created", :count => days),
      awesome_icon(:time, :size => :large), :css_class => "offer"
    )
  end
  
  def offer_comments_statistic_box(offer)
    statistic_box offer.comments.count,
      I18n.t("offer.statistic.comments"),
      awesome_icon(:comment, :size => :large), :css_class => "offer"
  end
  
end
