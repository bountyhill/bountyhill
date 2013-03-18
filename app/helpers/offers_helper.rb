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
      accept_offer_button(offer),
      reject_offer_button(offer),
      withdraw_offer_button(offer)
    ]
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
    dl do
      offer_statistic_entries(offer).join.html_safe
    end
  end
  
  def offer_statistic_entries(offer)
    statistic_entries = [
      dt(I18n.t("offer.compliance", :precentage => offer.compliance)),
      dd("")
    ]
    
    unless offer.active?
      statistic_entries << [
        dt(I18n.t("offer.states.#{offer.state}")),
        dd("")
      ]
    end

    statistic_entries << [
      dt(I18n.t("offer.list.statistic.images", :count => offer.images.size)),
      dd(image_stack(offer))
    ]
      
    statistic_entries.compact.flatten
  end
  
  def offer_compliance(offer, options={})
    value = options[:value] || offer.compliance.to_s
    label = options[:label] || value
    css   = options[:class] || "progress"
    
    div :class => css do
      div label, :class => "bar", :style => "width: #{value}%;"
    end
  end
  
  def offers_box(offerable, options={})
    expect! offerable => [Quest]
    
    title = h3 :class => "title" do
      [
        div(I18n.t("offer.list.title", :count => offerable.offers.count), :class => "pull-left"),
        div(:class => "pull-right") do
          button_group [
            new_offer_button(offerable)
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

    div :class => "offers box row-fluid  #{options[:class]}" do
      title + content
    end
  end
  
  def offers_state_filters(filters=[])
    filter_box(:offer, :states, filters, :title => I18n.t("filter.states.title"), :active => params[:state])
  end
  
end
