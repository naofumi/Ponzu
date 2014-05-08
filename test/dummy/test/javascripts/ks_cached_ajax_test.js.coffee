module 'KSCache.cachedAjax test', 
  setup: ->
    localStorage.clear()
    # How sinon works;
    # When a xhr request is made using `new XMLHttpRequest()`,
    # sinon creates a new FakeXMLHttpRequest object.
    # On creation, the `onCreate(xhr)` method is called.
    # We use the onCreate method to provide a handle for the xhr objects.
    # We set the response body, etc. using this handle.
    # The actual request is probably only send when we run an assertion.
    this.xhr = sinon.useFakeXMLHttpRequest()
    requests = this.requests = []
    xhrOnCreateSpy = this.xhrOnCreateSpy = sinon.spy()
    this.xhr.onCreate = (xhr) ->
      xhrOnCreateSpy()
      requests.push(xhr)
  teardown: ->
    this.xhr.restore()

test 'cachedAjax success with nothing in cache', ->
  successHandler = sinon.spy()
  addEventListener 'ajaxSuccess', successHandler
  completeHandler = sinon.spy()
  addEventListener 'ajaxComplete', completeHandler
  errorHandler = sinon.spy()
  addEventListener 'ajaxError', errorHandler
  cachedSuccessHandler = sinon.spy()
  addEventListener 'cachedAjaxSuccess', cachedSuccessHandler
  cachedCompleteHandler = sinon.spy()
  addEventListener 'cachedAjaxComplete', cachedCompleteHandler

  success = (data, textStatus, xhr)->
    equal textStatus, "success", "status success"
    equal xhr.responseText, 'hello', "responseText correct"
    equal xhr.method, "GET", "method correct"
    equal data, "hello", "data correct"
    ok cachedSuccessHandler.called, "cachedAjaxSuccess event raised before ajaxSuccess"
  complete = sinon.spy (xhr, textStatus) ->
    equal textStatus, "success", "status success"
    ok successHandler.called, "ajaxSuccess event raised before ajaxComplete"

  KSCache.cachedAjax
    url: "/some/article"
    success: success
    complete: complete
    method: "get"
  equal this.requests.length, 1, "request set"
  this.requests[0].respond 200, { "Content-Type": "text/html" },
                                 'hello'

  ok cachedSuccessHandler.calledOnce, "cachedAjaxSuccess event raised once"
  ok successHandler.calledOnce, "ajaxSuccess event raised once"
  ok complete.calledOnce, "complete callback called once"
  ok completeHandler.calledOnce, "ajaxComplete event raised once"
  ok !errorHandler.called, "ajaxError event not raised for at this point for ks_cache_version.html"
  ok this.xhrOnCreateSpy.calledOnce, "Fake XHR called once"


asyncTest 'cachedAjax success with valid cache', ->
  responseString = '<div class="page" data-title="a title" id="test_id" data-expiry=60>hello</div>'

  KSCache.cachedAjax
    url: "/some/article"
    method: "get"
  equal this.requests.length, 1, "request set"
  this.requests[0].respond 200, { "Content-Type": "text/html" },
                                 responseString

  successHandler = sinon.spy()
  addEventListener 'ajaxSuccess', successHandler
  cachedSuccessHandler = sinon.spy()
  addEventListener 'cachedAjaxSuccess', cachedSuccessHandler
  cachedCompleteHandler = sinon.spy()
  addEventListener 'cachedAjaxComplete', cachedCompleteHandler
  completeHandler = sinon.spy()
  addEventListener 'ajaxComplete', completeHandler

  successInsideCacheSpy = sinon.spy()
  completeInsideCacheSpy = sinon.spy()
  requests = this.requests = []; # reset requests
  KSCache.cachedAjax
    url: "/some/article"
    success: ->
      successInsideCacheSpy()
    complete: ->
      completeInsideCacheSpy()
      equal requests.length, 0, "No requests sent because cached"        
    method: "get"

  ok successInsideCacheSpy.calledOnce, "Success callback called inside cached response"
  ok completeInsideCacheSpy.calledOnce, "Complete callback called inside cached response"
  ok !successHandler.called, "ajaxSuccess event not called because cached"
  ok !completeHandler.called, "ajaxComplete event not called because cached"
  ok cachedSuccessHandler.calledOnce, "cachedAjaxSuccess event raised once for cached result"
  ok cachedCompleteHandler.calledOnce, "cachedAjaxComplete event raised once for cached result"
  ok this.xhrOnCreateSpy.calledOnce, "Fake XHR called once for network request"

  start()

