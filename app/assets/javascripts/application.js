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
//= require jquery-ui
//= require jquery_ujs
//= require bootstrap
//= require filepicker
//= require tinymce
//= require jquery.inview
//= require bootstrap-lightbox
//= require bootstrap-select
//= require html5slider

// dummy console, just in case
if(typeof console === "undefined") {
  console = {
    log: function() {}
  };
}

// HTML escape
jQuery.escapeHTML = function(str) {
  return jQuery('<div/>').text(str).html();
};

$(document).ready(function() {

  // prevent Safari on iOS to zoom site
  // see: http://stackoverflow.com/questions/2989263/disable-auto-zoom-in-input-text-tag-safari-on-iphone
  $('textarea, input[type="text"], input[type="password"], input[type="search"], input[type="email"], input[type="url"], input[type="number"]').on({ 'touchstart' : function() { zoomDisable(); }});
  $('textarea, input[type="text"], input[type="password"], input[type="search"], input[type="email"], input[type="url"], input[type="number"]').on({ 'touchend' : function() { setTimeout(zoomEnable, 500); }});

  function zoomDisable(){
    $('head meta[name="viewport"]').remove();
    $('head').prepend('<meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no" />');
  }
  function zoomEnable(){
    $('head meta[name="viewport"]').remove();
    $('head').prepend('<meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=yes" />');
  } 

  // enable endless scrolling
  // see http://blog.migrantstudios.com/2012/07/11/building-an-infinite-scroll-component-with-rails-and-jquery/
  $('.endless_scroll_hook').bind('inview', function(e,visible) {
    if(visible) {
      $.getScript($(this).attr("href"));
    }
  });
  
  // use Ajax Content in Twitter Bootstrap Modal
  // see http://blog.assimov.net/blog/2012/03/09/ajax-content-in-twitter-bootstrap-modal/
  $("a[data-toggle=modal]").click(function (e) {
   lv_target = $(this).attr('data-target');
   lv_url = $(this).attr('href');
   $(lv_target).load(lv_url);
  });
  
});

