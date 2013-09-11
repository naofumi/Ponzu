# Understanding the controller logic.
#
# The controller analyzed the new hash after a hash change
# and fires necessary loads and KSCompositor methods.
#
# Our concept for loading is that we will try not to use DOM cache.
# Instead, we will try to reload everything downstream per hash change. 
# We will not reload upstream stuff. That means for downstream elements,
# that the "expire" attribute is the sole determinator of cache life.
# Even DOM cached pages will still be reloaded.
#
# As a result, pageId only transitions should also fire a reload.
#
# As a result of this concept, multi-page DOMs tend to only differ
# from separate pages in that they allow us to batch load multiple pages.
# There is no *cache* advantage.
#
# URLs with pageId only;
#
# Find the pageId element on the current page and transition to it.
# Then load dependencies. If that element has a data-ajax attribute,
# then it will be reloaded, which is most of the time because all
# loaded pages will be given a data-ajax stamp.
#
# URLs with resourceUrl only;
#
# Load the resourceUrl and then transition to the page with 'data-default' or
# if not available, to the first page. Then load dependencies.
#
# URLs with both resourceUrl and pageId;
#
# Look for the pageId element on the current page. If available, then
# handle as if there was now resourceUrl in the first place.
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
  requestHistory = {} # memo for all urls requested per hashChange (to prevent redundant requests)

  handleHashChange = ->
    requestHistory = {}
    targetState = KSUrl.parseHref(location.href);
    show targetState if targetState

  show = (targetState) ->
    [resourceUrl, pageId] = resourceUrlAndPageId(targetState)

    load resourceUrl,
      (pages) ->
        toElement = if pageId
                      document.getElementById(pageId)
                    else
                      defaultPage(pages)
        KSApp.errors("ERROR: toElement could not be found") unless toElement
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
          (dompages) -> callback and callback(dompages))

  # Load from a URL and then insert into DOM.
  # If resourceUrl evaluates to false, then don't load anything
  # and just run the callback with empty array.
  # Do not recursively load downstream dependencies
  # but recursively load upstream containers.
  # The callback receives pages (the pages in the ajax response)
  load = (resourceUrl, callback) ->
    return callback && callback([]) if !resourceUrl || requestHistory[resourceUrl]

    console.log('loadResourceUrl ' + resourceUrl)
    requestHistory[resourceUrl] = true
    KSCache.cachedAjax
      method: "get"
      dataType: 'html'
      success: (data, textStatus, xhr) ->
        processAjaxSuccess(data, textStatus, xhr, resourceUrl, callback)
      error: (jqXHR, textStatus, errorThrown) ->
        KSApp.notify("Load failed: " + resourceUrl + textStatus + "<br />" + errorThrown)
        return false
      timeoutInterval: ajaxLoadTimeout
      timeoutIntervalIfExpiredCacheFound: ajaxLoadtimeoutIntervalIfExpiredCacheFound
      url: resourceUrl

  loadMissingContainers = (dslpages, callback) ->
    KSDom.missingContainers dslpages, (missingContainers) ->
      load missingContainers[0], () -> callback()

  # Recursively load dependencies
  loadDependencies = (redrawnAreas) ->
    urls = allDataAjaxUrlsIn(redrawnAreas)
    for url in urls
      load(url, (pages) -> loadDependencies(pages)) unless requestHistory[url]

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

