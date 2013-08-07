# encoding: UTF-8

require 'will_paginate'

module PaginateHelper
  class PaginateLinkRenderer < WillPaginate::ActionView::LinkRenderer
    def page_number(page)
      l = link(page, page, :rel => rel_value(page))
    
      if page == current_page
        tag :li, l, :class => 'active'
      else
        tag :li, l
      end
    end

    def previous_or_next_page(page, text, classname)
      l = link(text, page || @collection.current_page, :class => classname)
      tag :li, l, :class => (page ? nil : 'disabled')
    end
    
    def html_container(html)
      tag :ul, html
    end

    def gap
      text = @template.will_paginate_translate(:page_gap) { '&hellip;' }
      l = link(text, "#")
      tag :li, l, :class => 'gap'
    end
  end

  def paginate(p)
    will_paginate p, :inner_window => 1, :outer_window => 1,
      :previous_label => '&#8592;'.html_safe, :next_label => '&#8594;'.html_safe,
      :renderer => PaginateLinkRenderer 
  end
end
