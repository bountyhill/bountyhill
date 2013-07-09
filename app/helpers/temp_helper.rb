#TODO: this is just a temporary helper - remove when site is implemented

module TempHelper
  def placeholder(text, options={})
    div :class => "placeholder", :style => options[:style] do
      content_tag :b, "Placeholder: #{text}"
    end
  end
  
  def spacer(options={})
    div "", :class => "spacer #{options[:class]}", :style => options[:style]
  end
end