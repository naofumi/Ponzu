// Maintains a history for the current load.
// Serves mainly to calculate animation direction.
// Uses sessionStorage instead of memory because
// we may do full reloads when we want to reset the
// viewport zoom, for example.
window.KSHistory = function(){
  var radix = 36;
  var CACHE_PREFIX = "KSHistory-";
  var memoryStore = null;

  function historyStore() {
    if (lscache.supported()) {
      return sessionStorage
    } else {
      // If sessionStorage is not supported,
      // then use in memory storage
      return memoryStorage;
    }
  }

  function push(state, href) {
  	href = href || window.location.href;
    state = state || {};
  	var now = new Date();

    pruneHistory();
    state.visitedAt = now.getTime().toString(36);
  	console.log('push href: ' + href + ' into history');
  	historyStore().setItem(CACHE_PREFIX + href, 
                           storageString(state));
  }

  function getState(href) {
    href = href || window.location.href;
    return objForKey(CACHE_PREFIX + href);
  }

  function pruneHistory(){
    var href = window.location.href;
    var state = getState(href)
    if (state) {
      var previousEntryTimeString = state.visitedAt;
      console.log('found href: ' + href + ' in history');
      // Remove history entries after previousEntryTime.
      // This keeps the history linear and without branches.
      previousEntryTime = parseInt(previousEntryTimeString, radix);
      removeEntriesAfterTime(previousEntryTime);
    }
  }

  function storageString(obj){
    try {
      // Right now, we're only storing obj.visitedAt.
      return JSON.stringify(obj);
    } catch (e) {
      return obj.visitedAt;
    }
    return JSON.stringify(obj);
  }

  function objFromString(string){
    try {
      // We can't tell if its JSON or a string, so we try to parse
      return JSON.parse(string);
    } catch (e) {
      // If we can't parse, it's probably because it isn't an object
      return {visitedAt: string};
    }
  }

  function objForKey(key){
    if (historyStore().getItem(key)) {
      return objFromString(historyStore().getItem(key))
    } else {
      return null
    }
  }

  function isInHistory(href) {
  	return (getState(href) ? true : false);
  }

  function isBackwards(href) {
    href = href || window.location.href;
  	return (isInHistory(href) ? true : false);
  }

  function removeEntriesAfterTime(time) {
    var entriesToDelete = [];

    for (var i = 0; i < historyStore().length; i++) {
      var key = historyStore().key(i);
      if (key.indexOf(CACHE_PREFIX) == 0) {
        var timeString = objForKey(key).visitedAt;
        if (!timeString || parseInt(timeString, radix) > time) {
          entriesToDelete.push(key);
        }        
      }
    };

    for (var i = 0; i < entriesToDelete.length; i++) {
      console.log('remove id: ' + entriesToDelete[i] + ' from history');
      historyStore().removeItem(entriesToDelete[i]);
    };
  }

  function allIds() {
    var result = [];
    for (var i = 0; i < historyStore().length; i++) {
      var key = historyStore().key(i);
      if (key.indexOf(CACHE_PREFIX) != 0) continue;
      var id = key.replace(CACHE_PREFIX, '');
      result.push(id);
    };        
    return result;
  }

  function latestId() {
    var ids = idsSortedByTime();
    return ids[ids.length - 1]
  }

  function idsByRegExp(regexp) {
    var ids = allIds();
    var result = [];
    for (var i = 0; i < ids.length; i++) {
      if (regexp.test(ids[i])) {
        result.push(ids[i]);
      }
    };    
    return result;
  }

  function idsByNoMatchToRegExp(regexp) {
    var ids = allIds();
    var result = [];
    for (var i = 0; i < ids.length; i++) {
      if (!regexp.test(ids[i])) {
        result.push(ids[i]);
      }
    };    
    return result;
  }

  function idsSortedByTime(array){
    var array = array || allIds();
    var sortedIds = array.sort(function(a, b){
      if (!getState(a)) return -1;
      if (!getState(b)) return 1;
      var aTime = parseInt(getState(a).visitedAt, radix);
      var bTime = parseInt(getState(b).visitedAt, radix);
      return aTime - bTime;
    });
    return sortedIds;
  }

  function latestIdMatchingRegExp(regexp) {
    var allMatchingIds = idsByRegExp(regexp);
    return idsSortedByTime(allMatchingIds)[allMatchingIds.length - 1];
  }

  function latestIdNotMatchingRegExp(regexp){
    var allMatchingIds = idsByNoMatchToRegExp(regexp);
    return idsSortedByTime(allMatchingIds)[allMatchingIds.length - 1];    
  }

  return {
  	push: push,
  	isBackwards: isBackwards,
    latestIdMatchingRegExp: latestIdMatchingRegExp,
    latestIdNotMatchingRegExp: latestIdNotMatchingRegExp,
    latestId: latestId,
    idsSortedByTime: idsSortedByTime
  }

}();