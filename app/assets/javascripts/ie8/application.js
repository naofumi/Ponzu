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
// We have already loaded jquery for ie9
// require jquery
// require jquery_ujs
//= require_tree .

alert('現在 Internet Explorer 8でうまく動作しなくなっております。現在、原因を調査中ですので、もうしばらくお待ちください。Internet Explorer 9以上、もしくはFirefox, Chromeでは問題なく動作しています。');

document.getElementsByClassName = function(className){
	return $('.' + className).get();
}

kss.next = function(element) {
  return $(element).next().get(0)
}

// $(document).on('click', 'a', function(event){
//   if (!event.target) {
//     event.preventDefault();
//     event.stopPropagation();
//     return false;
//   } else {
//     return true;
//   }
// })

// $(document).on('click', 'a#user_menu_button', function(event){
//   var target = this;
//   console.log("event fired 2 " + this.id + event.type);
//   if (target.id === 'user_menu_button') {
//     var menu = $(target).next().get(0);
//     if (kss.isVisible(menu)) {
//       kss.hide(menu);
//     } else {
//       kss.show(menu, true);
//     }
//     event.preventDefault();
//     event.stopPropagation();
//   }
// });


Array.prototype.map = function(callback) {
  result = [];
  for (var i = 0; i < this.length; i++) {
    result.push(callback(this[i]));
  };
  return result;
}

function defaultEffect (fromElements, toElement, backwards, callback) {
  toElement.style.display = 'block';

  for (var i = 0; i < fromElements.length; i++) {
    fromElements[i].style.display = 'none';
  }
  if (callback) callback();
}

KSTransitionSelector.transition = function(){ return {effect: defaultEffect}};

KSScrollMemory.set = function(options) {
  var radix = 36;
  var CACHE_PREFIX = "KSScrollMemory-";
  var href = options.href !== undefined ? options.href : window.location.href;
  // IE does not support pageXOffset https://developer.mozilla.org/ja/docs/DOM/window.scrollX
  var x = options.scrollX !== undefined ? options.scrollX : (document.documentElement || document.body.parentNode || document.body).scrollLeft;
  var y = options.scrollY !== undefined ? options.scrollY : (document.documentElement || document.body.parentNode || document.body).scrollTop;
  var clicked = options.clicked || null;
  var string = JSON.stringify({scrollX: x.toString(radix), 
                               scrollY: y.toString(radix),
                               clicked: clicked})
  sessionStorage.setItem(CACHE_PREFIX + href, string);
}

Array.prototype.indexOf = function(needle) {
  for (var i = 0; i < this.length; i++) {
    if (this[i] == needle) 
      return i;
  };
  return -1;
}

// IE8 doesn't allow Array.prototype.slice.call
// https://bitbucket.org/scott_koon/bootstrap/issue/2/ie8-doesnt-allow-arrayprototypeslicecall
Array.prototype.slice = function(begin, end) {
  end = end || this.length;
  var result = [];
  for (var i = 0; i < this.length; i++) {
    result.push(this[i]);
  };
  return result;
}

// http://jmblog.jp/archives/169
Event.prototype.preventDefault = function(){
  this.returnValue = false;
}

// http://jmblog.jp/archives/169
Event.prototype.stopPropagation = function(){
  this.cancelBubble = true;
}

// http://stackoverflow.com/questions/12201485/create-script-tag-in-ie8
//
// It might malfunction if there are many javascripts running concurrently
KSDom.executeScript = function(javascriptCode){
  var scriptTag = document.createElement('script');
  scriptTag.text = javascriptCode;
  document.getElementsByTagName('head')[0].appendChild(scriptTag);
}

// http://bezwebs.com/blog/16-blog/26-inner-html-issues-with-ie-8.html
// Get jQuery to work around ie8 bugs.
KSDom.replaceInnerHtml = function(stalePage, page) {
  return $(stalePage).html($(page).html()).get(0)
}
// IE8 does not support form event bubbling.
// We use jQuery for this
// $(document).on('submit', 'form', function(event){
//   var target = this;
//   if (target && target.hasAttribute('data-invalidates-keys')) {
//     var invalidateKeysString = target.getAttribute('data-invalidates-keys');
//     KSCache.invalidateCache(invalidateKeysString, true);
//   }
// })


// CssChanger.js uses Element#textContent which
// doesn't work with style elements in IE8.
// IE8 requres that we get the styleSheet object and 
// stuff.
// https://github.com/mootools/mootools-core/issues/2479
window.cssSet = function(cssString, cssId) {
  cssId = cssId || "css-changer-inserted";
  css = document.getElementById(cssId) || createCssElement(cssId);
  css.styleSheet.cssText = cssString;
}

createCssElement = function(cssId) {
  css = document.createElement('style');
  css.id = cssId;
  return document.getElementsByTagName('head')[0].appendChild(css);
}
