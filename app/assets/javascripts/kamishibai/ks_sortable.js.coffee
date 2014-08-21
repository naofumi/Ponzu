# Initialize in Kamishibai.initialize()
# Inspiration from https://github.com/farhadi/html5sortable
#
# Concept:
#   Make it possible to use drag & drop to send Ajax requests by setting attributes on the DOM.
#   No additional Javascript should be necessary.
#
# Notes:
#   Although I haven't tested, this should work even when there are many sortable lists or
#   dropboxes in a single DOM. This is because the KSSortable object is reconfigured each time
#   a drag starts based on the characteristics of the element being dragged.
#
# Drag & Drop: How to
#
# 1. Create a draggable element. Some elements (like lists or images) may
#    be draggable by default. Otherwise, set "draggable='true'" as an attribute.
# 2. Create a droppable element that will send an Ajax event on drop. 
#    Add an attribute of "ajax-on-drop" to make it send out an Ajax request.
# 3. On the droppable element, set the "data-action" attribute to the URL you want to send the Ajax call to.
#    Optionally, specify the method in "data-method" (defaults to POST).
# 4. The Ajax will send the whole contents of the event.dataTransfer in the Ajax request data.
# 5. The Ajax will be sent using KSCache.cachedAjax from the droppable element.
# 6. You can trigger a DOM replacement using the "ks-insert-response" attribute on the droppable element.
# 7. If the draggable element is moved dropped outside of the screen, then the window
#    will reload after 1.0 seconds. This is convinient when you are moving an element to another Kamishibai
#    screen and the current screen contents will change.
#
# TODO: We should add an attribute so that some behaviors (like reloading) are configurable.
#
# Sortable: How to
#
# 1. Create a wrapper surrounding all sortable elements. This must have class="sortable". 
#    This can be ol, ul or a div or anything.
# 2. The drag-sortable elements should be direct children of the "sortable" wrapper.
# 3. The drag-sortable elements must have "draggable='true'" as an attribute.
# 4. Specify the URL to sent the ajax call to with data-action="/url/for/action" in the sortable wrapper.
#    Also add "data-method" if you wish to specify the method (default POST).
# 5. The ID of the sortable wrapper will be used as the parameter name in the ajax data.
KSSortableConstructor = () ->
  elementBeingDragged = null
  sortableElement = null
  placeholder = null
  initialIndex = null

  closestDraggable = (element) ->
    kss.closest element, (e) ->
      e.getAttribute && e.getAttribute('draggable') is "true"
    , true

  # Create a placeholder DOM object.
  #
  # Whenever an element is dragged over another
  # draggable target, then the placeholder will 
  # be inserted before the target and generate
  # enough space to accomodate the initial element.
  placeholderFactory = (elementBeingDragged) ->
    tagName = elementBeingDragged.parentNode.tagName.toUpperCase()
    placeholder = if tagName is "OL" || tagName is "UL"
      document.createElement('li')
    else
      document.createElement('div')
    placeholder.className = "sortable-placeholder"
    placeholder.style.height = elementBeingDragged.clientHeight + "px"
    placeholder.style.width = elementBeingDragged.clientWidth + "px"
    return placeholder

  indexOfNodeInParent = (node, parentNode) ->
    [].slice.call(parentNode.children, 0).indexOf(node)

  insertPlaceholder = (draggable) ->
    if !placeholder.parentNode || 
       (indexOfNodeInParent(draggable, draggable.parentNode) > 
        indexOfNodeInParent(placeholder, placeholder.parentNode))
      # Same as insertAfter
      draggable.parentNode.insertBefore(placeholder, draggable.nextSibling)
    else
      draggable.parentNode.insertBefore(placeholder, draggable)

  initialize = () ->

    ########## Behaviors for sortable drag & drop ####################

    # When a drag is started, we set the instance variables to the appropriate
    # values. We also set the "text/html" payload of `event.dataTransfer`.
    #
    # If this drag-drop is intended as a sort (has sortableElement), 
    # then we prepare for that as well.

    kss.addEventListener document, 'dragstart', (event) ->
      if (target = event.target) && sortableWrapper(target)
        elementBeingDragged = target
        sortableElement = sortableWrapper(target)
        placeholder = placeholderFactory(target)
        initialIndex = indexOfNodeInParent(target, sortableElement)
        kss.addClass target, 'sortable-dragging'
        event.dataTransfer.effectAllowed = 'move'
        event.dataTransfer.setData('text/html', target.innerHTML)

    kss.addEventListener document, 'drag', (event) ->
      if (target = event.target) && sortableWrapper(target)
        kss.hide elementBeingDragged

    # The default behaviour when the draggable element is a URL is
    # to change window.location to that page. We suppress this here
    # to allow drag & drop.
    kss.addEventListener document, 'dragover', (event) ->
      if (target = event.target) && (sortableWrapper(target) || target.hasAttribute('data-ks-ajax-on-drop'))
        if event.preventDefault
          event.preventDefault() # Allow drop
        return false
    
    # When the current elementBeingDragged enters another 
    # dragable element, we add a 'sortable-dragover' class to that
    # element and add a placeHolder.
    kss.addEventListener document, 'dragenter', (event) ->
      if sortableElement && (target = event.target) && elementBeingDragged && (draggable = closestDraggable(target))
        event.dataTransfer.dropEffect = 'move'
        kss.addClass draggable, 'sortable-dragover'
        insertPlaceholder(draggable)
    
    kss.addEventListener document, 'dragleave', (event) ->
      if sortableElement && (target = event.target) && (draggable = closestDraggable(target))
        kss.removeClass event.target, 'sortable-dragover'

    kss.addEventListener document, 'dragend', (event) ->
      cleanup()
    
    kss.addEventListener document, 'drop', (event) ->
      if (target = event.target) && (kss.hasClass(target, 'sortable-placeholder'))
        # If it is dropped onto a placeholder element generated by `placeholderFactory`.
        if event.stopPropagation
          event.stopPropagation() # prevent redirect
        target.parentNode.insertBefore(elementBeingDragged, target)
        if indexOfNodeInParent(elementBeingDragged, sortableElement) isnt initialIndex
          kss.sendEvent('sortableupdate', sortableElement)
          cleanup()
          target.innerHTML = event.dataTransfer.getData('text/html')
        return false

    # Send the ajax for sorting. Uses attributes on the sortableElement
    # which is the ancestor element with a 'sortable' class.
    kss.addEventListener document, 'sortableupdate', (event) ->
      target = event.target
      sortables = target.querySelectorAll('[draggable]')
      sortable_ids = (idToNumbers sortable.id for sortable in sortables)
      KSCache.cachedAjax 
        method: sortableElement.getAttribute('data-method') || 'post'
        url: sortableElement.getAttribute('data-action')
        callbackContext: sortableElement
        data: ("#{sortableElement.id}[]=#{sortable_id}" for sortable_id in sortable_ids).join('&')

    ########## Ajax drag & drop ####################

    kss.addEventListener document, 'dragstart', (event) ->
      if (target = event.target)
        elementBeingDragged = target
        event.dataTransfer.effectAllowed = 'move'
        # We simply send outerHTML so that we don't have to configure the drag elements
        # We let the server process the contents to decide what to do.
        #
        # This will be called for all drag events, even non-Kamishibai stuff.
        event.dataTransfer.setData('text/html', target.outerHTML)

    # Ajax on Drop stuff
    #
    # When something is dropped onto a dropbox, the the `dropbox()` function
    # will be called which sends all stuff in dataTransfer as parameters to the server.
    # The URL is set with `data-action` and the method is set with `data-method`
    kss.addEventListener document, 'drop', (event) ->
      if (target = event.target) && target.hasAttribute('data-ks-ajax-on-drop')
        event.stopPropagation()
        event.preventDefault()
        dropbox(event)
        kss.removeClass target, "drag-selected"
        return false

    kss.addEventListener document, 'dragenter', (event) ->
      if (target = event.target) && target.hasAttribute('data-ks-ajax-on-drop')
        kss.addClass target, "drag-selected"

    kss.addEventListener document, 'dragleave', (event) ->
      if (target = event.target) && target.hasAttribute('data-ks-ajax-on-drop')
        kss.removeClass target, "drag-selected"

    kss.addEventListener document, 'dragend', (event) ->
      if event.clientX < 0 || event.clientX > window.innerWidth || event.clientY < 0 || event.clientY > window.innerHeight
        setTimeout ->
          # Give the server time to process the response and then reload.
          kss.redirect(location.hash)
        , 1000



  # returns the numeric value at the end of the string
  idToNumbers = (str) ->
    numberAsString = str.replace(/(.*?)([0-9]*)$/, "$2")
    parseInt(numberAsString, 10)

  cleanup = () ->
    placeholder.parentNode.removeChild(placeholder) if placeholder && placeholder.parentNode
    if elementBeingDragged
      kss.show elementBeingDragged
      kss.removeClass elementBeingDragged, 'sortable-dragging'
      for node in elementBeingDragged.parentNode.childNodes
        kss.removeClass node, 'sortable-dragover'
    sortableElement = null
    elementBeingDragged = null
    placeholder = null
    initialIndex = null

  sortableWrapper = (element) ->
    return kss.closestByClass(element, 'sortable', false)


  # We can't use bubbling for the dropbox because we can't stop propagation
  # early enough to prevent default behaviour.
  dropbox = (event) ->
    target = event.target
    action = target.getAttribute('data-action')
    method = target.getAttribute('data-method') || 'post'
    params = []
    if event.dataTransfer.types
      params = params.concat ("data_transfer[#{type}]=#{encodeURIComponent(event.dataTransfer.getData(type))}" for type in event.dataTransfer.types)

    KSCache.cachedAjax
      method: method
      url: action
      callbackContext: target
      data: params.join('&')

  this.initialize = initialize
  return this

window.KSSortable = new KSSortableConstructor()
