module AccordionHelper
  class Accordion
    extend Forwardable
    delegate [:div, :link_to, :h2, :capture] => "@template"

    def initialize(template, accordion_id)
      @template, @accordion_id = template, accordion_id
      @item_id = 0
    end

    ARROW = '<span class="arrow"></span>'.html_safe
    
    def item(title, *contents, &block)
      contents << capture(&block) if block_given?

      generate_item_id do |item_id|
        heading = div :class => "accordion-heading" do
          a = link_to h2(title), "##{item_id}", :class => "accordion-toggle", 
            "data-toggle" => "collapse", "data-parent" => "##{@accordion_id}",
            "data-bitly-type"=>"bitly_hover_card"
          a + ARROW
        end

        collapsed = !first_item?
        
        body = div :id => item_id, :class => "accordion-body bg-gray collapse #{collapsed ? "" : "in"}" do
          div(*contents, :class => "accordion-inner")
        end

        div heading + body, :class=>"accordion-group"
      end.html_safe
    end

    private
    
    def generate_item_id
      yield "#{@accordion_id}_#{@item_id += 1}"
    end
    
    def first_item?
      @item_id == 1
    end
  end

  def accordion(options = {})
    accordion_id = options[:id] || "accordion1"
    div :class => "accordion", :id => accordion_id do
      yield Accordion.new(self, accordion_id)
    end
  end
end
