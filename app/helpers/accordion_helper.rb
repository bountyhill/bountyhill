module AccordionHelper
  
  def accordion(options={}, &block)
    output = div(capture(&block), { :class =>"accordion", :id => "accordion" }.merge(options))
    block_given? ? concat(output) : output
  end
  
  def accordion_group(options={}, &block)
    output = div(capture(&block), { :class => "accordion-group" }.merge(options))
    block_given? ? concat(output) : output
  end
  
  def accordion_heading(part, &block)
    output = div(:class => "accordion-heading") do
      link_to("#collapse-#{part}", :class => "accordion-toggle #{part}", :"data-toggle" => "collapse", :"data-parent" => "#accordion") do
        h4 do
          capture(&block)
        end
      end
    end
    
    block_given? ? concat(output) : output
  end

  def accordion_body(part, options={}, &block)
    output = div(:id => "collapse-#{part}",  :class => "accordion-body collapse #{collapse(part, options)}") do
      div(:class => "accordion-inner") do
        capture(&block)
      end
    end
    
    block_given? ? concat(output) : output
  end

  def collapse(partial, options={})
    expect! partial => Symbol
    expect! options => Hash

    return 'in' if @partial.blank? && options[:default]
    @partial.to_s == partial.to_s ? 'in' : 'out'
  end
  
end

__END__
  class Accordion
    extend Forwardable
    delegate [:div, :span, :ul, :li, :link_to, :h3, :capture] => "@template"

    def initialize(template, accordion_id)
      @template, @accordion_id = template, accordion_id
      @item_id = 0
    end
    
    def item_header(item_id, title, options)
      expect! options => { :mode => [ :blank, :present ] }
      expect! options => { :collapse  => [ true, false, nil ] }
      
      heading = span(@item_id, :class => "bullet")
      heading += h3(title)
      heading += span("", :class => "arrow")
      
      
      item_heading = unless options[:collapse] == false
        link_options = { :class => "accordion-toggle" }
        link_options.merge!("data-toggle" => "collapse", "data-parent" => "##{@accordion_id}")
        link_to heading, "##{item_id}", link_options
      else
        heading
      end
      div item_heading, :class => "accordion-heading"
    end

    def item(title, *contents, &block)
      options = contents.extract_options!
      expect! options => { :collapsed => [ true, false, nil ] }
      expect! options => { :collapse  => [ true, false, nil ] }
      
      contents << capture(&block) if block_given?
      contents.compact!
      
      generate_item_id do |item_id|
        heading = item_header(item_id, title, :mode => (contents.blank? ? :blank : :present), :collapse => options[:collapse])
        if contents.present?
          css = "accordion-body"
          css += " collapse"  if options[:collapse] == false
          css += " in"        if options[:collapse] == false || options[:collapsed] == false

          body = div :id => item_id, :class => css do
            div(*contents, :class => "accordion-inner")
          end
        end

        li heading, body, :class=>"accordion-group"
      end.html_safe
    end

    private
    
    def generate_item_id
      yield "#{@accordion_id}_#{@item_id += 1}"
    end
  end

  def accordion(options = {})
    accordion_id = options[:id] || "accordion1"
    ul :class => "accordion", :id => accordion_id do
      yield Accordion.new(self, accordion_id)
    end
  end
end
