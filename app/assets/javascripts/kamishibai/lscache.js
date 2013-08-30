/**
 * lscache library
 * Copyright (c) 2011, Pamela Fox
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*jshint undef:true, browser:true */

// Naofumi
//
// Heavily modified for Kamishibai.

/**
 * Creates a namespace for the lscache functions.
 */
var lscache = function() {

  // Prefix for all lscache keys
  var CACHE_PREFIX = 'lscache-';

  // Suffix for the key name on the expiration items in localStorage
  var CACHE_SUFFIX = '-cacheexpiration';

  // Suffix for the key name on the lru items in localStorage
  var LRU_SUFFIX = '-cachelru';

  // expiration date radix (set to Base-36 for most space savings)
  var EXPIRY_RADIX = 10;

  // time resolution in seconds
  var EXPIRY_UNITS = 1000;

  // ECMAScript max Date (epoch + 1e8 days)
  var MAX_DATE = Math.floor(8.64e15/EXPIRY_UNITS);

  var cachedStorage;
  var cachedJSON;
  var cacheBucket = '';

  // Determines if localStorage is supported in the browser;
  // result is cached for better performance instead of being run each time.
  // Feature detection is based on how Modernizr does it;
  // it's not straightforward due to FF4 issues.
  // It's not run at parse-time as it takes 200ms in Android.
  function supportsStorage() {
    var key = '__lscachetest__';
    var value = key;

    if (cachedStorage !== undefined) {
      return cachedStorage;
    }

    try {
      setItem(key, value);
      removeItem(key);
      cachedStorage = true;
    } catch (e) {
      if (e.name === 'QUOTA_EXCEEDED_ERR' || e.name === 'NS_ERROR_DOM_QUOTA_REACHED') {
        cachedStorage = true;
      } else {
        cachedStorage = false;        
      }
    }
    return cachedStorage;
  }

  // Determines if native JSON (de-)serialization is supported in the browser.
  function supportsJSON() {
    /*jshint eqnull:true */
    if (cachedJSON === undefined) {
      cachedJSON = (window.JSON != null);
    }
    return cachedJSON;
  }

  /**
   * Returns the full string for the localStorage expiration item.
   * @param {String} key
   * @return {string}
   */
  function expirationKey(key) {
    return key + CACHE_SUFFIX;
  }

  function lruKey(key) {
    return key + LRU_SUFFIX;
  }

  /**
   * Returns the number of minutes since the epoch.
   * @return {number}
   */
  function currentTime() {
    return Math.floor((new Date().getTime())/EXPIRY_UNITS);
  }

  /**
   * Wrapper functions for localStorage methods
   */

  function getItem(key) {
    return localStorage.getItem(CACHE_PREFIX + cacheBucket + key);
  }

  function setItem(key, value) {
    // Fix for iPad issue - sometimes throws QUOTA_EXCEEDED_ERR on setItem.
    localStorage.removeItem(CACHE_PREFIX + cacheBucket + key);
    localStorage.setItem(CACHE_PREFIX + cacheBucket + key, value);
  }

  function removeItem(key) {
    localStorage.removeItem(CACHE_PREFIX + cacheBucket + key);
  }

  // Remove the item, the expiry key and the lru key
  function removeItemSet(key) {
    removeItem(key);
    removeItem(expirationKey(key));
    removeItem(lruKey(key));
  }

  // Set the lru value to now
  function touchLru(key) {
    var timeString = currentTime().toString(EXPIRY_RADIX);
    try { 
      console.log('set LRU for key ' + key + ' to ' + timeString);
      setItem(lruKey(key), timeString);
    } catch(e) {
      if (e.name === 'QUOTA_EXCEEDED_ERR' || e.name === 'NS_ERROR_DOM_QUOTA_REACHED') {
        makeSpaceFor(timeString.length);
        setItem(lruKey(key), timeString);
      }
    }
  }

  function isExpirationKey(key) {
    return key.indexOf(CACHE_PREFIX + cacheBucket) === 0 && key.indexOf(CACHE_SUFFIX) >= 0
  }

  // We make space to accomodate targetSize.
  // We reset the cacheBucket while we do this, so that we can claim space
  // from other buckets.
  function makeSpaceFor(targetSize) {
    var storedKeys = [];
    var storedKey;
    console.log('making space for ' + targetSize + ' chars because QUOTA_EXCEEDED');
    KSBench.startBench('making space for ' + targetSize + ' chars because QUOTA_EXCEEDED');
    var cacheBucketStash = cacheBucket;
    lscache.resetBucket();
    // ToDo: The following to generate the storedKeys array should be pushed into a separate method
    for (var i = 0; i < localStorage.length; i++) {
      storedKey = localStorage.key(i);

      if (storedKey.indexOf(CACHE_PREFIX + cacheBucket) === 0 && 
          storedKey.indexOf(CACHE_SUFFIX) < 0 && 
          storedKey.indexOf(LRU_SUFFIX) < 0) {
        var mainKey = storedKey.substr((CACHE_PREFIX + cacheBucket).length);
        var lru = getItem(lruKey(mainKey));
        if (lru) {
          lru = parseInt(lru, EXPIRY_RADIX);
        } else {
          // keys without an lru will be purged first
          lru = MAX_DATE;
        }
        storedKeys.push({
          key: mainKey,
          size: (getItem(mainKey)||'').length,
          lru: lru
        });
      }
    }
    KSBench.endBench('making space for ' + targetSize + ' chars because QUOTA_EXCEEDED end');

    // Sorts the keys with oldest lru time last
    storedKeys.sort(function(a, b) { return (a.lru - b.lru); });

    while (storedKeys.length && targetSize > 0) {
      storedKey = storedKeys.pop();
      removeItemSet(storedKey.key);
      targetSize -= storedKey.size;
    }
    lscache.setBucket(cacheBucketStash);
  }

  function makeSpaceAndRetryOnError(error, key, value, callback) {
    if (error.name === 'QUOTA_EXCEEDED_ERR' || error.name === 'NS_ERROR_DOM_QUOTA_REACHED') {
      // If we exceeded the quota, then we will sort
      // by the lru time, and then remove the oldest ones until
      // the value fits. This ensures that we are storing the 
      // maximum values that will fit.
      var targetSize = (value||'').length;
      
      makeSpaceFor(targetSize);

      try {
        setItem(key, value);
        callback && callback();
      } catch (e) {
        // value may be larger than total quota
        return;
      }
    } else {
      // If it was some other error, just give up.
      return;
    }
  }

  return {

    /**
     * Stores the value in localStorage. Expires after specified number of minutes.
     * If localStorage quota is exceeded, remove least-recently-used (LRU) 
     * items to make space.
     * @param {string} key
     * @param {Object|string} value
     * @param {number} time
     */
    set: function(key, value, time, callback) {
      if (!supportsStorage()) return;

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

      try {
        setItem(key, value);
        touchLru(key);
        // If a time is specified, store expiration info in localStorage
        if (time) {
          setItem(expirationKey(key), (currentTime() + time).toString(EXPIRY_RADIX));
          callback && callback();
        } else {
          // In case they previously set a time, remove that info from localStorage.
          removeItem(expirationKey(key));
        }
      } catch (e) {
        makeSpaceAndRetryOnError(e, key, value, callback);
      }
    },

    /** Naofumi
     * Invalidates a localStorage entry by setting the expiry time
     * to now. If we #get after #invalidate, the entry is removed and null is returned.
     * If we #getDefferingExpiry, we get the old value and the old entry is preserved.
     * We can test if it has expired by #hasCacheExpired.
     * @param {string} key
     */
    invalidate: function(key) {
      // alert('deprecated: for performance, use invalidateKeysByRegex')
      console.log('invalidating ' + key);
      if (getItem(key)) {
        setItem(expirationKey(key), (currentTime()).toString(EXPIRY_RADIX));
      }
    },

    /** Naofumi
    * Invalidates a batch of keys by regex.
    * The invalidation is done by setting the expiration key value to *now*.
    */
    invalidateKeysByRegex: function(regex) {
      var timeNow = currentTime().toString(EXPIRY_RADIX);
      for (var i = 0; i < localStorage.length; i++) {
        storedKey = localStorage.key(i);
        if (storedKey.indexOf(CACHE_PREFIX + cacheBucket) === 0 && !isExpirationKey(storedKey)) {
          var mainKey = storedKey.substr((CACHE_PREFIX + cacheBucket).length);
          if (regex.test(mainKey)) {
            console.log('invalidating ' + storedKey);
            setItem(expirationKey(mainKey), timeNow);
          }
        }
      }
    },

    /** Naofumi
    * Returns All Keys that have not expired, sorted by expiration
    */
    allKeys: function(){
      var keysAndExpiries = [];
      var result = [];
      var timeNow = currentTime();
      for (var i = 0; i < localStorage.length; i++) {
        storedKey = localStorage.key(i);
        if (storedKey.indexOf(CACHE_PREFIX + cacheBucket) === 0 && !isExpirationKey(storedKey)) {
          var mainKey = storedKey.substr((CACHE_PREFIX + cacheBucket).length);
          var exprKey = expirationKey(mainKey);
          var expiration = getItem(exprKey);
          if (timeNow <= parseInt(expiration, EXPIRY_RADIX)) {
            keysAndExpiries.push([mainKey, expiration]);            
          }
        }
      }
      var keysAndExpiriesSortedByExpiration = keysAndExpiries.sort(function(a, b){
                                                return parseInt(a[1], EXPIRY_RADIX) - parseInt(b[1], EXPIRY_RADIX)
                                              });
      for (var i = 0; i < keysAndExpiriesSortedByExpiration.length; i++) {
        result.push(keysAndExpiriesSortedByExpiration[i][0]);
      };
      return result;
    },

    /** Naofumi
     * Gets the current time as formatted for lscache
     */
    currentTime: function() {
      return currentTime();
    },

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
    get: function(key, callback) {
      if (!supportsStorage()) return callback(null, null);

      // Get Expiry data
      var exprKey = expirationKey(key);
      var expr = getItem(exprKey);
      var hasExpired;
      if (expr) {
        var expirationTime = parseInt(expr, EXPIRY_RADIX);

        if (currentTime() >= expirationTime)
          hasExpired = true;
      }

      // Tries to de-serialize stored value if its an object, and returns the normal value otherwise.
      var value = getItem(key);

      if (value) {
        touchLru(key);
      }

      if (!value || !supportsJSON()) {
        callback && callback(value, hasExpired)
        return value;
      }

      try {
        // We can't tell if its JSON or a string, so we try to parse
        callback && callback(JSON.parse(value), hasExpired)
        return JSON.parse(value);
      } catch (e) {
        // If we can't parse, it's probably because it isn't an object
        callback && callback(value, hasExpired)
        return value;
      }
    },

    /**
     * Removes a value from localStorage.
     * Equivalent to 'delete' in memcache, but that's a keyword in JS.
     * @param {string} key
     */
    remove: function(key) {
      if (!supportsStorage()) return null;
      removeItemSet(key);
    },

    /**
     * Returns whether local storage is supported.
     * Currently exposed for testing purposes.
     * @return {boolean}
     */
    supported: function() {
      return supportsStorage();
    },

    /**
     * Flushes all lscache items and expiry markers without affecting rest of localStorage
     */
    flush: function() {
      if (!supportsStorage()) return;

      // Loop in reverse as removing items will change indices of tail
      for (var i = localStorage.length-1; i >= 0 ; --i) {
        var key = localStorage.key(i);
        if (key.indexOf(CACHE_PREFIX + cacheBucket) === 0) {
          localStorage.removeItem(key);
        }
      }
    },
    
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