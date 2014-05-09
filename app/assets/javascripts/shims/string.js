if(!String.prototype.trim) {
  // http://blog.stevenlevithan.com/archives/faster-trim-javascript
  String.prototype.trim = function () {
    return this.replace(/^\s\s*/, '').replace(/\s\s*$/, '');
  };
}
