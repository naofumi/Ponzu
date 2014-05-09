# Understanding the controller logic.
#
# The controller analyzes the new hash after a hash change
# and fires necessary loads and KSCompositor methods.
#
# It serves as the intermediary between hashChanges, 
# Ajax requests and DOM insertions.
#
# ### hashChange for URLs with pageId only;
#
# Find the pageId element on the current page and transition to it.
# Then load dependencies. If that element has a data-ajax attribute,
# then it will be reloaded, which is most of the time because all
# loaded pages will be given a data-ajax stamp.
#
# ### hashChange for URLs with resourceUrl only;
#
# Load the resourceUrl and then transition to the page with 'data-default' or
# if not available, to the first page. Then load dependencies.
#
# ### hashChange for URLs with both resourceUrl and pageId;
#
# Look for the pageId element on the current page. If available, then
# handle as if there was no resourceUrl in the first place.
#
# If not available, then load resourceUrl and look any element with pageId.
# Transition to it and then load dependencies.
#
# All elements with 'data-ajax' are now handled in loadDependencies. Hence
# the resources are auto-loaded as soon as these elements are read in. They are 
# also reloaded when specifically targeted in case the pre-loading failed.

KSControllerConstructor = ->
  ajaxLoadTimeout = 10000 # ms
  ajaxLoadtimeoutIntervalIfExpiredCacheFound = 3000 # ms
  requestHistoryForSingleHashChangeEvent = {} # memo for all urls requested per hashChange (to prevent redundant requests)

  handleHashChange = ->
    requestHistoryForSingleHashChangeEvent = {}
    targetState = KSUrl.parseHref(location.href);
    show targetState if targetState
    
  show = (targetState) ->
    [resourceUrl, pageId] = resourceUrlAndPageId(targetState)

    loadResourceIntoDom resourceUrl, {showErrorAsPage: true, showTimeoutAsPage: true},
      showPageCallback(pageId)

  showPageCallback = (pageId) ->
    (pages, xhr) ->
      # Show the toElement
      toElement = if pageId
                    document.getElementById(pageId)
                  else
                    defaultPage(pages)
      KSApp.errors("ERROR: toElement could not be found") unless toElement

      if (xhr.secondRequestToUpdateCache)
        # This callback should not trigger 
        # a transition to the toElement if it is
        # a second load after displaying the cached version.
        setTimeout () -> 
          loadDependencies(toElement)
        ,10
      else
        # TODO: Do we really need timeout
        setTimeout () ->
          redrawnArea = reveal(toElement)
          loadDependencies(redrawnArea)
        , 10


  # Page to show if not defined by pageId
  defaultPage = (pages) ->
    for page in pages
      # If any page has 'data-default', return first occurance
      if page.hasAttribute('data-default')
        return page
    return pages[0] # show first by default

  # We calculate the top level load and pageId based
  # on targetState (from location.href) and the current
  # DOM state.
  # 
  # Concerning the relationship between pageId and resourceUrl.
  # In targetState, the resourceUrl signifies the resource
  # that is required to get pageId into the DOM. If pageId
  # is already in the DOM, resourceUrl has no relevance. This
  # is similar to how we use the "data-container" attribute.
  # (if the container is already there, don't reload)
  #
  # If the pageId has a 'data-ajax' attribute, then reload it
  # because the first trial might have failed.
  resourceUrlAndPageId = (targetState) ->    
    pageId = targetState.pageId
    resourceUrl = if page = document.getElementById(pageId) 
                    page.getAttribute('data-ajax')
                  else
                    targetState.resourceUrl
    return [resourceUrl, pageId]

  # #insertAjaxIntoDom is used to post-process an Ajax response
  # and to insert HTML (sometimes converted from JSON) into the DOM.
  #
  # If the Ajax response requires a container that isn't present,
  # then it will load that recursively (otherwise we wouldn't be
  # able to insert it into the DOM)
  insertAjaxIntoDom = (data, textStatus, xhr, resourceUrl, callback) ->
    KSDom.convertAjaxDataToElements data, (dslpages) ->
      # Ensure that the containers are available before we insert
      # the Ajax response.
      loadMissingContainers dslpages, () ->
        KSDom.insertPagesIntoDom(dslpages, resourceUrl, 
          (dompages) -> callback and callback(dompages, xhr))

  # Load from a URL and then insert into DOM.
  #
  # If resourceUrl evaluates to false, continue the callback chain with no pages.
  # Also continue the callback chain with no pages if the request has already been sent.
  #
  # Do not recursively load downstream dependencies
  # but recursively load upstream containers.
  #
  # The callback receives an array pages (the pages in the ajax response).
  #
  # Error handling behaviour is defined here (it was previously defined in KSCache).
  # By setting the showErrorAsNotification, showErrorAsPage, showTimeoutAsNotification,
  # showTimeoutAsPage options, you can specify if and how the errors will be
  # displayed on the browser. Typically, we only show errors or timeout errors
  # for hashChange targeted resources or upstream dependencies 
  # (when the page cannot be displayed). If the page can be displayed even if some
  # dependencies may be absent, we don't bug the user with notifications.
  loadResourceIntoDom = (resourceUrl, options, callback) ->
    # Return no pages if no resourceUrl
    return callback && callback([]) if !resourceUrl
    # Return no pages if request already sent in this hashChange event
    return callback && callback([]) if requestHistoryForSingleHashChangeEvent[resourceUrl]

    showErrorAsNotification = options.showErrorAsNotification
    showErrorAsPage = options.showErrorAsPage
    showTimeoutAsNotification = options.showTimeoutAsNotification
    showTimeoutAsPage = options.showTimeoutAsPage

    console.log('prepare to loadResourceUrl ' + resourceUrl + ' using cachedAjax.')
    requestHistoryForSingleHashChangeEvent[resourceUrl] = true
    KSCache.cachedAjax
      method: "get"
      dataType: 'html'
      success: (data, textStatus, xhr) ->
        if !xhr.noChange
          insertAjaxIntoDom(data, textStatus, xhr, resourceUrl, callback)
        else
          console.log("will not insert data into dom because content identical to cache:" + resourceUrl)
      error: (xhr, textStatus, errorThrown) ->
        if showErrorAsNotification
          KSApp.notify("Load failed: " + resourceUrl + textStatus + "<br />" + errorThrown)
        if showErrorAsPage
          insertAjaxIntoDom errorPage(xhr, resourceUrl, textStatus, errorThrown), 
                            textStatus, 
                            xhr, 
                            resourceUrl,
                            showPageCallback()
      timeout: (xhr, ajaxOptions) ->
        if showTimeoutAsNotification
          KSApp.notify("Load failed: " + resourceUrl + textStatus + "<br />" + errorThrown)
        if showTimeoutAsPage
          insertAjaxIntoDom timeoutErrorHtml(ajaxOptions, resourceUrl, textStatus, errorThrown),
                            textStatus,
                            xhr,
                            resourceUrl,
                            showPageCallback()
        
      timeoutInterval: ajaxLoadTimeout
      timeoutIntervalIfExpiredCacheFound: ajaxLoadtimeoutIntervalIfExpiredCacheFound
      url: resourceUrl

  errorPage = (xhr, url, textStatus, errorThrown) ->
    bodyInner = KSDom.extractBodyTag(xhr.responseText)
    if bodyInner
      # Show full error page as returned by Rails
      # ready to be shown as a full top-level Kamishibai page.
      return "<div id='error_msg' data-ks_loaded class='page' data-title='" + textStatus + "'>" + 
            bodyInner + "</div>"
    else
      return errorWithoutResponseText(textStatus, url, errorThrown)

  errorWithoutResponseText = (textStatus, url, errorThrown) ->
    """
    <div id="error_msg" class="page" data-title="Error: #{textStatus}">
      <div class="dialog">
        <h1>Error: #{textStatus}</h1>
        <p>#{errorThrown}</p>
        <p>
          We are sorry but we failed to connect to the server at "#{url}".
        </p>
        <p>The network may be unstable.
        </p>
        <p>
          Please try again later.
        </p>
      </div>
    </div>
    """
  timeoutErrorHtml = (ajaxOptions, resourceUrl, textStatus, errorThrown) ->
    """
    <div id="error_msg" class="page" data-title="Error: Network timed-out">
      <div class="dialog">
        <h1>The network request timed-out</h1>
        <p>
          We could not get a response from the server at #{resourceUrl} in #{ajaxOptions.timeoutInterval} ms.
        </p>
        <p>
          The network may be unstable or the server may be over capacity.
        </p>
        <p>
          Please try again later.
        </p>
      </div>
    </div>
    """

  # Load all missing containers for pages.
  #
  # Containers are the frames into which the dslpages will be inserted into.
  loadMissingContainers = (dslpages, callback) ->
    KSDom.missingContainers dslpages, (missingContainers) ->
      loadResourceIntoDom missingContainers[0], {showErrorAsPage: true, showTimeoutAsPage: true}, () -> callback()

  # Recursively load dependencies
  #
  # Loads all resources specified by 'data-ajax'.
  loadDependencies = (redrawnAreas) ->
    urls = allDataAjaxUrlsIn(redrawnAreas)
    for url in urls
      loadResourceIntoDom(url, {}, (pages) -> loadDependencies(pages)) unless requestHistoryForSingleHashChangeEvent[url]

  # Finds all 'data-ajax' resource URLs
  allDataAjaxUrlsIn = (elements) ->
    elements = [elements] if !(elements instanceof Array)
    result = []
    for element in elements
      nodes = element.querySelectorAll("[data-ajax]")
      for node in nodes
        url = node.getAttribute('data-ajax')
        result.push(url) if result.indexOf(url) is -1
    return result

  # TODO: investigate the 'dontHide' argument
  reveal = (toElement) ->
    return KSCompositor.showElement(toElement)

  # Public interface
  this.handleHashChange = handleHashChange
  this.insertAjaxIntoDom = insertAjaxIntoDom
  return this

window.KSController = new KSControllerConstructor()

