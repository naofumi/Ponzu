module('KSUrl testing')
test 'KSUrl.parseHref returns false if not Kamishibai URL', ->
	equal KSUrl.parseHref("http://test.com/#the_id"), false
	equal KSUrl.parseHref("http://test.com/"), false

test 'KSUrl.parseHref returns Id for Id only KSUrl', ->
	deepEqual KSUrl.parseHref("http://test.com/#!the_id"),
	          { "baseUrl": "/", "pageId": "the_id", "resourceUrl": null}

test 'KSUrl.parseHref returns resource for resource KSUrl', ->
	deepEqual KSUrl.parseHref("http://test.com/#!_/the_resource"),
	          { "baseUrl": "/", "pageId": null, "resourceUrl": "/the_resource"}

test 'KSUrl.parseHref returns resource and Id for KSUrl', ->
	deepEqual KSUrl.parseHref("http://test.com/#!_/the_resource__the_id"),
	          { "baseUrl": "/", "pageId": "the_id", "resourceUrl": "/the_resource"}

test "KSUrl.stripHost works ok", ->
	equal KSUrl.stripHost("http://test.com/#!the_id"),
	      "/#!the_id"
	equal KSUrl.stripHost("https://test.com/#!the_id"),
	      "/#!the_id"
	equal KSUrl.stripHost("http://test.com/"),
	      "/"
	equal KSUrl.stripHost("http://test.com"),
	      "/"

test "KSUrl.toNormalizedPath", ->
	equal KSUrl.toNormalizedPath(""),
	      "/"
	equal KSUrl.toNormalizedPath("/"),
	      "/"
	equal KSUrl.toNormalizedPath("/the_path"),
	      "/the_path"
	equal KSUrl.toNormalizedPath("/the_path/"),
	      "/the_path"	      