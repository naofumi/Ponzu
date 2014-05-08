module 'KSAjax test', 
  setup: ->
    this.xhr = sinon.useFakeXMLHttpRequest()
    requests = this.requests = [];
    this.xhr.onCreate = (xhr) ->
            requests.push(xhr)
  teardown: ->
    this.xhr.restore()

test 'html success', ->
  success = (data, textStatus, xhr)->
    equal textStatus, "success", "status success"
    equal xhr.responseText, 'hello', "responseText correct"
    equal xhr.method, "GET", "method correct"
    equal data, "hello", "data correct"
  complete = sinon.spy (xhr, textStatus) ->
    equal textStatus, "success", "status success"
  successHandler = sinon.spy()
  addEventListener 'ajaxSuccess', successHandler
  completeHandler = sinon.spy()
  addEventListener 'ajaxComplete', completeHandler
  KSAjax.ajax
    url: "/some/article"
    success: success
    complete: complete
    method: "get"
  equal this.requests.length, 1, "request set"
  this.requests[0].respond 200, { "Content-Type": "text/html" },
                                 'hello'
  ok successHandler.called, "ajaxSuccess event raised"
  ok completeHandler.called, "ajaxComplete event raised"
  ok complete.called, "complete called"

test 'javascript in body success', ->
  success = (data, textStatus, xhr)->
    equal textStatus, "success"
    equal window.testResult, "howdy", "javascript run"
    equal data, null, "data should be null when javascript run"
  complete = (xhr, textStatus) ->
    equal textStatus, "success"
  successHandler = sinon.spy()
  addEventListener 'ajaxSuccess', successHandler

  KSAjax.ajax
    url: "/some/article"
    success: success
    complete: complete
    method: "GET"
  equal this.requests.length, 1, "request set"
  this.requests[0].respond 200, { "Content-Type": "text/javascript" },
                                 "window.testResult = 'howdy'"

  ok successHandler.called, "ajaxSuccess event raised"

test 'javascript in X-JS header', ->
  success = (data, textStatus, xhr)->
    equal textStatus, "success"
    equal window.testResult, "super howdy", "javascript run"
    equal data, "response body", "data should be preserved when javascript run in header"
  KSAjax.ajax
    url: "/some/article"
    method: "GET"
    success: success
  this.requests
  equal this.requests.length, 1, "request set"
  this.requests[0].respond 200, 
                           { "Content-Type": "text/html", "X-JS": "window.testResult = 'super howdy'" },
                           "response body"


test 'javascript in body syntax error', ->
  KSAjax.ajax
    url: "/some/article"
    method: "GET"
  equal this.requests.length, 1
  throws ->
    this.requests[0].respond 200, { "Content-Type": "text/javascript" },
                                 "syntax error"
  , SyntaxError, "ajax syntax error throws error"  

test '404', ->
  success = sinon.spy()
  complete = sinon.spy (xhr, textStatus) ->
    equal textStatus, "404 file not found at url", "complete status"
  error = sinon.spy (xhr, textStatus, errorThrown) ->
    equal textStatus, "404 file not found at url", "error status"
    equal errorThrown, "Not Found"
    return true
  errorHandler = sinon.spy()
  addEventListener 'ajaxError', errorHandler

  KSAjax.ajax
    url: "/some/article"
    success: success
    complete: complete
    error: error
    method: "GET"
  equal this.requests.length, 1
  this.requests[0].respond 404
  ok !success.called, "success never called"
  ok complete.called, "complete called"
  ok error.called, "error called"
  ok errorHandler.called, "ajaxError event raised if callback return value is true"

