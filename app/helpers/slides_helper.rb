# encoding: UTF-8

module SlidesHelper
  WIDTH = 100
  HEIGHT = 100
  
  #
  # Render slides.
  #
  # A slides object is rendered as a "ul.fp-slides li" list.
  #
  # The block is called with |image, thumbnail| arguments containing the image 
  # and thumbnail urls, respectively. It must return HTML for éach individual
  # slide.
  #
  # If no block is given the html is rendered via render_slide.
  def render_slides(object, options = {}, &block)
    original_options = options.dup
    
    unless block_given?
      block = lambda { |image, thumbnail| 
        render_slide object, image, thumbnail, original_options
      }
    end
    
    editable = options.delete(:editable)
    options[:class] = [options[:class], "fp-slides", ("fp-slides-edit" if editable)].compact.join(" ")

    ul options do
      images = object.images
      thumbnails = object.images(:width => WIDTH, :height => HEIGHT)
      
      list_items = images.zip(thumbnails).map do |image, thumbnail|
        html = block.call(image, thumbnail)
        
        li html.html_safe
      end
      
      list_items.join("\n").html_safe
    end
  end

  # renders an image tag with just the right dimensions
  def render_slide_image(thumbnail)
    image_tag(thumbnail, :width => SlidesHelper::WIDTH, :height => SlidesHelper::HEIGHT)
  end
  
  def render_slide(object, image, thumbnail, options = {})
    link_to render_slide_image(thumbnail), image, :target => "_blank"
  end
end

