module OffersHelper

  def offer_box(offer)
    expect! offer => Offer
    
    box(:offer, offer, :title => I18n.t("offer.box.title", :precentage => offer.send(:compliance).to_s))
  end
  
  def offers_list_box(offers)
    expect! offers        => ActiveRecord::Relation
    expect! offers.first  => [Offer, nil]
    
    list_box(:offers, offers)
  end
  
  def offers_list_box_buttons
    box_buttons [
      TODO
    ]
  end

  def offer_buttons(offer)
    ul :class => "interactions" do
      [
        accept_offer_button(offer),
        reject_offer_button(offer),
        withdraw_offer_button(offer)
      ].compact.map{|button| li(button)}.join.html_safe
    end
  end

  def accept_offer_button(offer)
    return unless !offer.active? && offer.owner != current_user

    modal_link_to(awesome_icon(:icon_ok_circle) + content_tag(:span, t("button.accept")),
      accept_offer_path(offer),
      :title => t("button.accept"), :rel => "nofollow")
  end

  def reject_offer_button(offer)
    return unless !offer.active? && offer.owner != current_user

    modal_link_to(awesome_icon(:icon_remove_sign) + content_tag(:span, t("button.reject")),
      reject_offer_path(offer),
      :title => t("button.reject"), :rel => "nofollow")
  end
  
  def withdraw_offer_button(offer)
    return unless !offer.active? && offer.owner == current_user

    modal_link_to(awesome_icon(:icon_remove_sign) + content_tag(:span, t("button.withdraw")),
      withdraw_offer_path(offer),
      :title => t("button.withdraw"), :rel => "nofollow")
  end
    
  def offer_statistic(offer)
    dl(:class => "statistic") do
      offer_statistic_entries(offer).join.html_safe
    end
  end
  
  def offer_statistic_entries(offer)
    statistic_entries = []
    statistic_entries << 
      [
        offer_compliance(offer),
        dt(I18n.t("offer.status.compliance")),
        dd("#{offer.compliance}%"),
        dt(I18n.t("offer.status.viewed")),
        dd(time_ago_in_words(offer.created_at))
      ]
    statistic_entries.compact.flatten
  end
  
  def offer_compliance(offer)
    return unless offer.quest.criteria.present?
    
    div :class => "progress" do
      div "#{offer.compliance}", :class => "bar", :style => "width: #{offer.compliance}%;"
    end
  end
  
  
  def offers_box(offerable)
    expect! offerable => [Quest]
    
    title = h3 :class => "title" do
      [
        div(I18n.t("offer.list.title", :count => offerable.offers.count), :class => "pull-left"),
        div(:class => "pull-right") do
          ul :class => "interactions" do
            li offer_quest_button(offerable)
          end
        end
      ].compact.join.html_safe
    end
    
    content = div :class => "content" do
      ul(:class => "offers list") do
        offerable.offers.map do |offer|
          li :class => "offer", :id => dom_id(offer) do
            partial "offers/item", :offer => offer
          end
        end.compact.join.html_safe
      end
    end

    div :class => "offers box row-fluid" do
      title + content
    end
    
  end
end

__END__
  # Actions to show on top of /offers/show
  def offer_actions(offer)
    return [] unless @offer.quest.active?

    if current_user == @offer.quest.owner
      [:accept, :decline]
    elsif current_user == @offer.owner
      [:withdraw]
    end
  end
end
