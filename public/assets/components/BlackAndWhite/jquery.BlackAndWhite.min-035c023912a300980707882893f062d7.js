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
(function(e){e.fn.extend({BlackAndWhite:function(t){function n(e,t,n,r){var i=t.getContext("2d"),t=0;i.drawImage(e,0,0,n,r);var e=i.getImageData(0,0,n,r),r=e.data,o=r.length;if(c&&s)t=new Worker(s+"BnWWorker.js"),t.postMessage(e),t.onmessage=function(e){i.putImageData(e.data,0,0)};else{for(;t<o;t+=4)n=.3*r[t]+.59*r[t+1]+.11*r[t+2],r[t]=r[t+1]=r[t+2]=n;i.putImageData(e,0,0)}}var r=this,t=e.extend({hoverEffect:!0,webworkerPath:!1,responsive:!0,invertHoverEffect:!1},t),i=t.hoverEffect,s=t.webworkerPath,o=t.invertHoverEffect,u=t.responsive,f=!!document.createElement("canvas").getContext,l=e(window),c="undefined"!=typeof Worker?!0:!1,h=e.browser.msie&&7===+e.browser.version;return this.init=function(){f&&(!e.browser.msie||"9.0"!=e.browser.version)?e(r).each(function(t,r){var s=e(r).find("img");e(s).prop("src");var u=e(s).width(),f=e(s).height();e('<canvas width="'+u+'" height="'+f+'"></canvas>').prependTo(r);var l=e(r).find("canvas");e(l).css({position:"absolute",top:0,left:0,display:o?"none":"block"}),n(s[0],l[0],u,f),i&&(e(this).mouseenter(function(){o?e(this).find("canvas").stop(!0,!0).fadeIn():e(this).find("canvas").stop(!0,!0).fadeOut()}),e(this).mouseleave(function(){o?e(this).find("canvas").stop(!0,!0).fadeOut():e(this).find("canvas").stop(!0,!0).fadeIn()}))}):(e(r).each(function(t,n){var r=e(n).find("img"),i=e(n).find("img").prop("src"),s=e(r).prop("width"),r=e(r).prop("height");e("<img src="+i+' width="'+s+'" height="'+r+'" class="ieFix" /> ').prependTo(n),e(".ieFix").css({position:"absolute",top:0,left:0,filter:"progid:DXImageTransform.Microsoft.BasicImage(grayscale=1)",display:o?"none":"block"})}),i&&(e(r).mouseenter(function(){o?e(this).children(".ieFix").stop(!0,!0).fadeIn():e(this).children(".ieFix").stop(!0,!0).fadeOut()}),e(r).mouseleave(function(){o?e(this).children(".ieFix").stop(!0,!0).fadeOut():e(this).children(".ieFix").stop(!0,!0).fadeIn()}))),u&&l.on("resize orientationchange",r.resizeImages)},this.resizeImages=function(){e(r).each(function(t,n){var r=e(n).find("img:not(.ieFix)"),i;h?(i=e(r).prop("width"),r=e(r).prop("height")):(i=e(r).width(),r=e(r).height()),e(this).find(".ieFix, canvas").css({width:i,height:r})})},this.init(t)}})})(jQuery);