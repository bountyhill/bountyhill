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
//= require jquery
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
    backgroundColor:    "black"
  };

  $.fn.map = function(location) {
    var self = this;
    
    var geocoder = new google.maps.Geocoder();
    geocoder.geocode(
      { 'address': location }, 
      function(results, status) {
        console.log("Received results for ", location)
        
        if (status !== 'OK') {
          console.log("Sorry: could not locate " + location + ": " + status);
          return;
        }

        var options = DEFAULTS;
        options.center = results[0].geometry.location;
        options.fitBounds = results[0].geometry.viewport;
        
        self.gmap(DEFAULTS).
          bind('init', function(ev, map) {
            self.gmap('addMarker', {'position': results[0].geometry.location}).
              click(function() { });
          });
        map.fitBounds(results[0].geometry.viewport);
      });
      
  }; // $.fn.map = ...

})(jQuery);
