# encoding: UTF-8

module ButtonHelper

  def button_group(buttons)
    expect! buttons => Array
    
    div :class => "btn-group" do
      buttons.compact.join.html_safe
    end
  end
  
  def modal_link_to(name, options, html_options={})
    link_to name, options, html_options.merge(:"data-toggle" => "modal", :"data-target" => "#myModal")
  end
  
  def modal_awesome_button(name, url, options={}, &block)
    expect! name => Symbol
    expect! url => String
    
    awesome_button(name, url, { :html => { :"data-toggle" => "modal", :"data-target" => "#myModal", :rel => "nofollow" }}.merge(options), &block)
  end
  
  def awesome_button(name, href='#', options={}, &block)
    expect! name => Symbol
    expect! href => String

    size = (options[:size] ||= :normal)
    html = (options.delete(:html) || {})
    
    button = options.delete(:button) || "btn btn-link"
    button << " btn-#{size}" if size
    
    if original_class = options.delete(:class)
      button << " #{original_class}"
    end

    content_tag :a, html.merge(:class => button, :href => href) do
      awesome_icon name, options, &block
    end
  end

  def contact_owner_button(object)
    expect! object => [Quest, Offer]
    
    return unless object.active?
    return unless current_user
    return if current_user.owns?(object)
    
    modal_awesome_button(icon_for('interaction.send'), url_for(
      :controller => :messages,
      :action     => :new,
      :message    => { :reference_id => object.id, :reference_type => object.class.name })) { I18n.t("button.contact") }
  end

end