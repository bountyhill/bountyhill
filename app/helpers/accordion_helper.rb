module AccordionHelper
  class Accordion
    extend Forwardable
    delegate [:div, :span, :ul, :li, :link_to, :h3, :capture] => "@template"

    def initialize(template, accordion_id)
      @template, @accordion_id = template, accordion_id
      @item_id = 0
    end
    
    def item_header(item_id, title, mode)
      expect! mode => [ :blank, :present ]
      heading = span(@item_id, :class => "bullet")
      heading += h3(title)
      heading += span("", :class => "arrow")
      a = link_to heading, "##{item_id}", :class => "accordion-toggle", 
        "data-toggle" => "collapse", "data-parent" => "##{@accordion_id}"
        
      div a, :class => "accordion-heading"
    end

    def item(title, *contents, &block)
      options = contents.extract_options!
      expect! options => { :collapsed => [ true, false, nil ] }
      
      contents << capture(&block) if block_given?
      contents.compact!
      
      generate_item_id do |item_id|
        heading = item_header(item_id, title, contents.blank? ? :blank : :present)
        if contents.present?
          css = "accordion-body collapse"
          css += " in" if options[:collapsed] == false

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
