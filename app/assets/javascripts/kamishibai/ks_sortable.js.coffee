# Initialize in Kamishibai.initialize()
# Inspiration from https://github.com/farhadi/html5sortable
#
# How to use
#
# 1. Create a wrapper with class="sortable". This can be ol, ul or a div or anything.
# 2. The drag-sortable elements should be direct children of the "sortable" wrapper.
# 3. The drag-sortable elements must have "draggable='true'" as an attribute.
# 4. Specify where to sent the ajax call with data-action="/url/for/action" in the sortable wrapper
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

  placeholderFactory = (elementBeingDragged) ->
    tagName = elementBeingDragged.parentNode.tagName.toUpperCase()
    placeholder = if tagName is "OL" || tagName is "UL"
      document.createElement('li')
    else
      document.createElement('div')
    placeholder.className = "sortable-placeholder"
    placeholder.style.height = elementBeingDragged.clientHeight + "px"
    return placeholder

  indexOfNodeInParent = (node, parentNode) ->
    [].slice.call(parentNode.children, 0).indexOf(node)

  insertPlaceholder = (draggable) ->
    if !placeholder.parentNode || 
       (indexOfNodeInParent(draggable, draggable.parentNode) >= 
        indexOfNodeInParent(placeholder, placeholder.parentNode))
      # Same as insertAfter
      draggable.parentNode.insertBefore(placeholder, draggable.nextSibling)
    else
      draggable.parentNode.insertBefore(placeholder, draggable)

  initialize = () ->
    kss.addEventListener document, 'dragstart', (event) ->
      if (target = event.target) && target.getAttribute('draggable') is 'true'
        sortableElement = sortableWrapper(target)
        elementBeingDragged = target
        placeholder = placeholderFactory(target)
        initialIndex = indexOfNodeInParent(target, sortableElement)
        kss.addClass target, 'sortable-dragging'
        # target.style.opacity = '0.4'
        event.dataTransfer.effectAllowed = 'move'
        event.dataTransfer.setData('text/html', target.innerHTML)

    kss.addEventListener document, 'dragover', (event) ->
      if event.preventDefault
        event.preventDefault() # Allow drop
      return false
    
    kss.addEventListener document, 'dragenter', (event) ->
      if (target = event.target) && elementBeingDragged && (draggable = closestDraggable(target))
        # Stuff to be done immediately after 'dragstart'
        event.dataTransfer.dropEffect = 'move'
        kss.hide elementBeingDragged

        kss.addClass draggable, 'sortable-dragover'
        insertPlaceholder(draggable)
    
    kss.addEventListener document, 'dragend', (event) ->
      if (target = event.target) && elementBeingDragged && (draggable = closestDraggable(target))
        cleanup()
    
    kss.addEventListener document, 'drop', (event) ->
      if (target = event.target) && (kss.hasClass(target, 'sortable-placeholder'))
        if event.stopPropagation
          event.stopPropagation() # prevent redirect
        target.parentNode.insertBefore(elementBeingDragged, target)
        if indexOfNodeInParent(elementBeingDragged, sortableElement) isnt initialIndex
          kss.sendEvent('sortableupdate', sortableElement)
          cleanup()
          # target.innerHTML = event.dataTransfer.getData('text/html')
        return false

    kss.addEventListener document, 'sortableupdate', (event) ->
      target = event.target
      sortables = target.querySelectorAll('[draggable]')
      sortable_ids = (idToNumbers sortable.id for sortable in sortables)
      KSAjax.ajax 
        method: 'post'
        url: sortableElement.getAttribute('data-action')
        callbackContext: sortableElement
        data: ("#{sortableElement.id}[]=#{sortable_id}" for sortable_id in sortable_ids).join('&')

    kss.addEventListener document, 'drop', (event) ->
      if (target = event.target) && kss.hasClass(target, 'dropbox')
        event.stopPropagation()
        event.preventDefault()
        dropbox(event)
        return false

  # returns the numeric value at the end of the string
  idToNumbers = (str) ->
    numberAsString = str.replace(/(.*?)([0-9]*)$/, "$2")
    parseInt(numberAsString, 10)

  cleanup = () ->
    placeholder.parentNode.removeChild(placeholder) if placeholder && placeholder.parentNode
    if elementBeingDragged
      kss.show elementBeingDragged
      kss.removeClass elementBeingDragged, 'sortable-dragging'
      for node in elementBeingDragged.childNodes
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
    params = ("data_transfer[#{type}]=#{encodeURIComponent(event.dataTransfer.getData(type))}" for type in event.dataTransfer.types)
    if target.hasAttribute('data-params')
      params.push target.getAttribute('data-params')

    KSAjax.ajax
      method: method
      url: action
      callbackContext: target
      data: params.join('&')

  this.initialize = initialize
  return this

window.KSSortable = new KSSortableConstructor()
