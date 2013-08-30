window.kss = new KSSupport();

function KSSupport() {
	var self = this;
	// Initialize and send an event
	// bubble, no cancel
	this.sendEvent = function (type, node, properties, bubbles, cancelable) {
    if (bubbles === undefined)
      bubbles = true
    if (cancelable === undefined)
      cancelable = false

    if (node) {
      var event = document.createEvent("UIEvent");
      event.initEvent(type, bubbles, cancelable);
      if (properties) {
        for (p in properties){
          event[p] = properties[p];
        }
      }
      node.dispatchEvent(event);
    }
  }

  // https://developer.mozilla.org/en-US/docs/DOM/element.addEventListener
  // TODO: We'll probably start deprecating IE specific stuff
  //       and put those in a different file. We want to keep
  //       standard compliant stuff lean.
  this.addEventListener = function(element, type, listener) {
  	if (element.addEventListener) {
  	  element.addEventListener(type, listener, false); 
  	}
  }

  this.addEventListenerFilteringByClass = function(element, type, className, listener) {
    self.addEventListener(element, type, function(event){
      var target = event.target && kss.closestByClass(event.target, className, true);
      if (target) {
        listener(event, target);
      }
    });
  }

  this.addEventListenerFilteringByTagName = function(element, type, tagName, listener) {
    self.addEventListener(element, type, function(event){
      var target = event.target && kss.closestByTagName(event.target, tagName, true);
      if (target) {
        listener(event, target);
      }
    });
  }


  this.parents = function(element, filter) {
  	var e = element,
  	    result = [];
  	while (e = self.closest(e, filter)) {
  		result.push(e);
  	}
  	return result;
  }

  this.parentsById = function(element, id, includeSelf) {
  	return self.parents(element, function(e){return e.id === id});
  }

  // Gets the closest parent that returns true in the 
  // filter. Or the absolute closest parent if the filter is
  // not specified. Starts from this element if includeSelf is true.
  this.closest = function(element, filter, includeSelf) {
    if (typeof element == "string") alert('first argument of kss.closest must be Node');
  	var e = element;
    if (!e) return null;
    e = includeSelf ? e : element.parentNode;
  	while (e) {
  		if (typeof(filter) === 'undefined' || filter(e)) {
  			return e;
  		}
      e = e.parentNode;
  	}
  	return null;
  }

  this.closestById = function(element, id, includeSelf) {
  	return self.closest(element, 
                        function(e){return e.id === id},
                        includeSelf);
  }

  this.closestByClass = function(element, className, includeSelf) {
    return self.closest(element, 
                        function(e){return kss.hasClass(e, className)},
                        includeSelf); 
  }

  this.closestByTagName = function(element, tagName, includeSelf) {
    return self.closest(element, 
                        function(e){return e.tagName == tagName.toUpperCase()},
                        includeSelf);
  }

  this.closestByName = function(element, name, includeSelf) {
    return self.closest(element, 
                        function(e){return e.name == name},
                        includeSelf);
  }

  // eldest ancestor last, direct parent first
  // none of the elements should be visible
  this.parentsUntilVisible = function(element){
  	var e = element,
  	    result = []
  	while (e = e.parentNode) {
  		if (!self.isVisible(e)) {
  			result.push(e);
  		} else {
  			break;
  		}
  	}
  	return result;
  }

  this.isVisible = function(element){
  	// In IE <=8, this won't work with tables, but who gives a damn!
  	// It might also be helpfull to check the computed style (getComputedStyle) for display
  	return !(element.offsetWidth === 0 && element.offsetHeight === 0);
  }

  // This simply removes any display:none
  // styles. The stylesheet is not observerd.
  // Force=true will show even if hidden in CSS file.
  this.show = function(element, force){
		if (element.style.display === 'none') {
			element.style.display = "";
		}
    if (force && element.style.display !== 'block') {
      element.style.display = "block";
    }
  }

  this.hide = function(element){
    if (element.style.display !== 'none') {
      element.style.display = "none";
    }
  }

  this.toggle = function(element, force){
    if (this.isVisible(element)) {
      this.hide(element);
    } else {
      this.show(element, force);
    }
  }

  // filter function should return true if we
  // want to include it.
  this.siblings = function(element, filter) {
  	var parent = element.parentNode;
		var result = [];
		var n = parent.firstChild;

		for ( ; n; n = n.nextSibling ) {
			if ( n.nodeType === 1 && n !== element ) {
				if ((typeof(filter) === 'function') && !filter(n)) {
				} else {
					result.push(n);
				}
			}
		}
		return result;
  }

  this.next = function(element) {
    return element.nextElementSibling;
  }

  this.hasClass = function(element, className) {
    return (" " + element.className + " ").replace(/[\t\n\r]/, " ").
           indexOf( " " + className + " " ) > -1 
  }

  this.addClass = function(element, name) {
    if (!self.hasClass(element, name)){
      element.setAttribute("class", 
            [element.className, name].join(' '));
    }
  }

  this.removeClass = function(element, name) {
    if (self.hasClass(element, name)) {
      var newClassName = kss.trim((" " + element.className + " ").
                          replace(/[\t\n\r]/, " ").replace(" " + name + " ", ' '));
      element.setAttribute("class", newClassName);
    }
  }

  this.toggleClass = function(element, name) {
    if (self.hasClass(element, name)) {
      self.removeClass(element, name);
    } else {
      self.addClass(element, name);
    }
  }

  // http://blog.stevenlevithan.com/archives/faster-trim-javascript
  this.trim = function(str) {
  	var result;
  	if (String.prototype.trim) {
  		result = str.trim(str);
  	} else {
  		result = str.replace(/^\s\s*/, '').replace(/\s\s*$/, '');
  	}
  	return ((result === null) ? "" : result);
  }

  // Redirect. Used from Rails controllers in response to an update or create
  // for POST-to-redirect CRUD patterns. Only reads the hash fragment.
  this.redirect = function(hash) {
    var currentHash = location.hash.replace(/^#/, '');
    var newHash = hash.replace(/^#/, '');
    if (currentHash == newHash) {
      // Send a request even if the hash hasn't changed.
      kss.sendEvent('hashchange', window);
    } else {
      // http://stackoverflow.com/questions/2305069/can-you-use-hash-navigation-without-affecting-history
      location.replace("#" + newHash);       
      // location.hash = newHash;
    }
  }

  // Uniquify an array
  this.uniquify = function(array) {
    var result = [];
    var l = array.length;
    for (var i = 0; i < l; i++) {
      for(var j = i + 1; j < l; j++) {
        // If we find a match, we skip the i
        // and do anothor round with a freshly initialized j.
        if (array[i] === array[j])
          j = ++i;
      }
      result.push(array[i]);
    };
    return result;
  }

  this.last = function(array) {
    return array[array.length - 1]
  }

  // Escape RegExp special characters
  // http://simonwillison.net/2006/Jan/20/escape/
  this.escapeForRegExp = function(string) {
    return string.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&")
  }

  // http://ivan-gandhi.livejournal.com/942493.html
  this.stacktrace = function() {
    function st2(f) {
      if (f) {
        var args = Array.slice(f.arguments);
        return st2(f.caller).concat([f.toString().split('(')[0].substring(9) + '(' + args.join(',') + ')']);      
      } else {
        return []
      }
    }
    return st2(arguments.callee.caller);
  }

  this.arrayOfElements = function(size, element) {
    result = [];
    for (var i = 0; i < size; i++) {
      result.push(element);
    };
    return result;
  }

}