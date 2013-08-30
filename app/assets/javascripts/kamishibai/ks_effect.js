// This is a collection of Transition effects.
// All effects receive the following parameters.
// (fromElements, toElement, backwards, callback)
//
// The toElement should always be hidden before calling
// KSEffect.

var KSEffect = new KSEffect();
function KSEffect () {
  function setStyleStashingOriginal(element, styleKey, value){
    var current_value = element.style[styleKey];
    element.setAttribute('data-stash-' + styleKey, current_value);
    element.style[styleKey] = value;
  }

  function resetStyleFromStash(element, styleKey) {
    var stashValue = element.getAttribute('data-stash-' + styleKey);
    element.style[styleKey] = stashValue;
    element.removeAttribute('data-stash-' + styleKey);
  }

  function resetAllStylesFromStash(element) {
    var allAttributes = element.attributes;
    for (var i = 0; i < allAttributes.length; i++) {
      var attr = allAttributes[i]
      if (attr.name.indexOf('data-stash-') == 0) {
        var styleKey = attr.name.slice(11);
        resetStyleFromStash(element, styleKey);
      }
    };
  }

  this.noEffect = function(fromElements, toElement, backwards, callback) {
    toElement.style.display = 'block';

    for (var i = 0; i < fromElements.length; i++) {
      fromElements[i].style.display = 'none';
    }

    if (callback) callback();
  }

  this.cssGlow = function(fromElements, toElement, backwards, callback) {
    toElement.style.display = 'block';

    for (var i = 0; i < fromElements.length; i++) {
      fromElements[i].style.display = 'none';
    }

    kss.addClass(toElement, 'css_glow_transition')

    if (callback) callback();
  }


  this.cssSlide = function (fromElements, toElement, backwards, callback) {
    // Hide the toElement as soon as possible.
    // Safari is OK, but Firefox seems to be slow to prepare and the
    // toElement gets in the way.
    toElement.style.display = 'none'; 
    var slideTransitionDuration = '400ms';
    var slideTimingFunction = 'ease';
    var width = 0;
    var fromElementsHeight = 0;

    // Calculate the width of the fromElements so we know how much
    // distance we need to slide.
    for (var i = 0; i < fromElements.length; i++) {
      var thisWidth = Math.min(fromElements[i].scrollWidth, window.innerWidth);
      width = Math.max(width, thisWidth);
    };

    // Calculate the max height of the fromElements so we know how much
    // distance we need to slide.
    for (var i = 0; i < fromElements.length; i++) {
      var fromElement = fromElements[i];
      var thisHeight = fromElement.offsetTop + fromElement.scrollHeight;
      fromElementsHeight = Math.max(fromElementsHeight, thisHeight);
    };

    // Now we know what the transformation CSS should look like
    // toStart is what we do to place the toElement in the start position.
    var toStart = 'translateX(' + (backwards ? '-' : '') + width +  'px)';
    // fromEnd is where the fromElements end up.
    var fromEnd = 'translateX(' + (backwards ? '' : '-') + width + 'px)';

    // Prepare parentNode

    // If the toElement is a sub-page, we have to set the parentNode
    // so that it will hide the toElement when it flows out.
    // To do this, we use overflow: 'hidden'. However, since the 
    // sub-pages will have position:absolute, the parentNode most
    // likely will have zero height and therefore will hide the
    // fromElement.
    // To fix this, we set the min-height of the parentNode to fit
    // the toElement.

    // This can cause flicker so turn on only if we really need it.
    // We only need it when we are not transitioning on a page element.
    if (!kss.hasClass(toElement, 'page')) {
      // toElement.parentNode.style.minHeight = Math.max((toElement.offsetTop + toElement.scrollHeight), toElement.parentNode.scrollHeight) + 'px';
      toElement.parentNode.style.minHeight = Math.max(toElement.parentNode.scrollHeight,
                                                          (toElement.offsetTop + toElement.scrollHeight),
                                                          fromElementsHeight
                                                         ) + 'px';
      toElement.parentNode.style.overflow = 'hidden';
      toElement.parentNode.style.position = 'relative';
    }


    // ** Prepare toElement **
    // Crop to fit size of the container
    // toElement.style.overflow = 'hidden'; 
    // hiding seems to cause flicker. Still investigating.
    toElement.style.overflow = 'visible';
    // We're going to move toElement to the start position.
    // Set duration to 0 so this happens instantly.
    setStyleWithVendorPrefix(toElement, {
      transitionDuration: '0ms',
      // http://stackoverflow.com/questions/3683211/ipad-safari-mobile-seems-to-ignore-z-indexing-position-for-html5-video-elements
      transformStyle: "preserve-3d"
    })

    setStyleWithVendorPrefix(toElement, {
      // Move the toElement to the start Position
      transform: toStart,
      // Prime the toElement for transition
      transitionDuration: slideTransitionDuration,
      transitionTimingFunction: slideTimingFunction
    })

    // ** Prepare fromElements **
    for (var i = 0; i < fromElements.length; i++) {
      // Crop to fit size of the container
      fromElements[i].style.overflow = 'hidden';
      setStyleWithVendorPrefix(fromElements[i], {
        transitionDuration: slideTransitionDuration,
        transitionTimingFunction: slideTimingFunction
      })
      var thisWidth = Math.min(fromElements[i].offsetWidth, window.innerWidth);
      // Get the width of the fattest fromElement and put it into width.
      // TODO: Refactor!!
      width = Math.max(width, thisWidth);
    };

    function startTrans() {
      // Pull the trigger for fromElements
      for (var i = 0; i < fromElements.length; i++) {
        setStyleWithVendorPrefix(fromElements[i], {
          transform: fromEnd,
          // perspective: '1000',
          backfaceVisibility: 'hidden'
        })
      }
      // Pull the trigger for toElement
      setStyleWithVendorPrefix(toElement,{
        transform: 'translateX(0%)', //toEnd
        // perspective: '1000',
        backfaceVisibility: 'hidden'
      })
    }

    // Clean up after transition
    function resetElements(){
      toElement.style.overflow = '';
      setStyleWithVendorPrefix(toElement, {
        transitionDuration: '0ms',
        transform: '',
        // backfaceVisibility: '',
        transformOrigin: ''
      })
      setStyleWithVendorPrefix(toElement.parentNode, {
        transitionDuration: '0ms'
      })
      toElement.parentNode.style.height = '';
      toElement.parentNode.style.overflow = '';
      for (var i = 0; i < fromElements.length; i++) {
        fromElements[i].style.overflow = '';
        fromElements[i].style.display = 'none';
        setStyleWithVendorPrefix(fromElements[i], {
          transitionDuration: '0ms',
          transformOrigin: '',
          transform: ''
          // backfaceVisibility: ''
        })
      }
      toElement.removeEventListener('webkitTransitionEnd', resetElements);
      toElement.removeEventListener('transitionend', resetElements);
    }

    // Support other browsers http://stackoverflow.com/questions/2794148/css3-transition-events
    function newCallback() {
      toElement.removeEventListener('webkitTransitionEnd', newCallback, false);
      toElement.removeEventListener('transitionend', newCallback, false);
      callback && callback();
    }

    toElement.addEventListener('webkitTransitionEnd', resetElements, false);
    toElement.addEventListener('webkitTransitionEnd', newCallback, false);
    toElement.addEventListener('transitionend', resetElements, false);
    toElement.addEventListener('transitionend', newCallback, false);

    // Show the toElement
    toElement.style.display = 'block';

    // And pull the master trigger.
    setTimeout(startTrans, 0);
  }

  this.cssPulse = function (fromElements, toElement, backwards, callback) {
    function startTrans(){
      kss.addClass(toElement, "css_pulse_transition");
      for (var i = 0; i < fromElements.length; i++) {
        fromElements[i].style.display = 'none';
      }
    }

    function resetElements(){
      kss.removeClass(toElement, "css_pulse_transition");
      toElement.removeEventListener('webkitAnimationEnd', resetElements);
      toElement.removeEventListener('animationend', resetElements);
    }

    toElement.addEventListener('webkitAnimationEnd', resetElements, false);
    toElement.addEventListener('animationend', resetElements, false);

    // Show the toElement
    toElement.style.display = 'block';
    // And pull the master trigger.
    setTimeout(startTrans, 0);
  }

  // DEPRECATED: We should rewrite this like we do for cssPulse
  this.cssPop = function (fromElements, toElement, backwards, callback) {
  	// TODO: display all fromElements in log
  	console.log('pop animation fromElement: ' + (fromElements[0] && fromElements[0].id) + ' toElement: ' + toElement.id);
  	toElement.style.display = 'none';

    // ** Prepare to Element **

    // Safari has an issue where the initial scale is used to calculate the scrollbars.
    // Hence if there are no scrollbars at the initial scale and then at the final scale
    // we need scrollbars because the element doesn't fit the viewport, we still don't
    // get scrollbars and cannot scroll. 
    // We work around this by first setting the height to a very large value (higher than
    // any display), doing the transitions, and then resetting the height.
    toElement.style.height = "3000px";

  	setStyleWithVendorPrefix(toElement, {
  		transitionDuration: '0ms',
  		transformOrigin: "50% 0%",
  		transform: 'scale(0.9)',
      // perspective: '1000',
      // backfaceVisibility: 'hidden'  		
  	})

  	function startTrans(){
  		setStyleWithVendorPrefix(toElement,{
  			transitionDuration: '300ms',
  			transform: 'scale(1.0)'
  		})
  		for (var i = 0; i < fromElements.length; i++) {
	      fromElements[i].style.display = 'none';
	    }
  	}

    function resetElements(){
      toElement.style.overflow = '';
      toElement.style.height = '';
      setStyleWithVendorPrefix(toElement, {
        transitionDuration: '0ms',
        transformOrigin: '',
        transform: ''
        // backfaceVisibility: ''
      })
      toElement.style.position = '';
      for (var i = 0; i < fromElements.length; i++) {
        setStyleWithVendorPrefix(fromElements[i], {
          transitionDuration: '0ms',
          transformOrigin: '',
          transform: ''
          // backfaceVisibility: ''
        })
        fromElements[i].style.overflow = '';
        fromElements[i].style.display = 'none';
      }
      toElement.removeEventListener('webkitTransitionEnd', resetElements);
      toElement.removeEventListener('transitionend', resetElements);
    }

    toElement.addEventListener('webkitTransitionEnd', resetElements, false);
    toElement.addEventListener('transitionend', resetElements, false);

    // Show the toElement
    toElement.style.display = 'block';
    // And pull the master trigger.
  	setTimeout(startTrans, 0);
  }

  this.horizontalFlip = function(fromElements, toElement, backwards, callback) {
    console.log('flip animation fromElement: ' + (fromElements[0] && fromElements[0].id) + ' toElement: ' + toElement.id);
    kss.show(toElement);
    setStyleWithVendorPrefix(document.body, {
      transformOrigin: "50% 30%",
      transitionDuration: '0ms',
      perspective:"2000px"
    })
    setStyleWithVendorPrefix(toElement, {
      transformOrigin: "50% 0%",
      transitionDuration: '0ms',
      backfaceVisibility: 'hidden',
      transform: 'rotateY(180deg)',
    });
    setStyleWithVendorPrefix(fromElements[0], {
      transitionDuration: '0ms',
      backfaceVisibility: 'hidden'
    });

    function startTrans(){
      kss.show(toElement);
      setStyleWithVendorPrefix(toElement, {
        transitionDuration: '750ms',
        transform: 'rotateY(0deg)',
      });

      setStyleWithVendorPrefix(fromElements[0], {
        transitionDuration: '750ms',
        transform: 'rotateY(-180deg)',
      });
    }

    function resetElements(){
      setStyleWithVendorPrefix(toElement, {
        transitionDuration: '0ms',
        transformOrigin: '',
        transform: ''
        // backfaceVisibility: ''
      })
      toElement.style.overflow = '';
      for (var i = 0; i < fromElements.length; i++) {
        setStyleWithVendorPrefix(fromElements[i], {
          transitionDuration: '0ms',
          transformOrigin: '',
          transform: ''
          // backfaceVisibility: ''
        })
        fromElements[i].style.overflow = '';
        fromElements[i].style.display = 'none';
      }
      toElement.removeEventListener('webkitTransitionEnd', resetElements);
      toElement.removeEventListener('transitionend', resetElements);
    }

    function newCallback() {
      toElement.removeEventListener('webkitTransitionEnd', newCallback, false);
      toElement.removeEventListener('transitionend', newCallback, false);
      callback();
    }

    toElement.addEventListener('webkitTransitionEnd', resetElements, false);
    toElement.addEventListener('webkitTransitionEnd', newCallback, false);
    toElement.addEventListener('transitionend', resetElements, false);
    toElement.addEventListener('transitionend', newCallback, false);

    setTimeout(startTrans, 0);
  }

  function setStyleWithVendorPrefix(element, styleValueSet) {
    if (!element) return;
  	var prefixes = ['webkit', 'Moz'];
  	for (var styleName in styleValueSet) {
  		for (i = 0; i < prefixes.length; i++) {
  			var capitalizedStyleName = styleName.slice(0,1).toUpperCase() + styleName.slice(1);
  			element.style[prefixes[i] + capitalizedStyleName] = styleValueSet[styleName];
  		}
  		element.style[styleName] = styleValueSet[styleName];
  	}
  }

  // Make function public
  this.setStyleWithVendorPrefix = setStyleWithVendorPrefix;
}