module ImagesHelper
  
  def image_stack(object)
    return if object.images.blank?
    
    link_to(image_tag(object.images(:width => 40, :height => 40).first),
      "/#{object.class.name.downcase.pluralize}/#{object.id}/lightbox/0",
      :class => object.images.size > 1 ? "image-stack rotated" : "image-single",
      :remote => true)
  end
  
end