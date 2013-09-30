originalTitle = document.title
toElement = null
fromElement = null
module 'KSCompositor test', 
  setup: ->
    toElement = document.createElement('div')
    toElement.className = "page"
    toElement.id = "to_id"
    toElement.dataset.title = "a title"
    toElement.style.display = "none"
    document.body.appendChild(toElement)

    fromElement = document.createElement('div')
    fromElement.className = "page"
    fromElement.id = "from_id"
    document.body.appendChild(fromElement)

    loadedFromElement = document.createElement('div')
    loadedFromElement.className = "page"
    loadedFromElement.id = "loaded_from_id"
    loadedFromElement.dataset['ks_loaded'] = true
    loadedFromElement.dataset.ajax = "/resource_url"
    document.body.appendChild(loadedFromElement)

  teardown: ->
    pages = document.getElementsByClassName('page')
    for page in pages
      # page may be removed
      if page
        page.parentElement.removeChild(page)
    document.title = originalTitle

test "confirm setup", ->
  ok document.getElementById('to_id')
  ok document.getElementById('from_id')

test "top level showElement", ->
  beforeShowHandler = sinon.spy()
  addEventListener 'ks:beforeshow', beforeShowHandler, false
  afterShownHandler = sinon.spy()
  addEventListener 'ks:aftershown', afterShownHandler, false
  ok !kss.isVisible(toElement), "should be invisible at first"
  callback = sinon.spy()
  shownElement = KSCompositor.showElement toElement, false, callback
  equal shownElement, toElement, "return value should be toElement"
  ok kss.isVisible(toElement), "toElement should be made visible"
  equal document.title, "a title", "title should be set"
  ok !kss.isVisible(fromElement), "fromElement should be hidden"
  ok beforeShowHandler.called, "ks:beforeshow event should fire"
  ok afterShownHandler.called, "ks:aftershown event should fire"
  ok callback.called, "callback should be called"

  equal document.getElementById('loaded_from_id'), null, "should remove unnecessary nodes"
  