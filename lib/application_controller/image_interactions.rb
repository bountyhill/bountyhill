module ApplicationController::ImageInteractions
  
  def self.included(klass)
    klass.layout false, :only => [:lightbox]
  end
  
  def lightbox
    @active = params[:active].to_i
    @images = object_class.find(params[:id]).images(:width => 600)
    
    render :template => "shared/lightbox"
  end
  
  private
  
  def object_class
    self.class.name.gsub("Controller", "").singularize.constantize
  end
end
