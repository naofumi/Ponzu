originalTitle = null
module 'KSController testing',
  setup: ->
    sinon.stub(KSUrl, "parseHref").
          returns { "baseUrl": "/", "pageId": null, "resourceUrl": "/the_resource"}
    this.server = sinon.fakeServer.create()
    originalTitle = document.title
  teardown: ->
    KSUrl.parseHref.restore()
    this.server.restore()
    # for page in document.querySelectorAll('[data-ks_loaded]')
    #   if page && page.parentElement
    #     page.parentElement.removeChild(page)
    document.title = originalTitle


# asyncTest "handleHashChange triggers resource loading", ->
#   responseBody = """
#     <div class="page" data-title="a title" id="test_id">hello</div>
#     """
#   this.server.respondWith "GET", "/the_resource",
#                           [200, { "Content-Type": "text/html" }, 
#                           responseBody]
#   KSController.handleHashChange()

#   this.server.respond()
#   afterLoadHandler = (event) ->
#     start()
#     equal document.getElementById('test_id').innerHTML, "hello", "loaded resource"
#     removeEventListener('ks:aftershown', afterLoadHandler, false)
#   addEventListener('ks:aftershown', afterLoadHandler, false)
  

asyncTest "handleHashChange triggers recursive resource loading", ->
  responseBody = """
    <div class="page" data-title="a title" id="test_id">
    hello
    <div id="nested_one_id" data-ajax="/nested_resource"></div>
    </div>
    """
  nestedResponseBody = """
    <div id="nested_one_id">nested hello</div>
    """
  expectedCompositedBody = """
    \nhello
    <div id="nested_one_id" data-ajax="/nested_resource">nested hello</div>\n
  """
  this.server.autoRespond = true
  this.server.respondWith "GET", "/the_resource",
                          [200, { "Content-Type": "text/html" }, 
                          responseBody]
  this.server.respondWith "GET", "/nested_resource",
                          [200, { "Content-Type": "text/html" }, 
                          nestedResponseBody]
  KSController.handleHashChange()

  # this.server.respond()

  afterLoadHandler = (event) ->
    start()
    equal document.getElementById('test_id').innerHTML, 
          expectedCompositedBody, 
          "loaded resource"

  # Wait till dependencies load
  setTimeout(afterLoadHandler, 100)
