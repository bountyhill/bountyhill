module ActionButtonsHelper
  class ActionButtons
    extend Forwardable
    delegate [:ul, :li, :link_to, :span, :div] => "@template"

    attr_reader :html
    def initialize(template)
      @template = template
      @html = []
    end
    
    def action(icon, title, sub = nil)
      if title.is_a?(Symbol)
        sub ||= I18n.t("#{title}.sub")
        title = I18n.t("#{title}.title")
      end
      li = self.li do
        link_to "#", "data-bitly-type" => "bitly_hover_card" do
          html = span icon, "class" => "ca-icon twitter"
          html += div "class" => "ca-content" do
            title = span title, :class => "ca-main"
            sub = span sub, :class => "ca-sub"

            "#{title}#{sub}".html_safe
          end
          html
        end
      end

      @html << li
    end
    
    def html
      @html.join("\n").html_safe
    end
  end

  def action_buttons(options = {})
    ul options.merge(:class=>"ca-menu bg-gray") do
      ActionButtons.new(self).tap do |action_buttons|
        Proc.new.bind(action_buttons).call
      end.html
    end
  end
end
