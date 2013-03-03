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
    # TODO
  end

  def offer_buttons(offer)
    button_group [
      accept_offer_button(offer),
      reject_offer_button(offer),
      withdraw_offer_button(offer)
    ]
  end

  def accept_offer_button(offer)
    return unless current_user
    return unless offer.active? && !current_user.owns?(offer)

    modal_awesome_button(:ok_circle, accept_offer_path(offer), :rel => "nofollow") { I18n.t("button.accept") }
  end

  def reject_offer_button(offer)
    return unless current_user
    return unless offer.active? && !current_user.owns?(offer)

    modal_awesome_button(:remove_sign, reject_offer_path(offer), :rel => "nofollow") { I18n.t("button.reject") }
  end
  
  def withdraw_offer_button(offer)
    return unless current_user
    return unless offer.active? && current_user.owns?(offer)

    modal_awesome_button(:remove_sign, withdraw_offer_path(offer), :rel => "nofollow") { I18n.t("button.withdraw") }
  end
    
  def offer_statistic(offer)
    dl(:class => "statistic") do
      offer_statistic_entries(offer).join.html_safe
    end
  end
  
  def offer_statistic_entries(offer)
    statistic_entries = [offer_compliance(offer)]
      
    statistic_entries << [
      dt(I18n.t("offer.list.statistic.images", :count => offer.images.size)),
      dd(image_stack(offer))
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
          button_group [
            offer_quest_button(offerable)
          ]
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