test 'cachedAjax success with expired cache item', ->
  responseString = '<div class="page" data-title="a title" id="test_id" data-expiry=1>hello</div>'

  KSCache.cachedAjax
    url: "/some/article"
    method: "get"
  this.requests[0].respond 200, { "Content-Type": "text/html" },
                                 responseString

  successHandler = sinon.spy()
  addEventListener 'ajaxSuccess', successHandler
  cachedSuccessHandler = sinon.spy()
  addEventListener 'cachedAjaxSuccess', cachedSuccessHandler
  cachedCompleteHandler = sinon.spy()
  addEventListener 'cachedAjaxComplete', cachedCompleteHandler
  completeHandler = sinon.spy()
  addEventListener 'ajaxComplete', completeHandler

  successInsideCacheSpy = sinon.spy()
  completeInsideCacheSpy = sinon.spy()

  that = this
  setTimeout ->
    KSCache.cachedAjax
      url: "/some/article"
      success: ->
        successInsideCacheSpy()
      complete: ->
        completeInsideCacheSpy()
      method: "get"
    equal that.requests.length, 2, "second request set"
    that.requests[1].respond 200, { "Content-Type": "text/html" },
                                   responseString    
  , 2000
  
  stop()
  
  # How to write async manually
  # http://jxck.hatenablog.com/entry/20100721/1279681676
  setTimeout ->
    start()
    ok successInsideCacheSpy.calledTwice, "Success callback called twice inside cached response"
    ok completeInsideCacheSpy.calledTwice, "Complete callback called twice inside cached response"
    ok successHandler.calledOnce, "ajaxSuccess event raised once for network request"
    ok completeHandler.calledOnce, "ajaxComplete event raised once for network request"
    ok cachedSuccessHandler.calledTwice, "cachedAjaxSuccess event raised twice"
    ok cachedCompleteHandler.calledTwice, "cachedAjaxComplete event raised twice"
    ok that.xhrOnCreateSpy.called, "Fake XHR called once for network request"
  , 3000

asyncTest '404 Error handling', ->
  successHandler = sinon.spy()
  addEventListener 'ajaxSuccess', successHandler
  completeHandler = sinon.spy()
  addEventListener 'ajaxComplete', completeHandler
  errorHandler = sinon.spy()
  addEventListener 'ajaxError', errorHandler
  cachedSuccessHandler = sinon.spy()
  addEventListener 'cachedAjaxSuccess', cachedSuccessHandler
  cachedCompleteHandler = sinon.spy()
  addEventListener 'cachedAjaxComplete', cachedCompleteHandler

  KSCache.cachedAjax
    url: "/some/article"
    method: "get"
  equal this.requests.length, 1, "request set"
  this.requests[0].respond 404, { "Content-Type": "text/html" }, ""

  ok !cachedSuccessHandler.called, "cachedAjaxSuccess event not raised"
  ok cachedCompleteHandler.called, "cachedAjaxComplete event raised"
  ok !successHandler.called, "ajaxSuccess event not raised"
  ok completeHandler.called, "ajaxComplete event raised once"
  ok errorHandler.calledOnce, "ajaxError event raised"

  start()
  return

asyncTest '500 Error handling', ->
  start()
  return

asyncTest '300 Redirect handling', ->
  start()
  return
