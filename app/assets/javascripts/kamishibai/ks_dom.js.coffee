# Provides high-level DOM manipulation methods.
#
# #convertAjaxDataToElements generates DOM elements from an Ajax response.
# The response may be HTML or it may be JSON, in which case we use a handler
# (template) to convert it to HTML.
#
# #insertPagesIntoDom will replace elements with same IDs,
# look inside containers, and merge the current DOM with the HTML data.
# It takes a list of DOM elements as the argument, which will usually
# come from #convertAjaxDataToElements.
#
# #missingContainers will return the URLs of missing containers so that
# the controller can load them. Without the missing containers loaded,
# we won't be able to do #insertPagesIntoDom.
# It takes a list of DOM elements as the argument.
#
# KSDom enables us to modify the DOM without Javascript.
# The common way to handle Ajax is to write Javascript that will insert/replace
# the response body into a DOM element. Although this can be hugely simplified
# with jQuery, Prototype and Rails helpers, the fact remains that we have to write 
# customized Javascript.
#
# I find the current situation a bit funny. Rails UJS allows you to send
# Ajax requests without a single line of Javascript, but requires you to 
# write Javascript event handlers (or Javascript in the response) to process
# the responses. Ideally, we would like to make response processing possible
# without any Javascript.
#
# The Kamishibai approach is to extend the Rails_ujs.js approach to the Ajax
# response. Instead of requiring the developer to write custom Javascript, we use
# 'data-' attributes inside the Ajax response to tell Kamishibai how to handle it.
#
# This is what the KSDom object does.
window.KSDomConstructor = () ->


  # Insert the kamishibai elements from an Ajax response into the DOM.
  # If an element is already in the DOM (identified by matching IDs),
  # then replace instead of insert.
  # If an element has a 'data-container' element, then insert the element
  # into the corresponding container element (ignore if container is not 
  # present). Otherwise, append the element to the <body>.
  #
  # Since we also use this method to handle non-GET requests, for example 
  # in response to an Ajax POST, PUT to modify like status, setting the
  # resourceUrl (without parameters) does not always make sense. In these situations, resourceUrl
  # should be set to null.
  insertPagesIntoDom = (pages, resourceUrl, callback) ->
    referencesToPages = []
    for page in pages
      page.setAttribute('data-ks_loaded', "");
      resourceUrl = page.getAttribute('data-ajax') || resourceUrl
      insertedPage = insertPageIntoDom(page)
      if insertedPage
        insertedPage.setAttribute('data-ajax', resourceUrl) if resourceUrl
        referencesToPages.push(insertedPage)

    callback(referencesToPages)

  convertAjaxDataToElements = (data, callback) ->
    convertJSONToHTMLWithTemplate data, (data) ->
      responseContainer = document.createElement('div')
      responseContainer.innerHTML = extractBodyTag(data)
      KSAjaxResponseValidator.validate responseContainer
      # We're creating a clone of the responseContainer.children
      # HTMLCollection because we will be manipulating it.
      # Since HTMLCollection does not have a #slice method,
      # we apply Array#slice to it.
      # http://unscriptable.com/2009/03/19/hi-performance-javascript-tips-1/
      # http://www.xenoveritas.org/blog/xeno/the-correct-way-to-clone-javascript-arrays
      elementsAsArray = [].slice.call(responseContainer.children, 0)
      callback(elementsAsArray)

  extractBodyTag = (data) ->
    if (!data.match) then debugger;
    if bodyTagMatch = data.match(/<body[^>]*>([\s\S]*)<\/body>/i)
      return bodyTagMatch[1]
    else
      return data

  # Use client-side templating to generate HTML from JSON.
  convertJSONToHTMLWithTemplate = (data, callback) ->
    # The following is client-side templating code.
    # We run it asyncronously in case it's slow.
    # But we should really consider webworkers.
    # However, even Android Jelly Bean doesn't support it.
    setTimeout () ->
      # When the response has no body (render :nothing),
      # we don't even try to parse JSON.
      unless data.trim().length is 0
        try
          # We can't tell if its JSON or a string, so we try to parse anyway.
          # TODO: We should look at the response code
          json = if typeof data is "object"
            data
          else
            JSON.parse(data)
          console.log("Convert JSON respose to HTML with template " + json.renderer.template)
          data = JST[json.renderer.template](json)
        catch e
          # If we can't parse, it's probably because it isn't an object
          # We don't think about it too much.
          console.log("Error parsing JSON. Probably HTML response")
          console.log(data)
          console.log(e)
      else
        console.log("No data in response.")
      callback(data)
    , 0

  missingContainers = (pages, callback) ->
    result = []
    for page in pages
      containerId = page.getAttribute('data-container')
      containerResourceUrl = page.getAttribute('data-container-ajax')
      if (containerId && 
          !document.getElementById(containerId) &&
          containerResourceUrl)
        result.push(containerResourceUrl)
    callback(kss.uniquify(result))

  executeScript = (javascriptCode) ->
    # based on Turbolinks executeScriptTags code
    scriptTag = document.createElement('script');
    scriptTag.appendChild(document.createTextNode(javascriptCode));
    document.getElementsByTagName('head')[0].appendChild(scriptTag);

  modifyClass = (domElement, dslElement) ->
    return unless domElement
    if dslElement.hasAttribute('data-remove')
      domElement.parentNode.removeChild(domElement)
    if classNames = dslElement.getAttribute('data-add-class')
      # TODO: We should move this code to KSSupport
      # as kss.addClasses, kss.removeClasses, kss.toggleClasses
      for className in classNames.split(' ')
        kss.addClass(domElement, className) if className.length > 0
    if classNames = dslElement.getAttribute('data-remove-class')
      for className in classNames.split(' ')
        kss.removeClass(domElement, className) if className.length > 0
    if classNames = dslElement.getAttribute('data-toggle-class')
      for className in classNames.split(' ')
        kss.toggleClass(domElement, className) if className.length > 0

  replaceInnerHtml = (domElement, dslElement) ->
    # Any attributes set on the page will be preserved and not
    # replaced with the Ajax response contents.
    console.log('replacing DOM element id ' + domElement.id + ' with ajax data')   
    domElement.innerHTML = dslElement.innerHTML
    return domElement

  appendIntoContainers = (dslElement) ->
    insertedPage = null 
    containerId = dslElement.getAttribute('data-container')
    containers = document.querySelectorAll("#" + containerId)
    console.log('data-container attribute was set, but the container didn\'t exist.') unless containers
    for container in containers
      # TODO: Add new attributes to control
      #       visibility and whether to append or prepend.
      console.log('appending DSL element id ' + dslElement.id + ' into container ' + containerId)
      kss.hide(dslElement) # Hide now. Only show after transition
      insertedPage = container.appendChild(dslElement) # Return the last one
    return insertedPage

  appendIntoBody = (dslElement) ->
    insertedPage = null
    console.log('appending DSL element id ' + dslElement.id + ' into top-level of body')
    kss.hide(dslElement) # Hide now. Only show after transition
    insertedPage = document.body.appendChild(dslElement)
    kss.addClass(insertedPage, 'page')
    return insertedPage


  # Insert the page into the DOM and return a reference to the
  # element in the DOM (not the element in the Ajax response)
  #
  # TODO: We currently only execute Javascript if it is a top
  # level element. This is not expected behaviour. The expected
  # behaviour is to run any Javascript in the page.
  insertPageIntoDom = (page) ->
    insertedPage = null

    if !page.id
      if page.tagName is "SCRIPT"
        KSDom.executeScript(page.innerHTML)
      else
        console.log('ignoring for insert because id was not set in following element')
        console.log(page)
      return false # No inserted page (DOM)

    stalePages = document.querySelectorAll("#" + page.id)
    shouldUpdateHtml = !page.hasAttribute('data-attributes-only')

    if stalePages.length > 0
      for stalePage in stalePages
        modifyClass(stalePage, page)
        insertedPage = KSDom.replaceInnerHtml(stalePage, page) if shouldUpdateHtml # Return the last one
    else
      if page.getAttribute('data-container') and shouldUpdateHtml
        insertedPage = appendIntoContainers(page)
      else
        insertedPage = appendIntoBody(page)

    if insertedPage
      scripts = insertedPage.getElementsByTagName('script')
      for script in scripts
        KSDom.executeScript(script.innerHTML)

    return insertedPage

  # public interface

  this.insertPagesIntoDom = insertPagesIntoDom
  this.missingContainers = missingContainers
  this.convertAjaxDataToElements = convertAjaxDataToElements
  this.extractBodyTag = extractBodyTag
  this.executeScript = executeScript # Make overwritable for IE8 patch
  this.replaceInnerHtml = replaceInnerHtml # Make overwritable for IE8 patch

  return this

window.KSDom = new KSDomConstructor()

