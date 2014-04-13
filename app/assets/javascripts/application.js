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
//= require patches

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
