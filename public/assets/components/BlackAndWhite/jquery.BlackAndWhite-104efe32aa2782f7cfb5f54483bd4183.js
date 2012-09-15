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
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 **/
(function(e){e.fn.extend({BlackAndWhite:function(t){"use strict";function p(e,t,n,r){var i=t.getContext("2d"),s=e,u=0,a;i.drawImage(e,0,0,n,r);var f=i.getImageData(0,0,n,r),l=f.data,h=l.length;if(c&&o){var p=new Worker(o+"BnWWorker.js");p.postMessage(f),p.onmessage=function(e){i.putImageData(e.data,0,0)}}else{for(;u<h;u+=4)a=l[u]*.3+l[u+1]*.59+l[u+2]*.11,l[u]=l[u+1]=l[u+2]=a;i.putImageData(f,0,0)}}var n=this,r=this,i={hoverEffect:!0,webworkerPath:!1,responsive:!0,invertHoverEffect:!1};t=e.extend(i,t);var s=t.hoverEffect,o=t.webworkerPath,u=t.invertHoverEffect,a=t.responsive,f=!!document.createElement("canvas").getContext,l=e(window),c=function(){return typeof Worker!="undefined"?!0:!1}(),h=e.browser.msie&&+e.browser.version===7;return this.init=function(t){f&&(!e.browser.msie||e.browser.version!="9.0")?e(n).each(function(t,n){var r=e(n).find("img"),i=e(r).prop("src"),o=e(r).width(),a=e(r).height();e('<canvas width="'+o+'" height="'+a+'"></canvas>').prependTo(n);var f=e(n).find("canvas");e(f).css({position:"absolute",top:0,left:0,display:u?"none":"block"}),p(r[0],f[0],o,a),s&&(e(this).mouseenter(function(){u?e(this).find("canvas").stop(!0,!0).fadeIn():e(this).find("canvas").stop(!0,!0).fadeOut()}),e(this).mouseleave(function(){u?e(this).find("canvas").stop(!0,!0).fadeOut():e(this).find("canvas").stop(!0,!0).fadeIn()}))}):(e(n).each(function(t,n){var r=e(n).find("img"),i=e(n).find("img").prop("src"),s=e(r).prop("width"),o=e(r).prop("height");e("<img src="+i+' width="'+s+'" height="'+o+'" class="ieFix" /> ').prependTo(n),e(".ieFix").css({position:"absolute",top:0,left:0,filter:"progid:DXImageTransform.Microsoft.BasicImage(grayscale=1)",display:u?"none":"block"})}),s&&(e(n).mouseenter(function(){u?e(this).children(".ieFix").stop(!0,!0).fadeIn():e(this).children(".ieFix").stop(!0,!0).fadeOut()}),e(n).mouseleave(function(){u?e(this).children(".ieFix").stop(!0,!0).fadeOut():e(this).children(".ieFix").stop(!0,!0).fadeIn()}))),a&&l.on("resize orientationchange",n.resizeImages)},this.resizeImages=function(){e(n).each(function(t,n){var r=e(n).find("img:not(.ieFix)"),i,s;h?(i=e(r).prop("width"),s=e(r).prop("height")):(i=e(r).width(),s=e(r).height()),e(this).find(".ieFix, canvas").css({width:i,height:s})})},r.init(t)}})})(jQuery);