module ActionButtonsHelper
  class ActionButtons
    extend Forwardable
    delegate [:ul, :li, :link_to, :span, :div] => "@template"

    attr_reader :html
    def initialize(template)
      @template = template
      @html = []
    end
    
    # action "t", :title,  [ "sub", ] :url => url
    # action "t", "title", [ "sub", ] :url => url
    def action(icon, *args)
      options = args.extract_options!
      title, sub = *args

      expect! title => [ Symbol, String ], sub => [ Symbol, String, nil ]

      if title.is_a?(Symbol)
        sub ||= I18n.t("#{title}.sub")
        title = I18n.t("#{title}.title")
      end
      if sub.is_a?(Symbol)
        sub = I18n.t(sub)
      end
      
      url = options[:url] || '#'
      
      li = self.li do
        link_to url, "data-bitly-type" => "bitly_hover_card" do
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
        yield action_buttons
      end.html
    end
  end
end
