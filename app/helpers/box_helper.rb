# encoding: UTF-8

module BoxHelper

  def box(type, object, options={})
    expect! type    => [:quest, :offer, :user, :email, :address, :twitter, :facebook]
    expect! object  => [nil, Quest, Offer, User, Identity]
    
    preview = options[:preview]
    header = div :class => "header" do
      [
        div(options[:title], :class => "pull-left"),
        div(preview ? step_indicator_for(object) : send("#{type}_buttons", object), :class => "pull-right")
      ].compact.join.html_safe
    end

    partial_path = case type
      when :email     then "identities/email/show"
      when :address   then "identities/address/show"
      when :twitter   then "identities/twitter/show"
      when :facebook  then "identities/facebook/show"
      else "#{type.to_s.pluralize}/show"
      end
    content = div :class => "content" do
      partial partial_path, type => object, :preview => preview
    end
    
    div :class => "#{type} box row-fluid #{options[:class]}" do
      header + content
    end
  end
  
  def list_box(type, models, options={})
    expect! type    => [:quests, :offers, :activities]
    expect! models  => ActiveRecord::Relation
    expect! options => Hash
    
    title_text =  I18n.t("#{type.to_s.singularize}.list.title", :count => models.total_entries)
    title_text += " " + I18n.t("filter.filter_by", :filter => options[:filter]) if options[:filter]
    
    header = div :class => "header" do
      [
        div(title_text, :class => "pull-left"),
        div(send("#{type}_list_box_buttons"), :class => "pull-right")
      ].compact.join.html_safe
    end
    
    content = div :class => "content" do
      if models.present?
        ul(:class => "#{type} list") do
          partial "#{type}/list", type => models
        end + endless_scroll_loader(type)
      end
    end

    div :class => "#{type} list box row-fluid #{options[:class]}" do
      header + content
    end
  end

  def filter_box(type, attribute, filters, options={})
    expect! type    => [:quest, :offer]
    expect! filters => Array
    
    header = div :class => "header" do
      div(options[:title], :class => "pull-left")
    end
    
    content = div :class => "content" do
      ul :class => "btn-group" do
        filters.map do |f|
          css_class =  "btn btn-link btn-small"
          css_class += " active" if f.active?(options[:active]) || filters.size == 1
          
          name = span(I18n.t(f.name, :scope => "#{type}.#{attribute}"), :class => 'filtername') + span(f.count, :class => 'filtercount')
          li link_to(name.html_safe, f.url, :class => css_class)
        end.join.html_safe
      end
    end
    
    div :class => "#{type} filter box row-fluid" do
      header + content
    end
  end
  
  def form_box(model, options={})
    expect! model  => [Quest, Offer]
    expect! options => Hash
    
    type = model.class.name.downcase
    
    header = div :class => "header" do
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

    div :class => "#{type} box row-fluid #{options[:class]}" do
      header + content
    end
  end
  
  def statistic_box(count, text, icon=nil, options={})
    expect! count   => [Integer, String]
    expect! text    => String
    expect! icon    => [String, nil]
    expect! options => Hash
    
    div :class => "statistic box #{options[:css_class]}" do
      div :class => "container" do
        [
          div(icon,  :class => "icon"),
          div(count, :class => "count"),
          div(text,  :class => "text")
        ].compact.join.html_safe
      end
    end
  end

  def step_indicator_for(model, options={})
    step_titles = case model
    when Quest then %w(create start)
    when Offer then %w(create offer)
    else raise "Unknown step_indicator for model #{model.inspect}!"
    end
    
    ol :class => "step-indicator" do
      [
        li(I18n.t(step_titles[0], :scope => "button"),  :class => "step #{model.new_record? ? 'active' : ''}"),
        li(I18n.t(step_titles[1],  :scope => "button"),  :class => "step #{model.new_record? ? '' : 'active'}"),
      ].join.html_safe
    end
  end
  
end
