module BoxHelper

  def box(type, object, options={})
    expect! type    => [:quest, :offer]
    expect! object  => [Quest, Offer]
    
    title = h2 :class => "title" do
      [
        div(options[:title], :class => "pull-left"),
        div(send("#{type}_buttons", object), :class => "pull-right")
      ].compact.join.html_safe
    end
    
    content = div :class => "content" do
      partial "#{type.to_s.pluralize}/show", type => object
    end
    
    div :class => "#{type} box row-fluid" do
      title + content
    end
  end
  
  def list_box(type, models)
    expect! type    => [:quests, :offers]
    expect! models  => ActiveRecord::Relation
    
    title = h2 :class => "title" do
      [
        div(I18n.t("#{type.to_s.singularize}.list.title", :count => models.total_entries), :class => "pull-left"),
        div(send("#{type}_list_box_buttons"), :class => "pull-right")
      ].compact.join.html_safe
    end
    
    content = div :class => "content" do
      ul(:class => "#{type} list") do
        partial "#{type}/list", type => models
      end + endless_scroll_loader(type)
    end

    div :class => "#{type} box row-fluid" do
      title + content
    end
  end

  def box_buttons(buttons)
    expect! buttons => Array
    
    div :class => "btn-group" do
      buttons.join.html_safe
    end
  end
  
end
