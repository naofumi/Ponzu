# We use this when we want to force cache flushing on the browser.
#
# We use this to trigger a browser-side cache refresh.
#
# Currently, we only have a full-reset based on version numbers.
# In the future, we want to be finer grained.
#
# We store a version string inside a cookie which represents the
# version currently in client localStorage (browserVersion.
# 
# The version on the server is retrieved by a GET request to "/ks_cache_version.html"
# which we currently return from /public (currentVersion).
#
# The browserVersion and currentVersion are compared, and the cache is flushed
# unless they are identical.
#
# Because we require an Ajax request, this will work even for offline applications.
# It will be triggered whenever Kamishibai Javascript is reloaded and initialized.
KSCacheVersionConstructor = ->

  resetCacheOnServerVersion = ->
    KSAjax.ajax url: "/system/ks_cache_version.html", method: "get", success: resetCacheCallback

  resetCacheCallback = (data, textStatus, xhr) ->
    if data then currentVersion = data.trim() else currentVersion = "null"
    resetCacheIfStale(currentVersion)

  browserVersion = ->
    KSCookie.get('cache_version')

  resetCacheIfStale = (currentVersion) ->
    if currentVersion isnt browserVersion()
      console.log('reset cache because browser: ' + browserVersion() + ', current: ' + currentVersion);
      resetCache()
      KSCookie.create('cache_version', currentVersion, 360) # 360 days

  resetCache = ->
    KSSqlCache.clear()
    localStorage.clear()



  # public interface
  this.resetCacheIfStale = resetCacheIfStale
  this.resetCache = resetCache
  this.resetCacheOnServerVersion = resetCacheOnServerVersion
  return this

window.KSCacheVersion = new KSCacheVersionConstructor()

# Reset the cache if stale on load (before initialize)
kamishibai.beforeInitialize ->
  KSCacheVersion.resetCacheOnServerVersion()

