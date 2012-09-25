// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
// Note: we do not require jquery. We will load jquery from google's CDN.
//  no_require jquery
//
//= require jquery_ujs
//= require_tree .

// dummy console, just in case
if(typeof console === "undefined") {
  console = {
    log: function() {}
  };
}

(function( $ ) {
  var DEFAULTS = {
    zoom:               8,
    center:             '52.5, 13.5', 
    mapTypeControl:     false,
    panControl:         false,
    rotateControl:      false,
    streetViewControl:  false,
    backgroundColor:    "black",
    draggable:          false,
    scrollwheel:        false
  };

  $.fn.map_widget = function() {
    var self = this;
    
    var location = self.data("location");
    
    var geocoder = new google.maps.Geocoder();
    geocoder.geocode(
      { 'address': location }, 
      function(results, status) {
        if (status !== 'OK') {
          console.log("Could not locate " + location + ": " + status);
          return;
        }

        // We found the location -> build a gmap and put a marker on it.
        var options = DEFAULTS;
        options.center = results[0].geometry.location;
        options.fitBounds = results[0].geometry.viewport;
        
        self.gmap(options).
          bind('init', function(ev, map) {
            self.gmap('addMarker', {'position': results[0].geometry.location}).
              click(function() { });
          });
      });
      
  }; // $.fn.map_widget = ...

})(jQuery);

jQuery(function() {
  jQuery("[data-location]").map_widget();
});
