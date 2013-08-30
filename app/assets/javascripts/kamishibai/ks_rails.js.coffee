KSRailsConstructor = ->
  csrfToken = () ->
    if cookie = KSCookie.get('csrf-token')
      return cookie
    else if meta = document.querySelector("meta[name='csrf-token']")
      return meta.getAttribute('content')

  csrfParam = () ->
    if cookie = KSCookie.get('csrf-param')
      return cookie
    else if meta = document.querySelector("meta[name='csrf-param']")
      return meta.getAttribute('content')

  # public interface

  this.csrfToken = csrfToken
  this.csrfParam = csrfParam

  return this

window.KSRails = new KSRailsConstructor()