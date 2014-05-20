// Reading cookies on a browser is quite a slow function.
// On the iPod 4th gen. (2010), it takes more than 1ms.
// We have to use this very sparingly.
// localStorage is at least a magnitute faster, even on iPod 4th gen.
//
// To improve performance, you can specify {cacheBetweenReloads:['user_id', 'locale', device']}
// in the options. Then when you `readCookie('user_id')`, `readCookie('locale')` or `readCookie('device')`,
// the cached value will be returned without ever accessing document.cookie,
// resulting in huge performance benefits.
//
// The cookie value is only cached in memory, so a full page reload will
// reset the cache. Since we always do a full reload after changing login status and locale,
// this is OK.
window.KSCookie = function(options){
  var cookiesCachedBetweenReloads = [];
  if (options && options['cacheBetweenReloads']) 
    cookiesCachedBetweenReloads = options['cacheBetweenReloads'];

  // http://www.quirksmode.org/js/cookies.html
  var previousCookieString = "";
  var cookieCache = {};

  function createCookie(name,value,days) {
    if (days) {
      var date = new Date();
      date.setTime(date.getTime()+(days*24*60*60*1000));
      var expires = "; expires="+date.toGMTString();
    }
    else var expires = "";
    document.cookie = name+"="+value+expires+"; path=/";
  }

  // http://stackoverflow.com/questions/4003823/javascript-getcookie-functions/4004010#4004010
  // provides a bulletproof solution, but we want to go for speed here.
  // When I profiled Javascript on the iPod Touch 4th, a lot of time was
  // being spent here.
  // We also looked at http://jsperf.com/cookie-parsing, but the current solution
  // seemed to be the fastest.
  // The only solution is to cache.
  // However, calling document.cookie itself is slow (and maybe the bottleneck).
  // Not getting enough performance improvements.
  // I wrote http://jsperf.com/document-cookie-read to get a better idea.
  // Turns out that document.cookies is super slow, at least on iPod 4th gen.

  // From http://www.quirksmode.org/js/cookies.html
  // Modified to use a cache because we access this quite often
  // and we don't want to parse each time.
  function readCookie(name) {
    var nameEQ = name + "=";
    var cachedCookieAvailable = (typeof cookieCache[name] !== "undefined");

    if (cookiesCachedBetweenReloads.indexOf(name) && cachedCookieAvailable) {
      // console.log("COOKIE read from super cache for " + name + " value " + cookieCache[name]);
      return cookieCache[name];
    } else {
      var cookieString = document.cookie;
      if (cookieString === previousCookieString && cachedCookieAvailable) {
        // console.log("COOKIE read from regular cache for " + name + " value " + cookieCache[name]);
        return cookieCache[name];  
      } else {
        previousCookieString = cookieString;
        var ca = cookieString.split(';');
        // console.log("COOKIE read without cache for " + name);
        for(var i=0;i < ca.length;i++) {
          var c = ca[i];
          while (c.charAt(0) === ' ') c = c.substring(1,c.length);
          if (c.indexOf(nameEQ) === 0) {
            cookieCache[name] = c.substring(nameEQ.length,c.length);
            return cookieCache[name];
          }
        }
        cookieCache[name] = null;
        return null;              
      }
    }
  }

  function eraseCookie(name) {
    createCookie(name,"",-1);
  }

  // Public interface
  return {
    create: createCookie,
    get: readCookie,
    remove: eraseCookie
  }
}(['user_id', 'device', 'locale']);
