# == KSCache concept
#
# KSCache wraps ks_ajax with a cache management layer. This is
# similar to how fragment caching works in Ruby-on-Rails.
# 
# By using KSCache.cachedAjax instead of KSAjax.ajax, you transparently
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
#
# Redesign of Kashibai Cache behaviour.
#
# 1. If there is nothing in the cache, then we fire an Ajax request.
#    a. If we get a response, then all is good.
#    b. If we don't get a response, we show an error page.
# 2. If we have data in the cache (regardless of expiry status), we
#    return the cached data immediately.
#    If it is expired data, then we fire an Ajax request but we make
#    sure that the response will not trigger a page transition but will
#    simply replace any elements that are already in the DOM.
#    a. If we get a response, then all is good.
#    b. If we timeout, then the online status is set to "unstable".
# 3. If we have valid data in the cache, we never fire an Ajax request,
#    but use the cached data immediately.
# 4. The success and complete handlers will be called when data is
#    available in the cache, and after a network response returns fresh data.
#    The `cachedAjaxSuccess` and `cachedAjaxComplete` methods do the same.
#    If a network request to update the cached value has been sent, the
#    callback for that request will have `secondRequestToUpdateCache` set to true
#    on the xhr object. You can modify behaviour based on this value.
# 5. The `ajaxSuccess` and `ajaxComplete` methods are only called after
#    a network response.
#
# Because of this design, callbacks to insert content into the DOM should
# use the `cachedAjaxSuccess` callback or the success handler. `ajaxSuccess`
# callbacks are used less frequently.
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
  #
  # If the response has come out of the cache, then xhr.fromCache will
  # be set to true in the callback.
  cachedAjax = (options) ->
    # Wrap success callback so that we additionally send
    # a 'cachedAjaxSuccess' on success.
    options.success = addCachedAjaxSuccessEventToCallback(options, options.success)
    options.complete = addCachedAjaxCompleteEventToCallback(options, options.complete)
    if !options.method || options.method.toUpperCase() isnt 'GET'
      # Non 'GET' methods will not be cached
      # We should actually put this outside of the callback.
      KSAjax.ajax(options)
    else
      url = options.url = normalizedUrl(options.url)
      delete options.forceReload # forceReload is Deprecated. Make sure we remove it.

      pageCache().getRaw url, (cachedValue, cacheHasExpired)->

        resetTimeoutIntervalIfCacheInvalid(options, cachedValue, cacheHasExpired)

        if cachedValue is null #|| (cacheHasExpired && !KSNetworkStatus.unstable())
          # Attempt Ajax if network is stable and the cache has expired.
          # if cachedValue is null
          console.log 'cache miss for ' + url
          # else if cacheHasExpired
            # console.log('cache expired for ' + url)

          # wrap the callbacks for Ajax Success to additionally
          # store the results in cache.
          # Set xhr.secondRequestToUpdateCache to false so
          # that callbacks will treat the response as the first
          # request (will transition to it)
          options.success = storeInCacheAndRunCallback(options, options.success, {secondRequestToUpdateCache: false})

          console.log('send ajax for ' + url);
          KSAjax.ajax(options);
        else
          # Call callback with cached values
          pseudoXhr = {responseText: cachedValue, fromCache: true}
          if options.success
            options.success(cachedValue, 'success', pseudoXhr)
          if options.complete
            options.complete(pseudoXhr, 'success')

          if cacheHasExpired
            console.log('cache expired for ' + url)

            # The second ajax request should only update DOM elements,
            # and should not trigger a page transition.
            # This wrapper stores the results into the cache.
            # Also sets xhr.secondRequestToUpdateCache to true so
            # that callbacks will treat the response as the second
            # request (will update but not transition)
            options.success = storeInCacheAndRunCallback(options, options.success, {secondRequestToUpdateCache: true, cachedValue:cachedValue})
            # timeouts should do nothing for the second request
            options.timeout = () ->
              return
            # errors should do nothing for the second request
            options.error = () ->
              return

            console.log('send ajax to update cache for ' + url + '(we will display cached contents before receiving response)');
            KSAjax.ajax(options);          
          else
            console.log('cache hit for ' + url)
            KSApp.debug('cache hit for ' + url)
  
  resetTimeoutIntervalIfCacheInvalid = (options, cachedValue, cacheHasExpired) ->
    if options.timeoutIntervalIfExpiredCacheFound
      if cachedValue && cacheHasExpired
        options.timeoutInterval = options.timeoutIntervalIfExpiredCacheFound
      delete options.timeoutIntervalIfExpiredCacheFound
    options

  # TODO: Combine addCachedAjaxSuccessEventToCallback and addCachedAjaxCompleteEventToCallback
  addCachedAjaxSuccessEventToCallback = (options, originalCallback) ->
    (data, textStatus, xhr) ->
      callbackContext = options.callbackContext || document.body
      kss.sendEvent('cachedAjaxSuccess', callbackContext,
                    {data: data, ajaxOptions: options, xhr: xhr})
      if typeof(originalCallback) is 'function'
        originalCallback(data, textStatus, xhr)

  addCachedAjaxCompleteEventToCallback = (options, originalCallback) ->
    (xhr, textStatus) ->
      callbackContext = options.callbackContext || document.body
      kss.sendEvent('cachedAjaxComplete', callbackContext,
                    {ajaxOptions: options, xhr: xhr})
      if typeof(originalCallback) is 'function'
        originalCallback(xhr, textStatus)

  storeInCacheAndRunCallback = (options, originalCallback, callbackModifier) ->
    (data, textStatus, xhr) ->
      cacheExpiry = options.expires || getExpiryDate(data) || defaultCacheExpiry
      if cacheExpiry
        pageCache().set(options.url, data, cacheExpiry)
        console.log('store key: ' + options.url + ' into cache with expiry: ' + cacheExpiry + ' seconds');
      else
        console.log('will not store: ' + options.url + ' into cache because no expiry set')
      if data is callbackModifier.cachedValue
        xhr.noChange = true  
      xhr.secondRequestToUpdateCache = callbackModifier.secondRequestToUpdateCache || false
      if typeof(originalCallback) is 'function'
        originalCallback(data, textStatus, xhr)

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
    # We need to get the expiry before we have a chance to 
    # parse JSON. Therefore, we use regular expressions to get
    # the expiry info. This should work with both HTML responses
    # and JSON responses.
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