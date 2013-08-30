KSOverlayConstructor = ->
  overlay = () ->
    document.getElementById('overlay')
  show = ()->
    kss.show(overlay(), true)
    kss.addClass(overlay(), 'show')
    this
  hide = ()->
    kss.removeClass(overlay(), 'show')
    # kss.hide(overlay())
    this
  toggle = () ->
    if kss.hasClass(overlay(), 'show')
      hide(overlay())
    else
      show(overlay(), true)
    this
  this.show = show
  this.hide = hide
  this.toggle = toggle
  return this

window.KSOverlay = new KSOverlayConstructor()

kamishibai.beforeInitialize ()->
  kss.addEventListener document, 'click', (event)->
    target = event.target;
    if target && kss.closestByClass(target, 'autoclose_overlay')
      KSOverlay && KSOverlay.hide()

  overlayDisplayNoneAfterHide = (event)->
    target = event.target;
    if target.id is "overlay"
      overlay = document.getElementById('overlay')
      if !kss.hasClass(overlay, "show")
        kss.hide(overlay)    

  kss.addEventListener document, 'webkitAnimationEnd', overlayDisplayNoneAfterHide
  kss.addEventListener document, 'animationend', overlayDisplayNoneAfterHide
