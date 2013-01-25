module OffersHelper
  
  def offers_list_box(offers)
    expect! offers        => ActiveRecord::Relation
    expect! offers.first  => [Offer, nil]
    
    list_box(:offers, offers)
  end
  
  def offers_list_box_buttons
    box_buttons [
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

    modal_link_to(content_tag(:i, nil, :class => "icon-ok-circle") + t("button.accept"),
      accept_offer_path(offer),
      :title => t("button.accept"), :rel => "nofollow")
  end

  def reject_offer_button(offer)
    return unless !offer.active? && offer.owner != current_user

    modal_link_to(content_tag(:i, nil, :class => "icon-remove-sign") + t("button.reject"),
      reject_offer_path(offer),
      :title => t("button.reject"), :rel => "nofollow")
  end
  
  def withdraw_offer_button(offer)
    return unless !offer.active? && offer.owner == current_user

    modal_link_to(content_tag(:i, nil, :class => "icon-remove-sign") + t("button.withdraw"),
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
