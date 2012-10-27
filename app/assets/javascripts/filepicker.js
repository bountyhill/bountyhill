/* 
 * set filepicker defaults for pickMultiple and pick functions; 
 * see https://developers.filepicker.io/docs/web
 */
jQuery(document).on("change", "input[type=filepicker]", function(event) {
  var fpfiles = event.originalEvent.fpfile;
  if(!fpfiles) return;

  var width = 100;
  var height = 140;
  
  var self = jQuery(this);
  var form = self.closest("form");

  /*
   * The slideshow target node; this is a UL, and new images are
   * added as <li><img src="..."></li> nodes.
   */
  var slideshow = (function() {
    var slides = self.data("fp-slides");
    return jQuery(slides, form);
  })();
  
  jQuery.each(fpfiles, function() {
    var url = this.url;
    var slide_url = url + "/convert?w=" + width + "&h=" + height;
  
    var slide = $('<li><input type="hidden"></input><img src=""></img><span></span></li>');
    slide.find("input").attr("name", self.data("fp-name")).val(url);
    slide.find("img").attr("src", slide_url).attr("width", width).attr("height", height);
    slide.find("span").text(this.filename);
    
    slideshow.append(slide);
  });
});

jQuery(function() {
  jQuery("ul.fp-slides-edit li a.fp-delete").click(function() {
    $(this).closest("li").remove();
  });
});