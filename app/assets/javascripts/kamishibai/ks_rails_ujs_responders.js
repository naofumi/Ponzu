// The ks_rails_ujs_responders.js file sets the event listeners that
// handle the Rails UJS responses in Kamishibai.
//
// Rails.js handles sending of the form or remote-link to the server.
// It does not handle the response at all, other than firing an
// 'ajaxSuccess' or 'ajaxError' event.
//
// Here we provide handlers that use Kamishibai logic
// to process the 'cachedAjaxSuccess' and 'ajaxError' events.

kamishibai.beforeInitialize(function(){
  /////////////////////
  //
  // Form sending additions to rails.js
  //
  ////////////////////
  //
  // There are two possible behaviours when sending a GET form in Kamishibai.
  // 1. Send the GET request for the form. (This is the default rails.js behaviour.)
  // 2. Point the URL to the resource defined by the form parameters.
  //
  // The first option is useful when we want to get a resource without changing the URL.
  // The second approach will fire a hashChange event, and let Kamishibai handle
  // retrieval of the resource.
  //
  // The second approach is especially useful when we have a search form.
  //
  // This listens to the 'submit' event on document whereas the default rails.js
  // listens on window. Therefore, this listener is handled first.
  kss.addEventListener(document, 'submit', function(event) {
    var target = event.target;
    if (target && (event.target.tagName.toUpperCase() == 'FORM') && 
        target.hasAttribute('data-ks_get_form')) {
      if (target.hasAttribute('data-remote') || target.hasAttribute('data-method')) {
        alert("Cannot use 'data-remote/method' when 'data-ks-get_form'");
        return;
      }
      var queryString = serialize(target);
      var resourceUrl = target.getAttribute('action') || KSUrl.parseHref(window.location.href).resourceUrl;
      var newPath = resourceUrl.replace(/\?.*$/, '') + '?' + queryString;
      kss.redirect("#!_" + newPath);
      event.preventDefault();
      event.stopPropagation();
    }
  })

  /////////////////////
  //
  // Ajax responding listeners.
  //
  ////////////////////
  //
  // Below is an outline of how forms should be managed in Kamishibai.
  //
  // === Normal Ajax forms
  // Sometimes we don't want Kamishibai to do anything. Instead we simply want
  // to process as old-fashioned rails_ujs. Then we simply set data-remote=true,
  // exactly as we would for rails_ujs. 
  //
  // === Forms that don't change the location but use Kamishibai to process the response.
  // Kamishibai can process the response without complicated Javascript and
  // this is often all that we need. For example, we might simply want to 
  // send an error notification.
  // In this case, we send the form via regular rails_ujs with data-remote=true.
  // We process the response in a callback by setting data-ks_insert_response.
  // If the response is Javascript, then that will be evaluated in KSAjax and event.data
  // will be set to null so we don't do any adverse insertion.
  //
  // === Forms that change location via redirect
  // The server response can cause a redirect by returning kss.redirect() as Javascript.
  // Thus we can do the POST-then-redirect behavior that is recommended for POST/PUT/DELETE forms.
  //
  // === Forms that actually are links
  // Regular GET forms are actually links in disguise. They simply direct the browser to the
  // location calculated from the form. To do the same behavior in Kamishibai, we
  // set the data-ks_get_form attribute. This is useful in searches where we often
  // want the URL to change so that the search results can be cached or bookmarked.
  //
  // Let's describe it in a different way; by what we want to achieve
  //
  // === POST/PUT/DELETE forms with redirects
  // This is the simplest method, which we use when we want to emulate traditional
  // form behavior (Simply show error messages on error, redirect on success).
  // 1. Set the 'data-remote' attribute on the form.
  // 2. Change the response to return "KSApp.notify;kss.redirect()" javascript on success and
  //    "KSApp.notify/error()" on error.
  //
  // === GET forms showing a new location (searches)
  // This is what we normally use on search. We change the location so that it is
  // cachable and bookmarkable.
  // 1. Set the 'data-ks_get_form' on the form.
  // 2. Don't set 'data-remote'.
  //
  // === POST/PUT/DELETE/GET forms that update portions of the page without changing location
  // This is what we use for 'likes' and 'my schedule'.
  // There are two options; 
  // 1. Process the response in an ajaxSuccess or ajaxSuccess callback (the regular rails_ujs method)
  // 2. Let Kamishibai process the response, intelligently and automatically inserting elements into the DOM
  // 
  // Option 1 (the rails_ujs way)
  // 1. Set 'data-remote' attribute on the form.
  // 2. Write an event handler for 'ajaxSuccess' or 'ajaxError' events on this form.
  //
  // Option 2 (the Kamishibai intelligence way)
  // 1. Set 'data-remote' and 'data-ks-insert-response' attributes in the form.
  // 2. There is no step 2.

  // Insert response into Ajax if 'data-ks-insert-response' attribute is set.
  kss.addEventListener(document, 'cachedAjaxSuccess', function(event){
    var data = event.data;
    var target = event.target;
    // var target = event.target && kss.closestByTagName(event.target, 'form', true);
    if (target && 
        target.hasAttribute('data-ks-insert-response') && data) {
      console.log('Insert response because data-ks-insert-response was set');
      KSController.insertAjaxIntoDom(data, 'success', event.xhr, event.ajaxOptions.url)
    }
  });

  // TODO: We have to revisit error handling.
  kss.addEventListener(document, 'ajaxError', function(event){
    var data = event.data;
    var target = event.target && kss.closestByTagName(event.target, 'a', true);
    if (event.status === 300 || event.status === 303 || event.status === 302) {
      // jQuery raises an error on redirects so we nullify the effects here.
      return; 
    } else {
      KSApp.notify('Failed to receive response from server. Error: ' + (event.errorMessage));      
    }

    event.preventDefault();
    event.stopPropagation();
  });
})
