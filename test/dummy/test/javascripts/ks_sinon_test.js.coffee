module 'sinon testing', 
  setup: ->
    this.xhr = sinon.useFakeXMLHttpRequest();
    requests = this.requests = [];
    this.xhr.onCreate = (xhr) ->
            requests.push(xhr)
  teardown: ->
    this.xhr.restore()
test 'sinon test', ->
  callback = (xhr, textStatus)->
    equal textStatus, "success"
    equal xhr.responseText, '[{ "id": 12, "comment": "Hey there" }]'
  jQuery.ajax
    url: "/some/article"
    complete: callback
  equal this.requests.length, 1
  this.requests[0].respond 200, { "Content-Type": "application/json" },
                                 '[{ "id": 12, "comment": "Hey there" }]'
