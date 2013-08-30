window.KSSqlCache = function() {
  // Safari will ask us each time quota is exceeded.
  // 5M -> 10M -> 50M
  // 
  // var SIZE = 0.2 // megabytes
  var SIZE = 50 // megabytes
  var db;

  function initialize(){
    try {
      db = openDatabase('kssqlcache', '1.0', 'Kamishibai SQL Cache', SIZE * 1000 * 1000);
      localStorage.webSQLDBCreated = "1"
      createTables(function(){
        // Code to import lscache stuff into WebSQL
        // so that the data that we already have in lscache is preserved.
      });
      return true;
    } catch (e) {
      localStorage.webSQLDBCreated = ""
      console.log("Failed to create WebSQL database with error: " + e.message);
      return false;
    }    
  }

  function createTables(callback) {
    if (!db) return;
    db.transaction(function(transaction){
      transaction.executeSql("CREATE TABLE IF NOT EXISTS cache" +
                             "(id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, " +
                             "key TEXT UNIQUE, " +
                             "expires_at INTEGER, " +
                             "lru_at INTEGER, " +
                             "value TEXT)", [], callback, killTransaction);
    })
  }

  // expiration date radix (set to Base-36 for most space savings)
  var EXPIRY_RADIX = 10;

  // time resolution in seconds
  var EXPIRY_UNITS = 1000;

  // ECMAScript max Date (epoch + 1e8 days)
  var MAX_DATE = Math.floor(8.64e15/EXPIRY_UNITS);

  var cachedStorage;
  var cachedJSON;
  var cacheBucket = '';

  // Determines if native JSON (de-)serialization is supported in the browser.
  function supportsJSON() {
    /*jshint eqnull:true */
    if (cachedJSON === undefined) {
      cachedJSON = (window.JSON != null);
    }
    return cachedJSON;
  }

  function supportsStorage() {
    // TODO: implement some real shit
    return !!db;
  }

  /**
   * Returns the number of minutes since the epoch.
   * @return {number}
   */
  function currentTime() {
    return Math.floor((new Date().getTime())/EXPIRY_UNITS);
  }

  /* This is the data handler which would be null in case of table creation and record insertion */
  function nullDataHandler(transaction, results)   {
  }

  /* This is the error handler */
  function killTransaction(transaction, error) {
    alert("WebSQL Error: " + error.code + " : " + error.message);
  }

  /* This is the error handler */
  // The issue is that when we exceed the current quota
  // the error callback is fired
  // only after the modal dialog is shown. Furthermore
  // the callback is run regardless of whether we allowed
  // storage increase or not.
  // This means that we cannot implement LRU invisibly.
  function transactionErrorCallback(error) {
    alert("WebSQL Error: " + error.code + " : " + error.message)
  }

  function bucketedKey(key) {
    return (cacheBucket + key);
  }

  function touchLru(key, transaction) {
    transaction.executeSql('UPDATE cache SET lru_at=? WHERE key=?', 
                           [currentTime(), bucketedKey(key)], nullDataHandler, killTransaction);
  }

  function getItem(key, callback) {
    db.transaction(function(transaction){
      transaction.executeSql('SELECT * FROM cache WHERE key=? LIMIT 1', [bucketedKey(key)],
                    function(tx, results){
                      var row, value;
                      if (results.rows.length > 0) {
                        row = results.rows.item(0);
                        value = row.value;
                        expiresAt = row['expires_at']
                        lruAt = row['lru_at']
                        touchLru(key, transaction);
                      } else {
                        value = null;
                        expiresAt = null;
                        lruAt = null;
                      }
                      callback(value, expiresAt, lruAt);
                    }, killTransaction);
    })
  }

  function setItem(key, value, expires_at, callback) {
    if (!supportsStorage()) return;
    if (!callback) callback = nullDataHandler;
    db.transaction(function(transaction){
      transaction.executeSql("REPLACE INTO cache (key, expires_at, lru_at, value) " +
                             "VALUES (?, ?, ?, ?)", 
                              [bucketedKey(key), expires_at, currentTime(), value],
                              callback, killTransaction)
    }, transactionErrorCallback, nullDataHandler)
  }

  function remove(key) {
    if (!supportsStorage()) return;
    db.transaction(function(transaction){
      transaction.executeSql('DELETE FROM cache WHERE key=?', [bucketedKey(key)],
                             nullDataHandler, killTransaction)
    })
  }

  function set(key, value, time, callback) {
    // If we don't get a string value, try to stringify
    // In future, localStorage may properly support storing non-strings
    // and this can be removed.
    if (typeof value !== 'string') {
      if (!supportsJSON()) return;
      try {
        value = JSON.stringify(value);
      } catch (e) {
        // Sometimes we can't stringify due to circular refs
        // in complex objects, so we won't bother storing then.
        return;
      }
    }

    var expires_at;
    if (time) {
      expires_at = currentTime() + time;
    } else {
      expires_at = null;
    }

    setItem(key, value, expires_at, callback);    
  }

  /** Naofumi
   * Invalidates a cached entry by setting the expiry time
   * to now.
   * If we #getDefferingExpiry, we get the old value and the old entry is preserved.
   * We can test if it has expired by #hasCacheExpired.
   * @param {string} key
   */
  function invalidate(key) {
    if (!supportsStorage()) return;
    console.log('invalidating ' + key);
    db.transaction(function(transaction){
      transaction.executeSql('UPDATE cache SET expires_at=? WHERE key=?', 
          [currentTime(), bucketedKey(key)], nullDataHandler, killTransaction);
    })
  }

  // These functions work with raw keys, with no regard for prefixes
  function invalidateKeysByRegex(regex) {
    if (!supportsStorage()) return;
    var timeNow = currentTime();
    findKeysMatchingRegex(regex, function(keys){
      db.transaction(function(transaction){
        var inString = kss.arrayOfElements(keys.length, '?').join(',');
        transaction.executeSql('UPDATE cache SET expires_at=? WHERE key IN (' + inString + ')',
                               [timeNow].concat(keys), nullDataHandler, killTransaction)
      })      
    });
  }

  // These functions work with raw keys, with no regard for prefixes
  function findKeysMatchingRegex(regex, callback) {
    if (!supportsStorage()) return callback([]);
    var matchingKeys = [];
    db.transaction(function(transaction){
      transaction.executeSql('SELECT key FROM cache', [],
                    function(tx, results){
                      for (var i = 0; i < results.rows.length; i++) {
                        var key = results.rows.item(i).key;
                        if (regex.test(key)) {
                          matchingKeys.push(key);
                        }
                      };
                      callback(matchingKeys);
                    });
    })
  }

  /** Naofumi
  * Returns All Keys that have not expired, sorted by expiration
  */
  // These functions work with raw keys, with no regard for prefixes
  function allKeys(callback){
    if (!supportsStorage()) return callback([]);
    var keys = []
    db.transaction(function(transaction) {
      transaction.executeSql('SELECT key FROM cache WHERE (expires_at IS NULL OR expires_at <= ?) ORDER BY expires_at ASC', 
                             [currentTime()],
                             function(tx, results){
                               var rows = results.rows;
                               for (var i = 0; i < rows.length; i++) {
                                 var key = rows.item(i).key;
                                 keys.push(key);
                               };
                               callback(keys)
                             })
    })
  }

  /** Naofumi
   * Retrieves specified value from localStorage regardless of
   * expiry status.
   *
   * We use this in cases where the value is expired but we want
   * to return it regardless (i.e. because we can't connect to the server
   * due to network issues).
   * 
   * We also touch the LRU.
   * @param {string} key
   * @return {string|Object}
   */
  // function getDeferringExpiry(key, callback) {
  //   if (!supportsStorage()) return callback(null);
  //   getItem(key, function(value){
  //     if (!value || !supportsJSON()) {
  //       callback(value);
  //     }
  //     try {
  //       // We can't tell if its JSON or a string, so we try to parse
  //       callback(JSON.parse(value));
  //     } catch (e) {
  //       // If we can't parse, it's probably because it isn't an object
  //       callback(value);
  //     }
  //   })
  // }

  // Callback receives both the value and the expiry status (hasExpired)
  function get(key, callback) {
    if (!supportsStorage()) return callback(null);
    getItem(key, function(value, expiresAt, lruAt){
      var hasExpired = (currentTime() > expiresAt);
      if (!value || !supportsJSON()) {
        callback(value, hasExpired);
      } else {
        try {
          // We can't tell if its JSON or a string, so we try to parse
          callback(JSON.parse(value), hasExpired);
        } catch (e) {
          // If we can't parse, it's probably because it isn't an object
          callback(value, hasExpired);
        }        
      }
    })    
  }

  function clear() {
    if (!supportsStorage()) return;
    db.transaction(function(transaction){
      transaction.executeSql('DELETE FROM cache', 
          [], nullDataHandler, killTransaction);
    })
  }

  // Public methods
  return {
    initialize: initialize,
    set: set,
    invalidate: invalidate,

    /** Naofumi
    * Invalidates a batch of keys by regex.
    * The invalidation is done by setting the expiration key value to *now*.
    */
    invalidateKeysByRegex: invalidateKeysByRegex,
    findKeysMatchingRegex: findKeysMatchingRegex,

    /** Naofumi
    * Returns All Keys that have not expired, sorted by expiration
    */
    allKeys: allKeys,

    currentTime: currentTime,

    get: get,

    /** Naofumi
     * Retrieves specified value from localStorage regardless of
     * expiry status.
     *
     * We use this in cases where the value is expired but we want
     * to return it regardless (i.e. because we can't connect to the server
     * due to network issues).
     * 
     * We also touch the LRU.
     * @param {string} key
     * @return {string|Object}
     */
    // getDeferringExpiry: getDeferringExpiry,

    /** Naofumi
    * Return true if the cache has expired or was not set, false otherwise.
    * Expiry includes *now* so that we can immediately expire keys.
    * @param {string} key
    * @return {boolean}
    */
    // hasCacheExpired: hasCacheExpired,

    /**
     * Removes a value from localStorage.
     * Equivalent to 'delete' in memcache, but that's a keyword in JS.
     * @param {string} key
     */
    remove: remove,

    /**
     * Returns whether local storage is supported.
     * @return {boolean}
     */
    supported: supportsStorage,

    clear: clear,

    /**
     * Appends CACHE_PREFIX so lscache will partition data in to different buckets.
     * @param {string} bucket
     */
    setBucket: function(bucket) {
      cacheBucket = bucket;
    },
    
    /**
     * Resets the string being appended to CACHE_PREFIX so lscache will use the default storage behavior.
     */
    resetBucket: function() {
      cacheBucket = '';
    }

  };
}();