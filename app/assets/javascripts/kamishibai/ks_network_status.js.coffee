# Provides information about the network status.
#
# Unlike navigator.onLine, it also considers how long
# the last Kamishibai Ajax request took, so it also
# measures network conjestion and server conjestion.
#
# Uses in-app memory to store current status.
#
# This value is used to decide whether the CachedAjax
# should send an Ajax request or not when we have
# an old cached value. In order to maximize responsiveness,
# we opt to use the old cached value if we ever 
# encounter a timeout.
#
# If the user decides that they want to try again to get
# a new value, all they need to do is push the refresh
# button, which will refresh KSNetworkStatus.
KSNetworkStatusContructor = ->
  onlineStatus = ->
    navigator.onLine

  lastAjaxTimedOut = false

  unstable = ->
    if lastAjaxTimedOut
      console.log('KSNetworkStatus.unstable sent true')
      true
    else
      false

  timedOut = ->
    lastAjaxTimedOut = true
    KSOnlineIndicator.showOnlineStatus()

  succeeded = ->
    lastAjaxTimedOut = false    
    KSOnlineIndicator.showOnlineStatus()


  this.unstable = unstable
  this.timedOut = timedOut
  this.succeeded = succeeded
  return this

window.KSNetworkStatus = new KSNetworkStatusContructor()

