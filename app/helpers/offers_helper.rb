# encoding: UTF-8

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
  
  def offer_buttons(offer)
    button_group [
      contact_owner_button(offer),
      edit_offer_button(offer),
      make_offer_button(offer),
      accept_offer_button(offer),
      reject_offer_button(offer),
      withdraw_offer_button(offer)
    ]
  end

  def make_offer_button(offer, options={})
    return unless current_user
    return unless offer.new? && current_user.owns?(offer)
    
    modal_awesome_button(icon_for('interaction.offer'), activate_offer_path(offer), options) { I18n.t("button.offer") }
  end
  
  def edit_offer_button(offer)
    return unless current_user
    return unless offer.new? && current_user.owns?(offer)

    awesome_button(icon_for('interaction.edit'), edit_offer_path(offer)) { I18n.t("button.edit") }
  end

  def accept_offer_button(offer)
    return unless current_user
    return unless offer.active? && current_user.owns?(offer.quest)

    modal_awesome_button(icon_for('interaction.accept'), accept_offer_path(offer)) { I18n.t("button.accept") }
  end

  def reject_offer_button(offer)
    return unless current_user
    return unless offer.active? && current_user.owns?(offer.quest)

    modal_awesome_button(icon_for('interaction.reject'), reject_offer_path(offer)) { I18n.t("button.reject") }
  end
  
  def withdraw_offer_button(offer)
    return unless current_user
    return unless offer.active? && current_user.owns?(offer)

    modal_awesome_button(icon_for('interaction.withdraw'), withdraw_offer_path(offer)) { I18n.t("button.withdraw") }
  end
    
  def offer_statistic(offer)
    statistic_entries =  []
    
    statistic_entries << case offer.state
      when 'active'     then awesome_icon(icon_for('status.active'))    + I18n.t("offer.compliance", :precentage => offer.compliance)
      when 'new'        then awesome_icon(icon_for('status.new'))       + I18n.t("offer.states.new")
      when 'withdrawn'  then awesome_icon(icon_for('status.withdrawn')) + I18n.t("offer.states.withdrawn")
      when 'accepted'   then awesome_icon(icon_for('status.accepted'))  + I18n.t("offer.states.accepted")
      when 'rejected'   then awesome_icon(icon_for('status.rejected'))  + I18n.t("offer.states.rejected")
      else raise "Unknown offer state: #{offer.state}"
      end
    statistic_entries << awesome_icon(icon_for('other.picture')) + I18n.t("offer.list.images", :count => offer.images.size)   if offer.images.present?
    
    ul :class => "stats-list" do
      statistic_entries.map{ |entry| li(entry) }.join.html_safe
    end
  end
  
  def offer_responses(offer)
    responses = []
    comments  = offer.comments.size
    
    responses << circle_link_to(comments, offer_path(offer, :anchor => 'comments'),
      :class  => 'comments',
      :id     => "comments-#{dom_id(offer)}",
      :title  => I18n.t("offer.info.comments", :count => comments)) unless comments.zero?
    
    div :class => 'responses' do
      responses.map{ |response| response }.join.html_safe
    end unless responses.blank?
  end
  
  def offer_compliance(offer, options={})
    value = options[:value] || offer.compliance.to_s
    css   = options[:class] || "progress"
    
    div :class => css do
      [
        div(:class => "bar-container") { div("&nbsp;", :class => "bar", :style => "width: #{value}%;") },
        div(value,  :class => "value")
      ].join.html_safe
    end
  end
  
  def offers_box(offerable, options={})
    expect! offerable => [Quest]
    
    offers = offerable.offers.for_user(current_user)
    header = div :class => "header" do
      [
        div(I18n.t("offer.list.title", :count => offers.count), :class => "title"),
        div(:class => "interactions") do
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
    filter_box(:offer, :states, filters, :title => I18n.t("filter.states.title"), :active => params[:state], :class => "states")
  end

  def offer_statistic_boxes(offer)
    [
      offer_compliance_statistic_box(offer),
      offer_created_statistic_box(offer),
      offer_viewed_statistic_box(offer),
      offer_comments_statistic_box(offer)
    ].compact.map{ |box| box + spacer }.join.html_safe
  end

  def offer_compliance_statistic_box(offer)
    statistic_box "#{offer.compliance}%",
      I18n.t("offer.statistic.compliance"),
      awesome_icon(icon_for('status.compliance')), :css_class => "offer"
  end
  
  def offer_viewed_statistic_box(offer)
    return unless offer.viewed_at

    days = distance_of_time_in_days_to_now(offer.viewed_at)
    statistic_box((days.zero? ? "#" : days),
      I18n.t("offer.statistic.viewed", :count => days),
      awesome_icon(icon_for('status.viewed')), :css_class => "offer"
    )
  end
  
  def offer_created_statistic_box(offer)
    return unless offer.active?
    
    days = distance_of_time_in_days_to_now(offer.created_at)
    statistic_box((days.zero? ? "#" : days),
      I18n.t("offer.statistic.created", :count => days),
      awesome_icon(icon_for('status.created')), :css_class => "offer"
    )
  end
  
  def offer_comments_statistic_box(offer)
    statistic_box offer.comments.count,
      I18n.t("offer.statistic.comments"),
      awesome_icon(icon_for('status.comments')), :css_class => "offer"
  end
  
end
