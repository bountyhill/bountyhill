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
//  no_require jquery_ujs
//
//= require bootstrap.js
//= require filepicker.js

// dummy console, just in case
if(typeof console === "undefined") {
  console = {
    log: function() {}
  };
}

$(document).ready(function() {
  // enable endless scrolling
  // see ???
  $('.endless_scroll_hook').bind('inview', function(e,visible) {
    if( visible ) {
      $.getScript($(this).attr("href"));
    }
  });
  
  // To use Ajax Content in Twitter Bootstrap Modal
  // see http://blog.assimov.net/blog/2012/03/09/ajax-content-in-twitter-bootstrap-modal/
  $("a[data-toggle=modal]").click(function (e) {
   lv_target = $(this).attr('data-target');
   lv_url = $(this).attr('href');
   $(lv_target).load(lv_url);
  });
});

