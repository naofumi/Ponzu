KSOnlineIndicatorContructor = ->
  kamishibai.beforeInitialize ->
    kss.addEventListener window, 'online', showOnlineStatus

    kss.addEventListener window, 'offline', showOnlineStatus

  showOnlineStatus = ->
    html = if navigator.onLine
      if KSNetworkStatus.unstable()
        "<div class='network-unstable'>Network Unstable: Displayed page may be outdated.</div>"
      else
        "<div class='online'>Online</div>"
    else
      "<div class='offline'>Offline: Displayed page may be outdated.</div>"

    document.getElementById('status') && document.getElementById('status').innerHTML = html

  this.showOnlineStatus = showOnlineStatus
  return this

window.KSOnlineIndicator = new KSOnlineIndicatorContructor()

