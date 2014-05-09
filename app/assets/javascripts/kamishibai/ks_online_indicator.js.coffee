KSOnlineIndicatorContructor = ->
  previousOnlineStatus = undefined;

  kamishibai.beforeInitialize ->
    kss.addEventListener window, 'online', showOnlineStatus

    kss.addEventListener window, 'offline', showOnlineStatus

  showOnlineStatus = ->
    if status() isnt previousOnlineStatus
      html = switch status()
        when "unstable" 
          "<div class='network-unstable'>Network Unstable: Displayed page may be outdated.</div>"
        when "online" 
          "<div class='online'>Online</div>"
        when "offline" 
          "<div class='offline'>Offline: Displayed page may be outdated.</div>"

      document.getElementById('status') && document.getElementById('status').innerHTML = html          
      previousOnlineStatus = status()

  status = ->
    if navigator.onLine
      if KSNetworkStatus.unstable()
        return 'unstable'
        "<div class='network-unstable'>Network Unstable: Displayed page may be outdated.</div>"
      else
        return 'online'
    else
      return 'offline'

  this.showOnlineStatus = showOnlineStatus
  return this

window.KSOnlineIndicator = new KSOnlineIndicatorContructor()

