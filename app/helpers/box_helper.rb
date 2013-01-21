module BoxHelper
  
  def box_buttons(buttons)
    expect! buttons => Array
    
    div :class => "btn-group" do
      buttons.join.html_safe
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
        render :partial => "#{type}/list"
      end + endless_scroll_loader(type)
    end

    # render box
    div :class => "#{type} box row-fluid" do
      title + content
    end
  end
  
end
