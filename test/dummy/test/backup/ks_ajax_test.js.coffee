server = null
module "KSAjax test",
  setup: ->
    server = new MockHttpServer()
  teardown: ->
    server.stop()

test "test KSAjax", ->
  server.handle = (request) ->
    request.setResponseHeader("Content-Type", "text/html")
    request.receive(200, "hello")
  server.start()
  KSAjax.ajax 
    url: "/test_path"
    method: "GET"
    success: (data, textStatus, xhr)->
      equal textStatus, "SHIT"

