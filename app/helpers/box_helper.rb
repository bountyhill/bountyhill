module BoxHelper

  def box(type, object, options={})
    expect! type    => [:quest, :offer, :user]
    expect! object  => [Quest, Offer, User]
    
    preview = options[:preview]
    title = div :class => "title" do
      [
        div(options[:title], :class => "pull-left"),
        div(preview ? step_indicator_for(object) : send("#{type}_buttons", object), :class => "pull-right")
      ].compact.join.html_safe
    end
    
    content = div :class => "content" do
      partial "#{type.to_s.pluralize}/show", type => object, :preview => preview
    end
    
    div :class => "#{type} box row-fluid #{options[:class]}" do
      title + content
    end
  end
  
  def list_box(type, models, options={})
    expect! type    => [:quests, :offers]
    expect! models  => ActiveRecord::Relation
    expect! options => Hash
    
    title_text =  I18n.t("#{type.to_s.singularize}.list.title", :count => models.total_entries)
    title_text += " " + I18n.t("filter.filter_by", :filter => options[:filter]) if options[:filter]
    
    title = div :class => "title" do
      [
        div(title_text, :class => "pull-left"),
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

  def filter_box(type, atribute, filters, options={})
    expect! type    => [:quest, :offer]
    expect! filters => Array
    
    title = div :class => "title" do
      div(options[:title], :class => "pull-left")
    end
    
    content = div :class => "content" do
      ul :class => "btn-group" do
        filters.map do |f|
          css_class =  "btn btn-link btn-small"
          css_class += " active" if f.active?(options[:active]) || filters.size == 1
          
          name = (I18n.t(f.name, :scope => "#{type}.#{atribute}") + span(f.count, :class => 'count')).html_safe
          li link_to(name, f.url, :class => css_class)
        end.join.html_safe
      end
    end
    
    div :class => "#{type} filter box row-fluid" do
      title + content
    end
  end
  
  def form_box(model, options={})
    expect! model  => [Quest, Offer]
    expect! options => Hash
    
    type = model.class.name.downcase
    
    title = div :class => "title" do
      [
        div(i18n_title_for(model), :class => "pull-left"),
        div(step_indicator_for(model), :class => "pull-right")
      ].compact.join.html_safe
    end
    
    content = div :class => "content" do
      div(:class => "#{type} form") do
        partial "#{type.pluralize}/form", type => model
      end
    end

    div :class => "#{type} box row-fluid" do
      title + content
    end
  end
  
  def statistic_box(count, text, icon=nil, options={})
    expect! count   => [Integer, String]
    expect! text    => String
    expect! icon    => [String, nil]
    expect! options => Hash
    
    div :class => "statistic box #{options[:css_class]}" do
      [
        div(icon,  :class => "icon"),
        div(count, :class => "count"),
        div(text,  :class => "text")
      ].compact.join.html_safe
    end
  end
  
end
