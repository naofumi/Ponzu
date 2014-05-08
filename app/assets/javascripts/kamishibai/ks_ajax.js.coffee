# Basic Ajax management modeled after the jQuery API.
#
# Features;
# 1. Timeout management.
# 2. Evaluate Javascript contained in custom 'X-JS' header.
# 3. Evaluate Javascript if content-type is "javascript" (same as jQuery).
# 4. 'Accept' header is optimized for Kamishibai.
#
# Timeout management is tricky, and has a lot of room for improvement.
# We currently do the following (in #setTimeoutCallback);
# 1. We kill all currently running Ajax requests. #abortAndTimeoutAllAjax
#
# In actual use though, the handling of slow HTTP requests should actually 
# be quite different.
#
# 1. If fallback content is available, then timeout should be very quick.
# 2. If fallback content is not available, then timeout should be quite slow.
# 3. However, when the user makes an action that results in an Ajax request,
#    then, previous Ajax requests should be aborted immediately to make way for the new
#    requests. User actions could be detected by hashChange events or rails_ujs.
#    The largest issue I have with slow responses is that the browser doesn't 
#    respond to hashChange, etc. if there are many Ajax requests in the queue.
KSAjaxConstructor = ->
  allAjaxRequests = {}
  defaultTimeout = 5000

  ajax = (options) ->
    startSpinner()

    url = options.url
    # jQuery uses the options.type to specify the method, but we prefer options.method.
    method = (options.method || options.type || "post").toUpperCase()
    data = options.data || null; # Only accepts URI encoded string, not objects.

    async = options.async || true
    options.timeoutInterval = timeoutInterval = options.timeoutInterval || defaultTimeout
    # callbackContext = options.callbackContext || document.body; # The object on which the callbacks will be targeted

    xhr = new XMLHttpRequest()

    xhr.open(method, url, true)
    xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8')
    xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest')
    xhr.setRequestHeader('Accept', 'text/html, application/json;q=0.9, text/javascript;q=0.8')

    # timeoutInterval == 0 for no timeoutInterval
    if async && timeoutInterval > 0
      setTimeoutCallback(xhr, options, timeoutInterval)
    
    readyStateCallback = (event) ->
      ajaxReadyStateChangeHandler(event, options, timeoutInterval)
      true

    xhr.addEventListener('readystatechange', readyStateCallback, false)
    xhr.send(data)
    allAjaxRequests[url] = xhr

  # The object on which the callbacks will be targeted
  callbackContext = (ajaxOptions) ->
    ajaxOptions.callbackContext || document.body

  # Set stuff related to the timeout in the xhr object.
  #
  # Then set the timeout timer.
  setTimeoutCallback = (xhr, ajaxOptions, timeoutInterval) ->
    console.log('set timeout interval to ' + timeoutInterval + 'ms for ' + ajaxOptions.url)
    xhr.abortAndTimeoutAllAjax = ->
      console.log("Timed out: Ajax request to " + ajaxOptions.url)
      abortAndTimeoutXhr(xhr, ajaxOptions)
      # timeout all other XHR requests
      for url of allAjaxRequests
        if allAjaxRequests[url] && allAjaxRequests[url].abortAndTimeoutAllAjax
          allAjaxRequests[url].abortAndTimeoutAllAjax()

    xhr.timeoutTimer = setTimeout(xhr.abortAndTimeoutAllAjax, timeoutInterval);


  abortAndTimeoutXhr = (xhr, ajaxOptions) ->
    stopSpinner()
    xhr.timedOut = true # Used in error handler because we want to ignore
                        # regular error handling if it was a timeout
    xhr.abort()
    clearTimeout(xhr.timeoutTimer)
    # Run the ajaxOptions.timeout callback
    if typeof(ajaxOptions.timeout) is 'function'
      ajaxOptions.timeout(xhr, ajaxOption)
    kss.sendEvent 'ajaxTimeout', callbackContext(ajaxOptions), 
      xhr: xhr,
      ajaxOptions: ajaxOptions,
      error: "response timeout" + ajaxOptions.timeoutInterval + "ms"       
    delete allAjaxRequests[ajaxOptions.url];
    KSNetworkStatus.timedOut()

  ajaxReadyStateChangeHandler = (event, ajaxOptions, timeoutInterval) ->
    xhr = event.target
    return unless xhr
    textStatus = xhr.statusText
    sendEventFlag = true
    if xhr.readyState is 4
      clearTimeout(xhr.timeoutTimer)
      delete allAjaxRequests[ajaxOptions.url]
      KSNetworkStatus.succeeded()
      stopSpinner()
      # jQuery processes javascript responses in the "text script" converter.
      # Each converter is run in #ajaxConvert, which is one of the first things
      # that jQuery does after receiving a response. The result is used to 
      # feed the callbacks. We will do similar stuff here but we set data to null if Javascript.
      processJsHeader(xhr) # javascript in custom 'X-JS' header.
      data = processResponse(xhr)
      status = getAjaxStatus(xhr)
      if status is "success"
        if typeof(ajaxOptions.success) is 'function'
          ajaxOptions.success(data, "success", xhr)
        kss.sendEvent 'ajaxSuccess', callbackContext(ajaxOptions), 
          xhr: xhr, 
          data: data, 
          ajaxOptions: ajaxOptions

      else if status is "redirect"
        # Don't do anything special on redirect
      else
        # Error
        # TODO: We have error handling in KSCache, KSAjax and
        # in ks_event_listeners.js. We need to clean this up.
        if !xhr.timeOut # This is set for aborted XHR requests due to timeout.
                        # We don't need to handle errors for these.
          if typeof(ajaxOptions.error) is 'function'
            ajaxOptions.error(xhr, status, textStatus)
          kss.sendEvent 'ajaxError', callbackContext(ajaxOptions),
            xhr: xhr, 
            ajaxOptions: ajaxOptions, 
            errorMessage: status
      
      if typeof(ajaxOptions.complete) is 'function'
        ajaxOptions.complete(xhr, status)
      kss.sendEvent 'ajaxComplete', callbackContext(ajaxOptions),
        xhr: xhr, 
        ajaxOptions: ajaxOptions
      timerStatus = false;
    
    return true;
  
  getAjaxStatus = (xhr)->
    # Manage local file responses with indexOf('http')
    # TODO: We might have to hand 300, 304 responses (not changed)
    if xhr.status is 200 || window.location.href.indexOf("http") is -1
      return "success"
    else if xhr.status is 303 || xhr.status is 302
      return "redirect"
    else if xhr.status is 404
      return "404 file not found at url"
    else if xhr.status is 0
      return if xhr.timedOut then "timeout" else "status 0 error"
    else
      return "xhr status " + xhr.status

  # Process the Kamishibai customer 'X-JS' header
  processJsHeader = (xhr)->
    jsHeader = xhr.getResponseHeader('X-JS')
    if jsHeader
      jsWrapper = ()-> eval(jsHeader)
      new jsWrapper()
    return null;

  processResponse = (xhr)->
    responseType = xhr.getResponseHeader('Content-Type')
    if responseType
      if responseType.indexOf('javascript') isnt -1
        jsWrapper = ()-> eval(xhr.responseText)
        new jsWrapper()
        return null;
      else
        return xhr.responseText;

  startSpinner = ->
    logos = document.querySelectorAll('#logo')
    for logo in logos
      kss.addClass(logo, 'css_pulse')

  stopSpinner = ->
    logos = document.querySelectorAll('#logo')
    for logo in logos
      kss.removeClass(logo, 'css_pulse')

  #public interface
  this.ajax = ajax
  this.allAjaxRequests = allAjaxRequests

  return this


window.KSAjax = new KSAjaxConstructor()