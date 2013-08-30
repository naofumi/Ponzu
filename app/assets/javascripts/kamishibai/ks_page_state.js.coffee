KSPageStateConstructor = () ->
  scrollMemory = () ->
    KSScrollMemory.get(KSUrl.stripHost(window.location.href))

  scrollBackToPreviousPostion = () ->
    sm = scrollMemory()
    # Ensure that there is enough height.
    document.getElementsByTagName('body')[0].style['min-height'] = ((sm.scrollY || 1) + 1000) + "px";
    if (typeof sm.scrollX isnt 'undefined' && sm.priority isnt 'element' && typeof sm.scrollY isnt 'undefined')
      # If sm.scrollX and scrollY have been set, then that has preference over
      # simply scrollToShow
      setTimeout ->
        scrollTo sm.scrollX, (sm.scrollY || 1)
      , 0
    else if sm.elementId && e = document.getElementById(sm.elementId)
      setTimeout ->
        scrollToShow(e)
        kss.addClass(e, 'move_pin')
      , 0

  showClickedIndicatorWithinElement = () ->
    sm = scrollMemory()
    if sm.clicked
      clickedElements = document.querySelectorAll("[href='" + sm.clicked + "']");
      for clickedElement in clickedElements
        kss.addClass clickedElement, 'was_clicked_indicator'

  scrollToShow = (element) ->
    pos = position element
    window.scrollTo(pos.x, pos.y)

  position = (element) ->
    x = element.offsetLeft
    y = element.offsetTop
    currentElement = element
    while (parent = currentElement.offsetParent) && parent isnt document.body
      x += parent.offsetLeft
      y += parent.offsetTop
      currentElement = parent
    {x: x, y: y}

  revert =() ->
    scrollBackToPreviousPostion()
    showClickedIndicatorWithinElement()

  # Public interface
  this.revert = revert
  this.scrollToShow = scrollToShow
  this

window.KSPageState = new KSPageStateConstructor()
