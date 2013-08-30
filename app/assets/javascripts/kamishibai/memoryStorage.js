// A client-side storage that shares the API with localStorage,
// but stores the values in memory.
//
// When Safari is in private mode, localStorage is 
// unavailable. Then we use memoryStorage instead.
//
// Very hackish right now.
function memoryStorageContructor() {
  var store = {};
  var keys = [];
  this.length = 0
  this.setItem = function(key, value) {
    store[key] = value;
    keys = Object.keys(store);
    this.length = keys.length;
  }
  this.getItem = function(key) {
    return store[key];
  }
  this.removeItem = function(key) {
    if (this.getItem(key) !== null) {
      delete store[key];
      keys = Object.keys(store);
      this.length = keys.length;
    }
  }
  this.key = function(index) {
    return keys[index];
  }
  return this
}

window.memoryStorage = new memoryStorageContructor();
