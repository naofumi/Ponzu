# Saves the current scroll position in memory
# and restores it when we move back.
#
# Uses sessionStorage
#
# In addition to setting the current scroll position,
# you can manipulate the ScrollMemory so that the next
# time you visit a certain URL, you can specify where you
# want to scroll to.
#
# For example, we have links to a timetable view and we
# want the browser to scroll to a certain entry when we
# show the view. To do this, we set the scrollMemory for the
# timetable view to scroll to that entry. In these cases,
# we won't be able to specify the absolute scroll position
# so we specify the id of the element we want to scrollIntoView.
#
KSScrollMemoryConstructor = ()->
  radix = 36
  CACHE_PREFIX = "KSScrollMemory-"

  scrollStore = ->
    if lscache.supported()
      return sessionStorage
    else
      # If sessionStorage is not supported,
      # then use in memory storage
      return memoryStorage

  # KSScrollMemory.set({href: "/hello/page", x: 360, y:200})
  # or
  # KSScrollMemory.set({href: "/hello/page", elementId: 'session_425'})
  #
  # By default, when we move back to a scroll memory, x, y will
  # be prioritized when we do PageState.scrollBackToPreviousPostion().
  # We can change that with the priority:"element" property.
  set = (options) ->
    # Use window.pageXOffset for cross-browser compatibility
    # https://developer.mozilla.org/ja/docs/DOM/window.scrollX
    href = if options.href isnt undefined then options.href else window.location.href
    href = KSUrl.stripHost(href)
    x = if options.scrollX isnt undefined then options.scrollX else window.pageXOffset
    y = if options.scrollY isnt undefined then options.scrollY else window.pageYOffset
    clicked = options.clicked || null
    elementId = options.elementId || null
    priority = options.priority || null
    string = JSON.stringify
      scrollX: x.toString(radix), 
      scrollY: y.toString(radix), 
      clicked: clicked
      elementId: elementId
      priority: priority
    scrollStore().setItem(CACHE_PREFIX + href, string);

  get = (href) ->
    string = scrollStore().getItem(CACHE_PREFIX + href)
    if (string)
      obj = JSON.parse(string)
      obj.scrollX = parseInt(obj.scrollX, radix)
      obj.scrollY = parseInt(obj.scrollY, radix)
      obj.clicked = obj.clicked
      obj.elementId = obj.elementId
      obj.priority = obj.priority
    else
      obj = {scrollX: 0, scrollY: 1, clicked: null}

    obj

  # Public interface
  this.set = set
  this.get = get
  this

window.KSScrollMemory = new KSScrollMemoryConstructor
