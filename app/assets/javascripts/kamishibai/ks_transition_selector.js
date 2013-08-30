// This object selects the animation used for transitioning pages and the direction.
// The direction is especially complex.
//
// We use the following scheme so that the necessary information is embedded in the DOM.
//
// Defaults;
// 1.  If there is no fromElement (i.e. a reload), then we use effectWhenNoFromElements.
// 2.  Unless the DOM specifies otherwise, we use the page viewing history KSHistory to
//     to determine forward vs. backward. We apply KSEffect.cssSlide with the determined
//     direction.
//
// Specifying in the DOM
// 1.  The effect and direction can be specified in the toElement with 'data-animation' and
//     'data-backwards. 
//     Note that we don't specify in the link, but in the toElement.
// 2.  We can also specify a collection of DOM elements. The order of the DOM elements
//     will tell us what the animation direction will be. This is explained below.
//
// A collection of DOM elements
// Suppose we have a collection of tabs that we use to transition between pages.
// Each of the tabs will contain a link. The link is used to transition to a page
// and select a toElement. The link may be a ID style or resourceUrl style.
// We collect the links in the tab set and compare their "href" attribute and
// their "data-target-element" attribute (if set) with both the id and the data-ajax
// attribute of the toElement and fromElement. Assuming that the collection of the DOM
// elements describes the order in which the elements appear in the DOM, and in which
// they are displayed, we can use this to calculate direction.
window.KSTransitionSelector = function(){
  // TODO: Make this configurable.
  var effectWhenNoFromElements = {effect: KSEffect.noEffect};
  // var effectWhenNoFromElements = {effect: KSEffect.cssPulse};
  // These values may be set in the link click event handler.
  // var defaultEffect = KSEffect.cssSlide;
  var defaultEffect = KSEffect.noEffect;
  var effect = defaultEffect;
  var backwards = null;

  function resetEffect() {
    effect = defaultEffect;
    backwards = null;
  }

  function identicalExceptForLocale(){
    var referrer = KSHistory.latestId();
    var current = document.location.href;
    // current = current.replace(/#.*$/, '');
    var localeRegexp = /\/(en|ja)/g
    if (referrer && referrer !== current && 
        (referrer.replace(localeRegexp, '') == current.replace(localeRegexp, ''))) {
      return true;
    } else {
      return false;
    }
  }

  function transition(toElement, fromElements) {
    var result = {};

    if (!fromElements[0]) {
      if (identicalExceptForLocale()) {
        result = {effect: KSEffect.horizontalFlip};
      } else {
        result = effectWhenNoFromElements;
      }
    } else {
      result.effect = effect;
      if (backwards === null) {
        // We used to do elaborate calculations but now we simply
        // set the position in the data-position attribute.
        // Of course, we can optionally set the attributes on the link.
        var comparison = comparePosition(fromElements[0], toElement);
        if (comparison == 0) {
          result.backwards = KSHistory.isBackwards();
        } else {
          result.backwards = (comparison == -1);
        }        
      } else {
        result.backwards = backwards;
      }
    }

    console.log("selecting transition effect: " + result.effect.name + 
                " backwards: " + result.backwards +
                " for toElement: " + toElement.id + " fromElement: " + (fromElements[0] && fromElements[0].id));
    return result;
  }

  function comparePosition(a, b) {
    var posA = a.getAttribute('data-position');
    var posB = b.getAttribute('data-position');
    if (posA === null || posB === null) return 0;
    return posB > posA ? 1 : 
          (posB == posA ? 0 : -1);
  }

  function setAnimation(animation) {
    if (animation) {
      if (!KSEffect[animation]) 
        alert('Effect "' + animation + '" not defined in KSEffect.');
      effect = KSEffect[animation];
      console.log('set animation to ' + animation + ' from link.');
    } else {
      effect = defaultEffect;
    }
  }

  function setAnimationFromElement(element) {
    if (!element) return;
    setAnimation(element.getAttribute('data-animation'));
  }

  // set 
  function setBackwards(boolean) {
    if (boolean !== null) {
      if (boolean == "true") {
        backwards = true;
      } else {
        backwards = false;
      }
      console.log('set backwards to ' + backwards + ' from link.');      
    } else {
      backwards = null;
    }
  }

  function setDirectionFromElement(element) {
    if (!element) return;
    setBackwards(element.getAttribute('data-backwards'));
  }

  function setAnimationAndDirectionFromElement(element){
    setAnimationFromElement(element);
    setDirectionFromElement(element);
  }

  return {
    effectWhenNoFromElements: effectWhenNoFromElements,
    setAnimationAndDirectionFromElement: setAnimationAndDirectionFromElement,
    transition: transition,
    resetEffect: resetEffect,
    setBackwards: setBackwards,
    setAnimation: setAnimation
  }
}();