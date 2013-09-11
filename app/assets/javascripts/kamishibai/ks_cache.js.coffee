# == KSCache concept
#
# KSCache wraps ks_ajax with a cache management layer. This is
# similar to how fragment caching works in Ruby-on-Rails.
# 
# By using KSCache.ajax instead of KSAjax.ajax, you transparently
# get the benefits of a caching.
#
# One difference to note is that KSCache will return 
# a "cachedAjaxSuccess" event when
# a value has successfully been recovered, either from the network
# or from the cache.
#
# Note that a successful Ajax response will fire the
# "ajaxSuccess" event.
#
# == How Kamishibai Cache is designed.
#
# Kamishibai Cache should behave as follows;
#
# 1. If there is nothing in the cache, then we fire an Ajax request.
#    a. If we get a response, then all is good.
#    b. If we don't get a response, we show an error page.
# 2. If we have expired data in the cache, then we fire an Ajax request,
#    but the timeout interval is shorter (we are more impatient)
#    a. If we get a response, then all is good.
#    b. If we timeout, then we show the cached data and set up a
#       warning in the status bar. The online status is set to "unstable".
# 3. If we have valid data in the cache, we never fire an Ajax request,
#    but use the cached data immediately.
#
# Also, if we timeout from any Ajax request, we immediately send a timeout
# to all other current Ajax requests and prevent ajax sending of future request.
# The idea is to fallback to cache.
KSCacheConstructor = ->
  # Defaults
  networkTestInterval = 120 # seconds : Deprecated?
  defaultCacheExpiry = 0 # seconds : 0 means that we won't cache
  defaultTimeoutForBatchAjax = 30000 # ms. 

  # Returns the object that we should
  # use for caching.
  # Either lscache or KSSqlCache, based on whether a WebSQL cache is ready
  # or not.
  pageCache = ->
    if KSSqlCache.supported()
      KSSqlCache.setBucket(KSApp.user_id() + "-" + KSCookie.get('device') + "-"  + KSCookie.get('locale') + "-")
      return KSSqlCache
    else
      lscache.setBucket(KSApp.user_id() + "-" + KSCookie.get('device') + "-"  + KSCookie.get('locale') + "-")
      return lscache

  # Entry point for a cached Ajax request.
  # The arguments are similar to a regular Ajax request (KSAjax.ajax())
  # with additional options for managing the cache.
  #
  # options (in addition to KSAjax.ajax() options):
  #
  # timeoutIfHasExpiredCached:
  #   If we find a cached value that has expired, set the timeoutInterval
  #   to this value (which is normally shorter). This is because we have
  #   can display the cached value, so we don't have to wait so long.
  cachedAjax = (options) ->
    # Wrap success callback so that we additionally send
    # a 'cachedAjaxSuccess' on success.
    options.success = successCallbackWithCachedAjaxSuccessEvent(options, options.success)

    if !options.method || options.method.toUpperCase() isnt 'GET'
      # Non 'GET' methods will not be cached
      # We should actually put this outside of the callback.
      KSAjax.ajax(options)
    else
      url = options.url = normalizedUrl(options.url)
      delete options.forceReload # forceReload is Deprecated. Make sure we remove it.

      pageCache().get url, (cachedValue, cacheHasExpired)->

        resetTimeoutIntervalIfCacheInvalid(options, cachedValue, cacheHasExpired)

        if cachedValue is null || (cacheHasExpired && !KSNetworkStatus.unstable())
          # Attempt Ajax if network is stable and the cache has expired.
          if cachedValue is null
            console.log 'cache miss for ' + url
          else if cacheHasExpired
            console.log('cache expired for ' + url)

          options.success = successCallbackOnAjax(options, options.success)
          options.timeout = timeoutCallback(options, cachedValue, options.success)
          options.error = errorCallbackOnAjax(options, cachedValue, options.success)

          console.log('send ajax for ' + url);
          KSAjax.ajax(options);
        else
          console.log('cache hit for ' + url)
          KSApp.debug('cache hit for ' + url)

          if options.success
            options.success(cachedValue, 'success')
  
  resetTimeoutIntervalIfCacheInvalid = (options, cachedValue, cacheHasExpired) ->
    if options.timeoutIntervalIfExpiredCacheFound
      if cachedValue && cacheHasExpired
        options.timeoutInterval = options.timeoutIntervalIfExpiredCacheFound
      delete options.timeoutIntervalIfExpiredCacheFound
    options


  successCallbackWithCachedAjaxSuccessEvent = (options, originalCallback) ->
    (data, textStatus, xhr) ->
      kss.sendEvent('cachedAjaxSuccess', options.callbackContext,
                    {data: data, ajaxOptions: options, xhr: xhr})
      if typeof(originalCallback) is 'function'
        originalCallback(data, textStatus, xhr)

  successCallbackOnAjax = (options, originalCallback) ->
    (data, textStatus, xhr) ->
      cacheExpiry = options.expires || getExpiryDate(data) || defaultCacheExpiry
      if cacheExpiry
        pageCache().set(options.url, data, cacheExpiry)
        console.log('store key: ' + options.url + ' into cache with expiry: ' + cacheExpiry + ' seconds');
      else
        console.log('will not store: ' + options.url + ' into cache because no expiry set')
      if typeof(originalCallback) is 'function'
        originalCallback(data, textStatus, xhr)

  timeoutCallback = (options, fallbackValue, successCallback) ->
    (xhr) ->
      if fallbackValue
        # Silently fail if we have a fallback value.
        # KSNetworkStatus will send KSOnlineIndicator a request to
        # show the network status.
        successCallback(fallbackValue, 'success')
      else
        KSApp.notify('Network timed out. Cannot display URL: ' + options.url)
        console.log('Network timed out. Cannot display URL: ' + options.url)
        # We show an error page instead of showing the same current page.
        # Without this, the URL will change but the page will be the same,
        # which is confusing for the user.
        successCallback(timeoutErrorHtml, "timeout")

  timeoutErrorHtml = """
                     <div id="error_msg" data-title="Error: Network timed-out">
                       <div class="dialog" id="error_msg">
                         <h1>The network request timed-out</h1>
                         <p>
                           We could not get a response from the server in time,
                           and we do not have a cached version to show.
                           The network may be unstable or the server congested.
                         </p>
                         <p>
                           Please try again later.
                         </p>
                       </div>
                     </div>
                     """

  errorWithoutResponseText = (status) ->
    """
    <div id="error_msg" data-title="Error: #{status}">
      <div class="dialog" id="error_msg">
        <h1>Error: #{status}</h1>
        <p>
          We are sorry but we failed to get a response from the server, 
          and we do not have a cached version to show.
        </p>
        <p>
          Please try again later.
        </p>
      </div>
    </div>
    """

  errorCallbackOnAjax = (options, fallbackValue, successCallback) ->
    (xhr, textStatus) ->
      return false if xhr.timedOut # We don't need to respond to errors if the
                                   # error was caused by timeout.
      if fallbackValue
        KSApp.notify(textStatus + ' error. Display previous page.')
        console.log(textStatus + ' error. Display previous page.')
        successCallback(fallbackValue, 'success')
      else
        KSApp.notify(textStatus + ' error. Cannot display URL: ' + options.url)
        console.log(textStatus + ' error. Cannot display URL: ' + options.url)
        successCallback(errorPage(xhr, options.url, textStatus), textStatus)
      return false # Don't raise error event

  # Display error in the browser
  errorPage = (xhr, url, textStatus) ->
    bodyInner = KSDom.extractBodyTag(xhr.responseText)
    if bodyInner
      return "<div id='error_msg' data-ks_loaded class='page' data-title='" + textStatus + "'>" + 
            bodyInner + "</div>"
    else
      return errorWithoutResponseText(textStatus)

  # Due to differences in url encoding methods, " "(space) can
  # be either '+' or '%20'.
  # We normalize this to '+' so that the cache entries will have the
  # same keys. Rails also uses '+', so it should
  # match any links, etc.
  normalizedUrl = (url) ->
    if url
      return url.replace(/%20/g, '+')      
    else
      return url


  getExpiryDate = (data)->
    match = data.match(/data-expiry\s*=\s*['"]?(\d*)['"]?/) || 
            data.match(/\"expiry\"\s*:\s*(\d*)/)
    if match && match[1]
      return parseInt(match[1], 10)
    else
      return null

  #################
  # Batch loading #
  #################

  #Refactor based on http://stackoverflow.com/questions/1609637/is-it-possible-to-insert-multiple-rows-at-a-time-in-an-sqlite-database
  # and http://stackoverflow.com/questions/1711631/how-do-i-improve-the-performance-of-sqlite
  # Without optimizations, it's a bit too slow.
  # iPad2 was something like 20 rows per second.
  simpleBatchLoad = (resourceUrl) ->
    queryString = ""
    progress_bar = document.getElementById('progress_bar')
    progress_bar.textContent = "Downloading..."
    KSAjax.ajax
      url: resourceUrl,
      timeoutInterval: defaultTimeoutForBatchAjax,
      method: 'post',
      data: queryString,
      success: (data, textStatus, xhr) ->
        progress_bar.textContent = "Download Complete!"
        count = 1
        totalCount = 0
        parsedData = JSON.parse(data)
        for url of parsedData
          theData = parsedData[url]
          cacheExpiry = getExpiryDate(theData) || defaultCacheExpiry
          console.log('store ' + url + ' from batchLoad from ' + resourceUrl)
          pageCache().set url, theData, cacheExpiry, ->
            if count < totalCount
              progress_bar.textContent = "updating DB: " + count
            else
              progress_bar.textContent = "update finished: " + count
              # Update the database version number here.
            count++
          totalCount++

  ######################
  # Cache invalidation #
  ######################

  # Invalidates the keys in localStorage
  # The keys are a space delimited list of lscache keys (the resouceUrls).
  # The keys will match anywhere in the lscache key. The idea
  # is to be permissive in cache invalidation (we allow situations
  # where we invalidate more than necessary) because cache invalidation
  # is hard.
  # 
  # If we want to specifically anchor the keys to the end of a path, we can use 
  # "(?:\\&|\\?|$)" at the end of the string.
  invalidateCache = (keysString)->
    if !keysString then return
    keys = (KSUrl.toNormalizedPath(key) for key in keysString.split(' '))
    # keys = (kss.escapeForRegExp(KSUrl.toNormalizedPath(key)) for key in keysString.split(' '))

    regexpString = "(?:" + keys.join('|') + ")"
    invalidationRegex = new RegExp(regexpString)
    console.log('will invalidate with Regexp ' + invalidationRegex.toString())

    lscache.invalidateKeysByRegex(invalidationRegex)
    KSSqlCache.invalidateKeysByRegex(invalidationRegex)

  # Set up the event listeners for cache invalidation
  kamishibai.beforeInitialize ->
    # They also handle cache invalidation for links or forms with
    # 'data-invalidates-keys'
    kss.addEventListener document, 'click', (event) ->
      target = event.target && kss.closestByTagName(event.target, 'a', true)
      if target && target.hasAttribute('data-invalidates-keys')
        invalidateKeysString = target.getAttribute('data-invalidates-keys')
        KSCache.invalidateCache(invalidateKeysString)

    kss.addEventListener document, 'submit', (event) ->
      target = event.target && kss.closestByTagName(event.target, 'form', true)
      if target && target.hasAttribute('data-invalidates-keys')
        invalidateKeysString = target.getAttribute('data-invalidates-keys')
        KSCache.invalidateCache(invalidateKeysString)

  ## Public interface

  this.invalidateCache = invalidateCache
  this.cachedAjax = cachedAjax
  # this.batchLoad = batchLoad
  this.simpleBatchLoad = simpleBatchLoad
  return this

window.KSCache = new KSCacheConstructor()