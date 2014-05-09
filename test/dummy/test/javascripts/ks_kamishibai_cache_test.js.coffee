module 'Kamishibai Cache test',
  setup: ->

  teardown: ->

asyncTest 'lscache set and get for valid value', ->
  lscache.set "the_key", "the_value", 1, ->
    lscache.get "the_key", (value, hasExpired) ->
      start()
      equal value, "the_value", "set value and get value match"
      equal hasExpired, undefined, "hasExpired is false"

asyncTest 'lscache set and get for expired value', ->
  lscache.set "the_key", "the_value", -1, ->
    lscache.get "the_key", (value, hasExpired) ->
      start()
      equal value, "the_value", "set value and get value match"
      equal hasExpired, true, "hasExpired is true"



# asyncTest 'initialize 4M KSSql database', ->
#   if false
#     ok KSSqlCache.initialize(4)
#     retrivedValue = null
#     kilobyteString = ('a' for num in [0..1024]).join('')
#     KSSqlCache.set "key_1", "value_1", 1000, ->
#       KSSqlCache.get 'key_1', (value) ->
#         retrivedValue = value
#         start()
#         equal retrivedValue, "value_1", "single value"
#         KSSqlCache.clear()
#   else
#     start()
#     ok false, "Skipped"

# asyncTest 'fill up 5M KSSql database', ->
#   if false
#     KSSqlCache.clear()
#     # In iOS7, it seems that we cannot initially set a high
#     # size. Instead, we have to initially set a small value,
#     # otherwise the database itself will not be created.
#     # We have to query the user each time we exceed quota
#     # 10M -> 25M -> 50M, which is a good thing really.
#     ok KSSqlCache.initialize(4)
#     retrivedValue = null
#     stringSize = 10 # megabytes
#     largeString = ('a' for num in [1..(stringSize * 1024 * 1024)]).join('')
#     equal largeString.length, stringSize * 1024 * 1024, "largeString size OK"
#     KSSqlCache.set "large_string", largeString, 1000, ->
#       KSSqlCache.get "large_string", (value) ->
#         start()
#         equal value, largeString, "large string OK"
#         KSSqlCache.clear()
#   else
#     start()
#     ok false, "Skipped"
