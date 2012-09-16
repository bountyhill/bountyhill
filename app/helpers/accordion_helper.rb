module AccordionHelper
  class Accordion
    extend Forwardable
    delegate [:div, :link_to, :h2, :capture] => "@template"

    def initialize(template, accordion_id)
      @template, @accordion_id = template, accordion_id
      @item_id = 0
    end

    ARROW = '<span class="arrow"></span>'.html_safe
    
    def item_header(item_id, title, mode)
      expect! mode => [ :blank, :present ]
      a = link_to h2(title), "##{item_id}", :class => "accordion-toggle", 
        "data-toggle" => "collapse", "data-parent" => "##{@accordion_id}",
        "data-bitly-type"=>"bitly_hover_card"
      a += ARROW if mode == :present

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
          css = "accordion-body bg-gray collapse"
          css += " in" if options[:collapsed] == false

          body = div :id => item_id, :class => css do
            div(*contents, :class => "accordion-inner")
          end
        end

        div heading, body, :class=>"accordion-group"
      end.html_safe
    end

    private
    
    def generate_item_id
      yield "#{@accordion_id}_#{@item_id += 1}"
    end
  end

  def accordion(options = {})
    accordion_id = options[:id] || "accordion1"
    div :class => "accordion", :id => accordion_id do
      yield Accordion.new(self, accordion_id)
    end
  end
end
