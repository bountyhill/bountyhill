/*
 * Inline Form Validation Engine 2.5.4, jQuery plugin
 *
 * Copyright(c) 2010, Cedric Dugas
 * http://www.position-absolute.com
 *
 * 2.0 Rewrite by Olivier Refalo
 * http://www.crionics.com
 *
 * Form validation engine allowing custom regex rules to be added.
 * Licensed under the MIT License
 */
(function(e){"use strict";var t={init:function(n){var r=this;if(!r.data("jqv")||r.data("jqv")==null)n=t._saveOptions(r,n),e(".formError").live("click",function(){e(this).fadeOut(150,function(){e(this).parent(".formErrorOuter").remove(),e(this).remove()})});return this},attach:function(n){if(!e(this).is("form"))return alert("Sorry, jqv.attach() only applies to a form"),this;var r=this,i;return n?i=t._saveOptions(r,n):i=r.data("jqv"),i.validateAttribute=r.find("[data-validation-engine*=validate]").length?"data-validation-engine":"class",i.binded&&(r.find("["+i.validateAttribute+"*=validate]").not("[type=checkbox]").not("[type=radio]").not(".datepicker").bind(i.validationEventTrigger,t._onFieldEvent),r.find("["+i.validateAttribute+"*=validate][type=checkbox],["+i.validateAttribute+"*=validate][type=radio]").bind("click",t._onFieldEvent),r.find("["+i.validateAttribute+"*=validate][class*=datepicker]").bind(i.validationEventTrigger,{delay:300},t._onFieldEvent)),i.autoPositionUpdate&&e(window).bind("resize",{noAnimation:!0,formElem:r},t.updatePromptsPosition),r.bind("submit",t._onSubmitEvent),this},detach:function(){if(!e(this).is("form"))return alert("Sorry, jqv.detach() only applies to a form"),this;var n=this,r=n.data("jqv");return n.find("["+r.validateAttribute+"*=validate]").not("[type=checkbox]").unbind(r.validationEventTrigger,t._onFieldEvent),n.find("["+r.validateAttribute+"*=validate][type=checkbox],[class*=validate][type=radio]").unbind("click",t._onFieldEvent),n.unbind("submit",t.onAjaxFormComplete),n.find("["+r.validateAttribute+"*=validate]").not("[type=checkbox]").die(r.validationEventTrigger,t._onFieldEvent),n.find("["+r.validateAttribute+"*=validate][type=checkbox]").die("click",t._onFieldEvent),n.die("submit",t.onAjaxFormComplete),n.removeData("jqv"),r.autoPositionUpdate&&e(window).unbind("resize",t.updatePromptsPosition),this},validate:function(){if(e(this).is("form"))return t._validateFields(this);var n=e(this).closest("form"),r=n.data("jqv"),i=t._validateField(e(this),r);return r.onSuccess&&r.InvalidFields.length==0?r.onSuccess():r.onFailure&&r.InvalidFields.length>0&&r.onFailure(),i},updatePromptsPosition:function(n){if(n&&this==window)var r=n.data.formElem,i=n.data.noAnimation;else var r=e(this.closest("form"));var s=r.data("jqv");return r.find("["+s.validateAttribute+"*=validate]").not(":disabled").each(function(){var n=e(this),r=t._getPrompt(n),o=e(r).find(".formErrorContent").html();r&&t._updatePrompt(n,e(r),o,undefined,!1,s,i)}),this},showPrompt:function(e,n,r,i){var s=this.closest("form"),o=s.data("jqv");return o||(o=t._saveOptions(this,o)),r&&(o.promptPosition=r),o.showArrow=i==1,t._showPrompt(this,e,n,!1,o),this},hide:function(){var n=e(this).closest("form");if(n.length==0)return this;var r=n.data("jqv"),i;return e(this).is("form")?i="parentForm"+t._getClassName(e(this).attr("id")):i=t._getClassName(e(this).attr("id"))+"formError",e("."+i).fadeTo(r.fadeDuration,.3,function(){e(this).parent(".formErrorOuter").remove(),e(this).remove()}),this},hideAll:function(){var t=this,n=t.data("jqv"),r=n?n.fadeDuration:.3;return e(".formError").fadeTo(r,.3,function(){e(this).parent(".formErrorOuter").remove(),e(this).remove()}),this},_onFieldEvent:function(n){var r=e(this),i=r.closest("form"),s=i.data("jqv");window.setTimeout(function(){t._validateField(r,s),s.InvalidFields.length==0&&s.onSuccess?s.onSuccess():s.InvalidFields.length>0&&s.onFailure&&s.onFailure()},n.data?n.data.delay:0)},_onSubmitEvent:function(){var n=e(this),r=n.data("jqv"),i=t._validateFields(n,r.ajaxFormValidation);return i&&r.ajaxFormValidation?(t._validateFormWithAjax(n,r),!1):r.onValidationComplete?(r.onValidationComplete(n,i),!1):i},_checkAjaxStatus:function(t){var n=!0;return e.each(t.ajaxValidCache,function(e,t){if(!t)return n=!1,!1}),n},_validateFields:function(n,r){var i=n.data("jqv"),s=!1;n.trigger("jqv.form.validating");var o=null;n.find("["+i.validateAttribute+"*=validate]").not(":disabled").each(function(){var u=e(this),a=[];if(e.inArray(u.attr("name"),a)<0){s|=t._validateField(u,i,r),s&&o==null&&(u.is(":hidden")&&i.prettySelect?o=u=n.find("#"+i.usePrefix+u.attr("id")+i.useSuffix):o=u);if(i.doNotShowAllErrosOnSubmit)return!1;a.push(u.attr("name"))}}),n.trigger("jqv.form.result",[s]);if(s){if(i.scroll){var u=o.offset().top,a=o.offset().left,f=i.promptPosition;typeof f=="string"&&f.indexOf(":")!=-1&&(f=f.substring(0,f.indexOf(":")));if(f!="bottomRight"&&f!="bottomLeft"){var l=t._getPrompt(o);u=l.offset().top}if(i.isOverflown){var c=e(i.overflownDIV);if(!c.length)return!1;var h=c.scrollTop(),p=-parseInt(c.offset().top);u+=h+p-5;var d=e(i.overflownDIV+":not(:animated)");d.animate({scrollTop:u},1100,function(){i.focusFirstField&&o.focus()})}else e("html:not(:animated),body:not(:animated)").animate({scrollTop:u,scrollLeft:a},1100,function(){i.focusFirstField&&o.focus()})}else i.focusFirstField&&o.focus();return!1}return!0},_validateFormWithAjax:function(n,r){var i=n.serialize(),s=r.ajaxFormValidationURL?r.ajaxFormValidationURL:n.attr("action");e.ajax({type:r.ajaxFormValidationMethod,url:s,cache:!1,dataType:"json",data:i,form:n,methods:t,options:r,beforeSend:function(){return r.onBeforeAjaxFormValidation(n,r)},error:function(e,n){t._ajaxError(e,n)},success:function(i){if(i!==!0){var s=!1;for(var o=0;o<i.length;o++){var u=i[o],a=u[0],f=e(e("#"+a)[0]);if(f.length==1){var l=u[2];if(u[1]==1)if(l==""||!l)t._closePrompt(f);else{if(r.allrules[l]){var c=r.allrules[l].alertTextOk;c&&(l=c)}t._showPrompt(f,l,"pass",!1,r,!0)}else{s|=!0;if(r.allrules[l]){var c=r.allrules[l].alertText;c&&(l=c)}t._showPrompt(f,l,"",!1,r,!0)}}}r.onAjaxFormComplete(!s,n,i,r)}else r.onAjaxFormComplete(!0,n,"",r)}})},_validateField:function(n,r,i){n.attr("id")||(n.attr("id","form-validation-field-"+e.validationEngine.fieldIdCounter),++e.validationEngine.fieldIdCounter);if(n.is(":hidden")&&!r.prettySelect||n.parents().is(":hidden"))return!1;var s=n.attr(r.validateAttribute),o=/validate\[(.*)\]/.exec(s);if(!o)return!1;var u=o[1],a=u.split(/\[|,|\]/),f=!1,l=n.attr("name"),c="",h=!1;r.isError=!1,r.showArrow=!0;var p=e(n.closest("form"));for(var d=0;d<a.length;d++){a[d]=a[d].replace(" ","");var v=undefined;switch(a[d]){case"required":h=!0,v=t._getErrorMessage(p,n,a[d],a,d,r,t._required);break;case"custom":v=t._getErrorMessage(p,n,a[d],a,d,r,t._custom);break;case"groupRequired":var m="["+r.validateAttribute+"*="+a[d+1]+"]",g=p.find(m).eq(0);if(g[0]!=n[0]){t._validateField(g,r,i),r.showArrow=!0;continue}v=t._getErrorMessage(p,n,a[d],a,d,r,t._groupRequired),v&&(h=!0),r.showArrow=!1;break;case"ajax":i||(t._ajax(n,a,d,r),f=!0);break;case"minSize":v=t._getErrorMessage(p,n,a[d],a,d,r,t._minSize);break;case"maxSize":v=t._getErrorMessage(p,n,a[d],a,d,r,t._maxSize);break;case"min":v=t._getErrorMessage(p,n,a[d],a,d,r,t._min);break;case"max":v=t._getErrorMessage(p,n,a[d],a,d,r,t._max);break;case"past":v=t._past(p,n,a,d,r);break;case"future":v=t._future(p,n,a,d,r);break;case"dateRange":var m="["+r.validateAttribute+"*="+a[d+1]+"]",g=p.find(m).eq(0),y=p.find(m).eq(1);if(g[0].value||y[0].value)v=t._dateRange(g,y,a,d,r);v&&(h=!0),r.showArrow=!1;break;case"dateTimeRange":var m="["+r.validateAttribute+"*="+a[d+1]+"]",g=p.find(m).eq(0),y=p.find(m).eq(1);if(g[0].value||y[0].value)v=t._dateTimeRange(g,y,a,d,r);v&&(h=!0),r.showArrow=!1;break;case"maxCheckbox":v=t._getErrorMessage(p,n,a[d],a,d,r,t._maxCheckbox),n=e(p.find("input[name='"+l+"']"));break;case"minCheckbox":v=t._getErrorMessage(p,n,a[d],a,d,r,t._minCheckbox),n=e(p.find("input[name='"+l+"']"));break;case"equals":v=t._getErrorMessage(p,n,a[d],a,d,r,t._equals);break;case"funcCall":v=t._getErrorMessage(p,n,a[d],a,d,r,t._funcCall);break;case"creditCard":v=t._getErrorMessage(p,n,a[d],a,d,r,t._creditCard);break;case"condRequired":v=t._condRequired(n,a,d,r),v!==undefined&&(h=!0);break;default:}v!==undefined&&(c+=v+"<br/>",r.isError=!0)}!h&&n.val()==""&&!v&&(r.isError=!1);var b=n.prop("type");(b=="radio"||b=="checkbox")&&p.find("input[name='"+l+"']").size()>1&&(n=e(p.find("input[name='"+l+"'][type!=hidden]:first")),r.showArrow=!1),n.is(":hidden")&&r.prettySelect&&(n=p.find("#"+r.usePrefix+n.attr("id")+r.useSuffix)),r.isError?t._showPrompt(n,c,"",!1,r):f||t._closePrompt(n),f||n.trigger("jqv.field.result",[n,r.isError,c]);var w=e.inArray(n[0],r.InvalidFields);return w==-1?r.isError&&r.InvalidFields.push(n[0]):r.isError||r.InvalidFields.splice(w,1),r.isError},_getErrorMessage:function(e,n,r,i,s,o,u){if(r=="custom"){var a=i.indexOf(r)+1,f=i[a];r="custom["+f+"]"}var l=n.context.attributes.id.nodeValue,c=n.context.attributes["class"].nodeValue,h=c.split(" "),p=t._getCustomErrorMessage(l,h,r,o),d;return r=="future"||r=="past"?d=u(e,n,i,s,o):d=u(n,i,s,o),d!=undefined&&p?p:d},_getCustomErrorMessage:function(e,t,n,r){var i=!1;e="#"+e;if(typeof r.custom_error_messages[e]!="undefined"&&typeof r.custom_error_messages[e][n]!="undefined")i=r.custom_error_messages[e][n].message;else if(t.length>0)for(var s=0;s<t.length&&t.length>0;s++){var o="."+t[s];if(typeof r.custom_error_messages[o]!="undefined"&&typeof r.custom_error_messages[o][n]!="undefined"){i=r.custom_error_messages[o][n].message;break}}return!i&&typeof r.custom_error_messages[n]!="undefined"&&typeof r.custom_error_messages[n]["message"]!="undefined"&&(i=r.custom_error_messages[n].message),i},_required:function(t,n,r,i){switch(t.prop("type")){case"text":case"password":case"textarea":case"file":default:if(!e.trim(t.val())||t.val()==t.attr("data-validation-placeholder"))return i.allrules[n[r]].alertText;break;case"radio":case"checkbox":var s=t.closest("form"),o=t.attr("name");if(s.find("input[name='"+o+"']:checked").size()==0)return s.find("input[name='"+o+"']").size()==1?i.allrules[n[r]].alertTextCheckboxe:i.allrules[n[r]].alertTextCheckboxMultiple;break;case"select-one":if(!t.val())return i.allrules[n[r]].alertText;break;case"select-multiple":if(!t.find("option:selected").val())return i.allrules[n[r]].alertText}},_groupRequired:function(n,r,i,s){var o="["+s.validateAttribute+"*="+r[i+1]+"]",u=!1;n.closest("form").find(o).each(function(){if(!t._required(e(this),r,i,s))return u=!0,!1});if(!u)return s.allrules[r[i]].alertText},_custom:function(e,t,n,r){var i=t[n+1],s=r.allrules[i],o;if(!s){alert("jqv:custom rule not found - "+i);return}if(s.regex){var u=s.regex;if(!u){alert("jqv:custom regex not found - "+i);return}var a=new RegExp(u);if(!a.test(e.val()))return r.allrules[i].alertText}else{if(!s.func){alert("jqv:custom type not allowed "+i);return}o=s.func;if(typeof o!="function"){alert("jqv:custom parameter 'function' is no function - "+i);return}if(!o(e,t,n,r))return r.allrules[i].alertText}},_funcCall:function(e,t,n,r){var i=t[n+1],s;if(i.indexOf(".")>-1){var o=i.split("."),u=window;while(o.length)u=u[o.shift()];s=u}else s=window[i]||r.customFunctions[i];if(typeof s=="function")return s(e,t,n,r)},_equals:function(t,n,r,i){var s=n[r+1];if(t.val()!=e("#"+s).val())return i.allrules.equals.alertText},_maxSize:function(e,t,n,r){var i=t[n+1],s=e.val().length;if(s>i){var o=r.allrules.maxSize;return o.alertText+i+o.alertText2}},_minSize:function(e,t,n,r){var i=t[n+1],s=e.val().length;if(s<i){var o=r.allrules.minSize;return o.alertText+i+o.alertText2}},_min:function(e,t,n,r){var i=parseFloat(t[n+1]),s=parseFloat(e.val());if(s<i){var o=r.allrules.min;return o.alertText2?o.alertText+i+o.alertText2:o.alertText+i}},_max:function(e,t,n,r){var i=parseFloat(t[n+1]),s=parseFloat(e.val());if(s>i){var o=r.allrules.max;return o.alertText2?o.alertText+i+o.alertText2:o.alertText+i}},_past:function(n,r,i,s,o){var u=i[s+1],a=e(n.find("input[name='"+u.replace(/^#+/,"")+"']")),f;if(u.toLowerCase()=="now")f=new Date;else if(undefined!=a.val()){if(a.is(":disabled"))return;f=t._parseDate(a.val())}else f=t._parseDate(u);var l=t._parseDate(r.val());if(l>f){var c=o.allrules.past;return c.alertText2?c.alertText+t._dateToString(f)+c.alertText2:c.alertText+t._dateToString(f)}},_future:function(n,r,i,s,o){var u=i[s+1],a=e(n.find("input[name='"+u.replace(/^#+/,"")+"']")),f;if(u.toLowerCase()=="now")f=new Date;else if(undefined!=a.val()){if(a.is(":disabled"))return;f=t._parseDate(a.val())}else f=t._parseDate(u);var l=t._parseDate(r.val());if(l<f){var c=o.allrules.future;return c.alertText2?c.alertText+t._dateToString(f)+c.alertText2:c.alertText+t._dateToString(f)}},_isDate:function(e){var t=new RegExp(/^\d{4}[\/\-](0?[1-9]|1[012])[\/\-](0?[1-9]|[12][0-9]|3[01])$|^(?:(?:(?:0?[13578]|1[02])(\/|-)31)|(?:(?:0?[1,3-9]|1[0-2])(\/|-)(?:29|30)))(\/|-)(?:[1-9]\d\d\d|\d[1-9]\d\d|\d\d[1-9]\d|\d\d\d[1-9])$|^(?:(?:0?[1-9]|1[0-2])(\/|-)(?:0?[1-9]|1\d|2[0-8]))(\/|-)(?:[1-9]\d\d\d|\d[1-9]\d\d|\d\d[1-9]\d|\d\d\d[1-9])$|^(0?2(\/|-)29)(\/|-)(?:(?:0[48]00|[13579][26]00|[2468][048]00)|(?:\d\d)?(?:0[48]|[2468][048]|[13579][26]))$/);return t.test(e)},_isDateTime:function(e){var t=new RegExp(/^\d{4}[\/\-](0?[1-9]|1[012])[\/\-](0?[1-9]|[12][0-9]|3[01])\s+(1[012]|0?[1-9]){1}:(0?[1-5]|[0-6][0-9]){1}:(0?[0-6]|[0-6][0-9]){1}\s+(am|pm|AM|PM){1}$|^(?:(?:(?:0?[13578]|1[02])(\/|-)31)|(?:(?:0?[1,3-9]|1[0-2])(\/|-)(?:29|30)))(\/|-)(?:[1-9]\d\d\d|\d[1-9]\d\d|\d\d[1-9]\d|\d\d\d[1-9])$|^((1[012]|0?[1-9]){1}\/(0?[1-9]|[12][0-9]|3[01]){1}\/\d{2,4}\s+(1[012]|0?[1-9]){1}:(0?[1-5]|[0-6][0-9]){1}:(0?[0-6]|[0-6][0-9]){1}\s+(am|pm|AM|PM){1})$/);return t.test(e)},_dateCompare:function(e,t){return new Date(e.toString())<new Date(t.toString())},_dateRange:function(e,n,r,i,s){if(!e[0].value&&n[0].value||e[0].value&&!n[0].value)return s.allrules[r[i]].alertText+s.allrules[r[i]].alertText2;if(!t._isDate(e[0].value)||!t._isDate(n[0].value))return s.allrules[r[i]].alertText+s.allrules[r[i]].alertText2;if(!t._dateCompare(e[0].value,n[0].value))return s.allrules[r[i]].alertText+s.allrules[r[i]].alertText2},_dateTimeRange:function(e,n,r,i,s){if(!e[0].value&&n[0].value||e[0].value&&!n[0].value)return s.allrules[r[i]].alertText+s.allrules[r[i]].alertText2;if(!t._isDateTime(e[0].value)||!t._isDateTime(n[0].value))return s.allrules[r[i]].alertText+s.allrules[r[i]].alertText2;if(!t._dateCompare(e[0].value,n[0].value))return s.allrules[r[i]].alertText+s.allrules[r[i]].alertText2},_maxCheckbox:function(e,t,n,r,i){var s=n[r+1],o=t.attr("name"),u=e.find("input[name='"+o+"']:checked").size();if(u>s)return i.showArrow=!1,i.allrules.maxCheckbox.alertText2?i.allrules.maxCheckbox.alertText+" "+s+" "+i.allrules.maxCheckbox.alertText2:i.allrules.maxCheckbox.alertText},_minCheckbox:function(e,t,n,r,i){var s=n[r+1],o=t.attr("name"),u=e.find("input[name='"+o+"']:checked").size();if(u<s)return i.showArrow=!1,i.allrules.minCheckbox.alertText+" "+s+" "+i.allrules.minCheckbox.alertText2},_creditCard:function(e,t,n,r){var i=!1,s=e.val().replace(/ +/g,"").replace(/-+/g,""),o=s.length;if(o>=14&&o<=16&&parseInt(s)>0){var u=0,n=o-1,a=1,f,l=new String;do f=parseInt(s.charAt(n)),l+=a++%2==0?f*2:f;while(--n>=0);for(n=0;n<l.length;n++)u+=parseInt(l.charAt(n));i=u%10==0}if(!i)return r.allrules.creditCard.alertText},_ajax:function(n,r,i,s){var o=r[i+1],u=s.allrules[o],a=u.extraData,f=u.extraDataDynamic,l={fieldId:n.attr("id"),fieldValue:n.val()};if(typeof a=="object")e.extend(l,a);else if(typeof a=="string"){var c=a.split("&");for(var i=0;i<c.length;i++){var h=c[i].split("=");h[0]&&h[0]&&(l[h[0]]=h[1])}}if(f){var p=[],d=String(f).split(",");for(var i=0;i<d.length;i++){var v=d[i];if(e(v).length){var m=n.closest("form").find(v).val(),g=v.replace("#","")+"="+escape(m);l[v.replace("#","")]=m}}}s.isError||e.ajax({type:s.ajaxFormValidationMethod,url:u.url,cache:!1,dataType:"json",data:l,field:n,rule:u,methods:t,options:s,beforeSend:function(){var e=u.alertTextLoad;e&&t._showPrompt(n,e,"load",!0,s)},error:function(e,n){t._ajaxError(e,n)},success:function(n){var r=n[0],i=e(e("input[id='"+r+"']")[0]);if(i.length==1){var o=n[1],a=n[2];if(!o){s.ajaxValidCache[r]=!1,s.isError=!0;if(a){if(s.allrules[a]){var f=s.allrules[a].alertText;f&&(a=f)}}else a=u.alertText;t._showPrompt(i,a,"",!0,s)}else{s.ajaxValidCache[r]!==undefined&&(s.ajaxValidCache[r]=!0);if(a){if(s.allrules[a]){var f=s.allrules[a].alertTextOk;f&&(a=f)}}else a=u.alertTextOk;a?t._showPrompt(i,a,"pass",!0,s):t._closePrompt(i)}}i.trigger("jqv.field.result",[i,s.isError,a])}})},_ajaxError:function(e,t){e.status==0&&t==null?alert("The page is not served from a server! ajax call failed"):typeof console!="undefined"&&console.log("Ajax error: "+e.status+" "+t)},_dateToString:function(e){return e.getFullYear()+"-"+(e.getMonth()+1)+"-"+e.getDate()},_parseDate:function(e){var t=e.split("-");return t==e&&(t=e.split("/")),new Date(t[0],t[1]-1,t[2])},_showPrompt:function(e,n,r,i,s,o){var u=t._getPrompt(e);o&&(u=!1),u?t._updatePrompt(e,u,n,r,i,s):t._buildPrompt(e,n,r,i,s)},_buildPrompt:function(n,r,i,s,o){var u=e("<div>");u.addClass(t._getClassName(n.attr("id"))+"formError"),u.addClass("parentForm"+t._getClassName(n.parents("form").attr("id"))),u.addClass("formError");switch(i){case"pass":u.addClass("greenPopup");break;case"load":u.addClass("blackPopup");break;default:}s&&u.addClass("ajaxed");var a=e("<div>").addClass("formErrorContent").html(r).appendTo(u);if(o.showArrow){var f=e("<div>").addClass("formErrorArrow"),l=n.data("promptPosition")||o.promptPosition;if(typeof l=="string"){var c=l.indexOf(":");c!=-1&&(l=l.substring(0,c))}switch(l){case"bottomLeft":case"bottomRight":u.find(".formErrorContent").before(f),f.addClass("formErrorArrowBottom").html('<div class="line1"><!-- --></div><div class="line2"><!-- --></div><div class="line3"><!-- --></div><div class="line4"><!-- --></div><div class="line5"><!-- --></div><div class="line6"><!-- --></div><div class="line7"><!-- --></div><div class="line8"><!-- --></div><div class="line9"><!-- --></div><div class="line10"><!-- --></div>');break;case"topLeft":case"topRight":f.html('<div class="line10"><!-- --></div><div class="line9"><!-- --></div><div class="line8"><!-- --></div><div class="line7"><!-- --></div><div class="line6"><!-- --></div><div class="line5"><!-- --></div><div class="line4"><!-- --></div><div class="line3"><!-- --></div><div class="line2"><!-- --></div><div class="line1"><!-- --></div>'),u.append(f)}}n.closest(".ui-dialog").length&&u.addClass("formErrorInsideDialog"),u.css({opacity:0,position:"absolute"}),n.before(u);var c=t._calculatePosition(n,u,o);return u.css({top:c.callerTopPosition,left:c.callerleftPosition,marginTop:c.marginTopSize,opacity:0}).data("callerField",n),o.autoHidePrompt&&setTimeout(function(){u.animate({opacity:0},function(){u.closest(".formErrorOuter").remove(),u.remove()})},o.autoHideDelay),u.animate({opacity:.87})},_updatePrompt:function(e,n,r,i,s,o,u){if(n){typeof i!="undefined"&&(i=="pass"?n.addClass("greenPopup"):n.removeClass("greenPopup"),i=="load"?n.addClass("blackPopup"):n.removeClass("blackPopup")),s?n.addClass("ajaxed"):n.removeClass("ajaxed"),n.find(".formErrorContent").html(r);var a=t._calculatePosition(e,n,o),f={top:a.callerTopPosition,left:a.callerleftPosition,marginTop:a.marginTopSize};u?n.css(f):n.animate(f)}},_closePrompt:function(e){var n=t._getPrompt(e);n&&n.fadeTo("fast",0,function(){n.parent(".formErrorOuter").remove(),n.remove()})},closePrompt:function(e){return t._closePrompt(e)},_getPrompt:function(n){var r=e(n).closest("form").attr("id"),i=t._getClassName(n.attr("id"))+"formError",s=e("."+t._escapeExpression(i)+".parentForm"+r)[0];if(s)return e(s)},_escapeExpression:function(e){return e.replace(/([#;&,\.\+\*\~':"\!\^$\[\]\(\)=>\|])/g,"\\$1")},isRTL:function(t){var n=e(document),r=e("body"),i=t&&t.hasClass("rtl")||t&&(t.attr("dir")||"").toLowerCase()==="rtl"||n.hasClass("rtl")||(n.attr("dir")||"").toLowerCase()==="rtl"||r.hasClass("rtl")||(r.attr("dir")||"").toLowerCase()==="rtl";return Boolean(i)},_calculatePosition:function(e,t,n){var r,i,s,o=e.width(),u=e.position().left,a=e.position().top,f=e.height(),l=t.height();r=i=0,s=-l;var c=e.data("promptPosition")||n.promptPosition,h="",p="",d=0,v=0;typeof c=="string"&&c.indexOf(":")!=-1&&(h=c.substring(c.indexOf(":")+1),c=c.substring(0,c.indexOf(":")),h.indexOf(",")!=-1&&(p=h.substring(h.indexOf(",")+1),h=h.substring(0,h.indexOf(",")),v=parseInt(p),isNaN(v)&&(v=0)),d=parseInt(h),isNaN(h)&&(h=0));switch(c){default:case"topRight":i+=u+o-30,r+=a;break;case"topLeft":r+=a,i+=u;break;case"centerRight":r=a+4,s=0,i=u+e.outerWidth(!0)+5;break;case"centerLeft":i=u-(t.width()+2),r=a+4,s=0;break;case"bottomLeft":r=a+e.height()+5,s=0,i=u;break;case"bottomRight":i=u+o-30,r=a+e.height()+5,s=0}return i+=d,r+=v,{callerTopPosition:r+"px",callerleftPosition:i+"px",marginTopSize:s+"px"}},_saveOptions:function(t,n){if(e.validationEngineLanguage)var r=e.validationEngineLanguage.allRules;else e.error("jQuery.validationEngine rules are not loaded, plz add localization files to the page");e.validationEngine.defaults.allrules=r;var i=e.extend(!0,{},e.validationEngine.defaults,n);return t.data("jqv",i),i},_getClassName:function(e){if(e)return e.replace(/:/g,"_").replace(/\./g,"_")},_condRequired:function(e,n,r,i){var s,o;for(s=r+1;s<n.length;s++){o=jQuery("#"+n[s]).first();if(o.length&&t._required(o,["required"],0,i)==undefined)return t._required(e,["required"],0,i)}}};e.fn.validationEngine=function(n){var r=e(this);if(!r[0])return!1;if(typeof n=="string"&&n.charAt(0)!="_"&&t[n])return n!="showPrompt"&&n!="hide"&&n!="hideAll"&&t.init.apply(r),t[n].apply(r,Array.prototype.slice.call(arguments,1));if(typeof n=="object"||!n)return t.init.apply(r,arguments),t.attach.apply(r);e.error("Method "+n+" does not exist in jQuery.validationEngine")},e.validationEngine={fieldIdCounter:0,defaults:{validationEventTrigger:"blur",scroll:!0,focusFirstField:!0,promptPosition:"topRight",bindMethod:"bind",inlineAjax:!1,ajaxFormValidation:!1,ajaxFormValidationURL:!1,ajaxFormValidationMethod:"get",onAjaxFormComplete:e.noop,onBeforeAjaxFormValidation:e.noop,onValidationComplete:!1,doNotShowAllErrosOnSubmit:!1,custom_error_messages:{},binded:!0,showArrow:!0,isError:!1,ajaxValidCache:{},autoPositionUpdate:!1,InvalidFields:[],onSuccess:!1,onFailure:!1,autoHidePrompt:!1,autoHideDelay:1e4,fadeDuration:.3,prettySelect:!1,usePrefix:"",useSuffix:""}},e(function(){e.validationEngine.defaults.promptPosition=t.isRTL()?"topLeft":"topRight"})})(jQuery);