/* 
 * set filepicker defaults for pickMultiple and pick functions; 
 * see https://developers.filepicker.io/docs/web
 */
jQuery(document).on("change", "input[type=filepicker]", function(event) {
  var fpfiles = event.originalEvent.fpfiles;
  if(!fpfiles) return;
  
  var width = 100;
  var height = 140;
  
  var self = jQuery(this);
  var single_mode = self.data("fpMultiple") != true; /* multiple images? */
  var form = self.closest("form");

  /*
   * The slideshow target node; this is a UL, and new images are
   * added as <li><img src="..."></li> nodes.
   */
  var slideshow = jQuery(self.data("fp-slides"), form);
  
  if(single_mode) {
    jQuery("> li", slideshow).empty();
  }
  
  jQuery.each(fpfiles, function() {
    var url = this.url;
    var slide_url = url + "/convert?w=" + width + "&h=" + height + "&fit=max";
  
    var slide = $('<li><input type="hidden"></input><div class="image-container"><img src=""></img></div><a href="#" class="btn fp-delete"><i class="icon-trash icon-large""></i></a></div></li>');
    slide.find("input").attr("name", self.data("fp-name")).val(url);
    slide.find("img").attr("src", slide_url).attr("width", width).attr("height", height);
//    slide.find("span").text(this.filename);
    
    slideshow.append(slide);
  });
});

$(document).on("click", "ul.fp-slides-edit li a.fp-delete", 
  function(){ 
    $(this).closest("li").remove();
});