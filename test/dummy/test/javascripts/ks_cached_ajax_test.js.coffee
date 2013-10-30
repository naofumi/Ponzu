module 'KSCache.cachedAjax test', 
  setup: ->
    localStorage.clear()
    this.xhr = sinon.useFakeXMLHttpRequest()
    requests = this.requests = []
    xhrOnCreateSpy = this.xhrOnCreateSpy = sinon.spy()
    this.xhr.onCreate = (xhr) ->
      xhrOnCreateSpy()
      requests.push(xhr)
  teardown: ->
    this.xhr.restore()

test 'cachedAjax success with no expiry', ->
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


asyncTest 'cachedAjax success with expiry', ->
  responseString = '<div class="page" data-title="a title" id="test_id" data-expiry=60>hello</div>'

  successHandler = sinon.spy()
  addEventListener 'ajaxSuccess', successHandler
  cachedSuccessHandler = sinon.spy()
  addEventListener 'cachedAjaxSuccess', cachedSuccessHandler
  cachedCompleteHandler = sinon.spy()
  addEventListener 'cachedAjaxComplete', cachedCompleteHandler
  completeHandler = sinon.spy()
  addEventListener 'ajaxComplete', completeHandler

  KSCache.cachedAjax
    url: "/some/article"
    method: "get"
  equal this.requests.length, 1, "request set"
  this.requests[0].respond 200, { "Content-Type": "text/html" },
                                 responseString

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
  ok successHandler.calledOnce, "ajaxSuccess event raised only once for network request"
  ok completeHandler.calledOnce, "ajaxComplete event raised only once for network request"
  ok cachedSuccessHandler.calledTwice, "cachedAjaxSuccess event raised twice for each response"
  ok cachedCompleteHandler.calledTwice, "cachedAjaxComplete event raised twice for each response"
  ok this.xhrOnCreateSpy.calledOnce, "Fake XHR called once for network request"

  start()

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

  ok cachedSuccessHandler.calledOnce, "cachedAjaxSuccess event raised once"
  ok !cachedCompleteHandler.called, "cachedAjaxComplete event raised"
  ok !successHandler.called, "ajaxSuccess event raised once"
  ok !completeHandler.called, "ajaxComplete event raised once"
  ok errorHandler.calledOnce, "ajaxError event not raised for at this point for ks_cache_version.html"

  start()
  return

asyncTest '500 Error handling', ->
  start()
  return

asyncTest '300 Redirect handling', ->
  start()
  return
