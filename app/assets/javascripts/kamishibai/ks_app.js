// Display status messages (flash).
// Also get's the user_id
window.KSApp = function(){
  // Messages to be shown in a message dialog (flash) are
  // sent through the 'X-Message-Type', 'X-Message'
  // custom headers.
  kamishibai.beforeInitialize(function(){
    kss.addEventListener(document, 'ajaxComplete', function(event) {
      var msg = JSON.parse(event.xhr.getResponseHeader('X-Message'));
      var type = event.xhr.getResponseHeader('X-Message-Type');
      if (type == 'notice' || type == 'message') {
        notify(msg);
      } else if (type == 'error') {
        errors(msg);
      }
    })
  });

  function notify(string) {
    var noticeElement = document.getElementsByClassName('notice')[0];
    if (!noticeElement) {return};
    if (string)
      noticeElement.innerHTML = string;
      // $('.notice').html(string);
    if (noticeElement.innerHTML) {
      // TODO: Animate
      kss.show(noticeElement, true);
      setTimeout(function(){kss.hide(noticeElement)}, 2000);
      // $('.notice').fadeIn(300, function(){
      //   window.setTimeout(function(){$('.notice').fadeOut()}, 2500);
      // });
    }
  }

  function status(string) {
    var statusElement = document.getElementsByClassName('status')[0];
    if (string)
      statusElement.innerHTML = string;
    if (statusElement.innerHTML) {
      kss.show(noticeElement, true);
    } else {
      kss.hide(noticeElement);
    }
  }

  function errors(string) {
    var errorsElement = document.getElementsByClassName('error')[0];
    if (!errorsElement) {return};
    if (string)
      errorsElement.innerHTML = string;
      // $('.notice').html(string);
    if (errorsElement.innerHTML) {
      // TODO: Animate
      kss.show(errorsElement, true);
      setTimeout(function(){kss.hide(errorsElement)}, 5000);
      // $('.notice').fadeIn(300, function(){
      //   window.setTimeout(function(){$('.notice').fadeOut()}, 2500);
      // });
    }
  }

  function debug(string) {
    
  }

  function user_id(){
    return KSCookie.get("user_id")
  }

  return {
    notify: notify,
    errors: errors,
    debug: debug,
    user_id: user_id
  }
}();

// Display Flash notice on load.
// 
onDomReady(function(){
  KSApp.notify();
})
