module "MockHTTPRequest", {}

test "test MockHTTPRequest", ->
  request = new MockHttpRequest();
  request.open("POST", "http://some.host/path")
  request.setRequestHeader("Content-Type", "application/robot")
  request.onload = () ->
    console.log("Received response: " + this.statusText)
    console.log("Response body: " + this.responseText)
  request.send("Test body")
  equal "Test body", request.requestText


test "test MockHTTPServer", ->
  server = new MockHttpServer()
  server.handle = (request) ->
      request.setResponseHeader("Content-Type", "application/robot")
      request.receive(200, "I am Bender, please insert girder!")
  server.start()

  xhr = new XMLHttpRequest()

  xhr.open("GET", "http://some.host/path", true)

  readyStateCallback = () ->
    if xhr.readyState == 4
      equal xhr.responseText, "I am Bender, please insert girder!"

  xhr.addEventListener('readystatechange', readyStateCallback, false)
  xhr.send({})


  server.stop()
