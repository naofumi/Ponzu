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
// We will try to remove dependency on jQuery
//= require jquery
//= require jquery_ujs
//= require_tree .

// This sets the accept header correctly for the rails.ujs Ajax calls.
$(document).on('ajax:beforeSend', function(event, xhr, settings){
  xhr.setRequestHeader('accept', 'text/html, application/json;q=0.9, text/javascript;q=0.8');
})

KSAjax.ajax = function(options){
  options.type = options.method;
  options.timeout = options.timeout || 5000;
  options.context = options.callbackContext || document.body;
  options.headers = {Accept: 'text/html, application/json;q=0.9, text/javascript;q=0.8',
                     'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8'};

  // I couldn't find a way to get jQuery to automatically evaluate a Javascript response
  // so I wrote it here. I can't get jQuery to respond based on content-type.
  var successCallback = options.success;
  var evalJS = function(data, textStatus, jqXHR) {
    var ct = jqXHR.getResponseHeader('content-type');
    if (ct.indexOf('javascript') != -1) {
      eval(data)
    } else if (successCallback) {
      successCallback(data, textStatus, jqXHR);
    }
  };
  options.success = evalJS;
  $.ajax(options);
}

defaultEffect = function(fromElements, toElement, backwards, callback) {
  toElement.style.display = 'block';

  for (var i = 0; i < fromElements.length; i++) {
    fromElements[i].style.display = 'none';
  }

  if (callback) callback();
}

defaultTransitionSelector = function(){return {effect: defaultEffect}};

KSTransitionSelector.effectWhenNoFromElements = defaultTransitionSelector;
KSTransitionSelector.setAnimationAndDirectionFromElement = defaultTransitionSelector;
KSTransitionSelector.transition = defaultTransitionSelector;
KSTransitionSelector.resetEffect = defaultTransitionSelector;

// Summary of Event management for IE8 and IE9
//
// Issues with IE9
// 1. IE9 events works most of the time. The issue that we have is that
//    it doesn't allow custom events. Since rails.js (the unobtrusive javascript library)
//    which handles regular Rails-ish ajax totally relies on custom events,
//    we can't handle forms and remote links. To solve this, we decided
//    to not use rails.js for IE9 (it is still loaded). We load 
//    jQuery and jquery_ujs and handle all events there. I'm not sure how
//    jquery_ujs does it, but it seems that jquery_ujs captures 'click', 'submit'
//    events before rails.js (even though rails.js is loaded earlier) and
//    prevents rails.js events from firing. This is good in this case.
//
// Issues with IE8
// 1.  IE8 uses the attachEvent() syntax for events, which is not a big deal.
// 2.  The big issue with IE8 is that submit events don't bubble. This is 
//     solved in jquery_ujs.js but not in rails.js. We need to use jQuery and jquery_ujs.js.

// Since IE cannot handle custom events, we use jQuery events all the way.
kss.sendEvent = function(type, node, properties){
  node = node || document;
  // In regular Kamishibai, the properties are added to the
  // event object when we send the event.
  // However, with jQuery, we cannot directly manipulate the
  // event object inside the trigger call.
  // Instead, we modify the event in the event listener, prior
  // to sending the event to the handler.
  $(node).trigger(type, properties)
}

var railsUjsTargetStash;
$(document).on('ajax:before', function(event, data){
  var target = event.target;
  railsUjsTargetStash = target;


  // In IE, the invalidation callbacks were not firing, presumably because
  // the jquery_ujs.js callbacks were firing first and then blocking.
  // In pure Javascript, you can't stop events firing on same element,
  // but jQuery does it.
  // Not sure how this happens, but we ensure that we invalidate here.
  if (target && target.hasAttribute('data-invalidates-keys')) {
    var invalidateKeysString = target.getAttribute('data-invalidates-keys');
    KSCache.invalidateCache(invalidateKeysString);
  }

})

kss.addEventListener = function(element, type, listener) {
  $(element).on(type, function(event, properties) {
    var myEvent = event;
    // var myEvent = (event.originalEvent || event);
    if (!myEvent.target) {myEvent.target = event.target};


    // jQuery sets the event.target of an 'ajaxSuccess'
    // event to the DOM document. This means that we
    // cannot access the caller from the callback.
    // We set event.target from railsUjsTargetStash
    // which is set using the 'ajax:before' handle in
    // jquery_ujs.js.
    //
    // We also moved away from 'ajax:success' (jquery_ujs.js event)
    // to 'ajaxSuccess' (jquery.js event). This is because
    // 'ajax:success' cannot access the ajax URL. This is also
    // good because regular Kamishibai callbacks were 
    // firing from KSAjax.js and not rails.js.
    var data, status, xhr;
    if (type == "ajaxSuccess" || type == "ajaxComplete" || type == "cachedAjaxSuccess") {
      xhr = arguments[1]
      data = xhr.responseText;
      status = xhr.statusText;
      ajaxOptions = arguments[2];
      myEvent.data = data;
      myEvent.xhr = xhr;
      myEvent.ajaxOptions = ajaxOptions;
      myEvent.target = railsUjsTargetStash;
      // ToDo: myEvent.xhr should hold raw xhr object
      //       ajaxOptions.url should hold URL
    } else if (properties) {
      for (p in properties){
        myEvent[p] = properties[p];
      }
    }
    if (typeof listener === 'function') {
      listener(myEvent);
    } else {
      listener.handleEvent(myEvent);
    }
  })
}

// TODO: We should find a better way of doing this.
kss.addEventListener(document, 'ajaxSuccess', function(event){
  var data = event.data;
  var target = event.target;
  // var target = event.target && kss.closestByTagName(event.target, 'form', true);
  if (target && 
      target.hasAttribute('data-ks-insert-response') && data) {
    console.log('Insert response because data-ks-insert-response was set');
    KSController.insertAjaxIntoDom(data, 'success', event.xhr, event.ajaxOptions.url)
  }
})

kss.addEventListener(document, 'cachedAjaxSuccess', function(event){
  var data = event.data;
  var target = event.target;
  // var target = event.target && kss.closestByTagName(event.target, 'form', true);
  if (target && 
      target.hasAttribute('data-ks-insert-response') && data) {
    console.log('Insert response because data-ks-insert-response was set');
    KSController.insertAjaxIntoDom(data, 'success', event.xhr, event.ajaxOptions.url)
  }
})

// $(document).on('ajaxSuccess', function(event, xhr, ajaxOptions){
//   event.ajaxOptions = ajaxOptions;
//   event.xhr = xhr;
//   event.data = xhr.responseText;
//   KSAjax.successHandler(event);
// })
