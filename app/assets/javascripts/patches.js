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
