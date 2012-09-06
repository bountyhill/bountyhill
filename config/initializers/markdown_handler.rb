# require 'action_view'

class ActionView::Template::Handlers::MarkdownHandler
  def self.call(template)
    require_engine
    
    return <<-RUBY
markdown = <<-MARKDOWN
#{template.source}
MARKDOWN
  RDiscount.new(markdown).to_html;
RUBY
  end
  
  def self.require_engine
    @required ||= begin
      require 'rdiscount'
      true
    end
  end
end

ActionView::Template.register_template_handler :md, ActionView::Template::Handlers::MarkdownHandler
