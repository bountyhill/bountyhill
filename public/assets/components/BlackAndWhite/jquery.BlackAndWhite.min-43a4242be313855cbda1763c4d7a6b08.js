
/**
 *
 * Version: 0.2.1
 * Author:  Gianluca Guarini
 * Contact: gianluca.guarini@gmail.com
 * Website: http://www.gianlucaguarini.com/
 * Twitter: @gianlucaguarini
 *
 * Copyright (c) 2012 Gianluca Guarini
 *
 **/

(function(a){a.fn.extend({BlackAndWhite:function(e){function k(a,b,c,d){var g=b.getContext("2d"),b=0;g.drawImage(a,0,0,c,d);var a=g.getImageData(0,0,c,d),d=a.data,e=d.length;if(l&&i)b=new Worker(i+"BnWWorker.js"),b.postMessage(a),b.onmessage=function(a){g.putImageData(a.data,0,0)};else{for(;b<e;b+=4)c=0.3*d[b]+0.59*d[b+1]+0.11*d[b+2],d[b]=d[b+1]=d[b+2]=c;g.putImageData(a,0,0)}}var f=this,e=a.extend({hoverEffect:!0,webworkerPath:!1,responsive:!0,invertHoverEffect:!1},e),j=e.hoverEffect,i=e.webworkerPath,
h=e.invertHoverEffect,m=e.responsive,n=!!document.createElement("canvas").getContext,o=a(window),l="undefined"!==typeof Worker?!0:!1,p=a.browser.msie&&7===+a.browser.version;this.init=function(){n&&!(a.browser.msie&&"9.0"==a.browser.version)?a(f).each(function(e,b){var c=a(b).find("img");a(c).prop("src");var d=a(c).width(),g=a(c).height();a('<canvas width="'+d+'" height="'+g+'"></canvas>').prependTo(b);var f=a(b).find("canvas");a(f).css({position:"absolute",top:0,left:0,display:h?"none":"block"});
k(c[0],f[0],d,g);j&&(a(this).mouseenter(function(){h?a(this).find("canvas").stop(!0,!0).fadeIn():a(this).find("canvas").stop(!0,!0).fadeOut()}),a(this).mouseleave(function(){h?a(this).find("canvas").stop(!0,!0).fadeOut():a(this).find("canvas").stop(!0,!0).fadeIn()}))}):(a(f).each(function(e,b){var c=a(b).find("img"),d=a(b).find("img").prop("src"),f=a(c).prop("width"),c=a(c).prop("height");a("<img src="+d+' width="'+f+'" height="'+c+'" class="ieFix" /> ').prependTo(b);a(".ieFix").css({position:"absolute",
top:0,left:0,filter:"progid:DXImageTransform.Microsoft.BasicImage(grayscale=1)",display:h?"none":"block"})}),j&&(a(f).mouseenter(function(){h?a(this).children(".ieFix").stop(!0,!0).fadeIn():a(this).children(".ieFix").stop(!0,!0).fadeOut()}),a(f).mouseleave(function(){h?a(this).children(".ieFix").stop(!0,!0).fadeOut():a(this).children(".ieFix").stop(!0,!0).fadeIn()})));if(m)o.on("resize orientationchange",f.resizeImages)};this.resizeImages=function(){a(f).each(function(e,b){var c=a(b).find("img:not(.ieFix)"),
d;p?(d=a(c).prop("width"),c=a(c).prop("height")):(d=a(c).width(),c=a(c).height());a(this).find(".ieFix, canvas").css({width:d,height:c})})};return this.init(e)}})})(jQuery);
