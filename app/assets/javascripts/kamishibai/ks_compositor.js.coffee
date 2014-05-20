# Displays a DOM element.
#
# Receives a #showElement(toElement) message. Then it
# does the following;
#
# 1. Calculates what part of the DOM needs to be redrawn.
# 2. Prepares the toElement for redrawing if it includes any ancestors.
# 3. Calculates the fromElements (which should be hidden after transition).
# 4. Delegates the transition to KSEffect.
# 5. Cleans up after the transition, removing any excess nodes and scrolling
#    to appropriate position.
# 6. Sets the title.
#
# In essence, KSCompositor prepares the DOM, transitions with KSEffect,
# and cleans up the DOM afterwards.
#
# It does not construct the DOM. It only affects visibility and display.
#
# ## toElement must be hidden
#
# When sending the toElement to KSEffect, toElement must be hidden.
# We do that during KSDom.insertIntoDom for container children and pages.

KSCompositorConstructor = () ->

  # Set each element in array to 'show'. 
  showAll = (elements) ->
    for element in elements
      kss.show(element)
  # If it is an element inside a container
  # as determined by the presence of 'data-container', then hide siblings so
  # that the element is the only one in the container that is shown.
  trimVisibilityWithinContainersToSingleChild = (elements) ->
    for element in elements
      if element.hasAttribute('data-container')
        for sibling in kss.siblings(element)
          sibling.style.display = "none"


  # If the toElement has ancestors that are not currently displayed,
  # the the transition has to happen so that all of these ancestors
  # are displayed. We do this by recalculating the toElement to the
  # highest hidden ancestor and making sure that the path from there
  # to the original toElement is "shown".
  returnHighestHiddenAncestorAndShowDescendants = (toElement) ->
    # eldest ancestor last, direct parent second, toElement first
    hiddenAncestors = kss.parentsUntilVisible(toElement)
    hiddenAncestorsExceptEldest = hiddenAncestors.slice(0, -1)

    if hiddenAncestors.length > 0
      showAll hiddenAncestorsExceptEldest 
      trimVisibilityWithinContainersToSingleChild hiddenAncestorsExceptEldest.concat([toElement])
      newToElement = kss.last hiddenAncestors
      console.log("newToElement recalculated to id: " + newToElement.id);
      # When switching the toElement, show old one so that it will 
      # automatically display during transition.
      kss.show(toElement) 
      return newToElement
    else
      return toElement

  # Calculate the fromElements, which are basically 
  # siblings of the toElement which are DIV tags.
  calculateFromElements = (toElement) ->
    if kss.hasClass(toElement, 'page')
      # Since we must allow elements other than pages as direct children of 'body',
      # we have to select only '.page' elements.      
      filter = (node) ->
                      kss.hasClass(node, 'page') && 
                      node.id isnt 'splashscreen'
    else
      # For sub-elements, all visible siblings of the toElement are fromElements.
      # We don't need to filter.
      filter = (node) -> true
    kss.siblings toElement, (node) ->
      node.tagName is 'DIV' &&
      kss.isVisible(node) &&
      filter(node)

  # For console log message
  stringOfIdsFromElements = (elements) ->
    elements.map (obj) ->
      obj.tagName + "#" + obj.id
    .join(', ')

  doTransition = (toElement, fromElements, animate, callback) ->
    if animate
      transition = KSTransitionSelector.transition(toElement, fromElements)
      transition.effect.apply(transition.effect, 
                              [fromElements, toElement, transition.backwards, callback])
    else
      kss.show toElement
      for fromElement in fromElements
        kss.hide fromElement
      callback and callback();

  # We remove nodes that are unnecessary for the current display
  # after a transition is finished.
  # 
  # The criteria for removing nodes is as follows (all must apply);
  # 1. The node has a data-ks_loaded attribute, which indicates
  #    that it was loaded via Ajax and is not a part of the bootloader.
  # 2. The node comes from a different resource URL than the current URL.
  #    We probably don't need this restriction.
  # 3. Is not a decendant of toElement.
  # 4. Is currently invisible.
  removeUnecessaryNodes = (toElement) ->
    allLoadedElements = Array.prototype.slice.call(document.querySelectorAll('[data-ks_loaded]'))
    allLoadedDescendantsOfToElement = Array.prototype.slice.call(toElement.querySelectorAll('[data-ks_loaded]'))
    for nodeToRemove in allLoadedElements
      if nodeToRemove isnt toElement && 
         nodeComesFromDifferentResourceUrl(toElement, nodeToRemove) && 
         isNotIncludedIn(allLoadedDescendantsOfToElement, nodeToRemove) &&
         !kss.isVisible(nodeToRemove)
           console.log('remove element id: ' + nodeToRemove.id + ' following transition');
           nodeToRemove.parentNode && nodeToRemove.parentNode.removeChild(nodeToRemove)

  nodeComesFromDifferentResourceUrl = (toElement, nodeToRemove) ->
    nodeToRemove.getAttribute('data-ajax') isnt toElement.getAttribute('data-ajax')

  isNotIncludedIn = (allLoadedDescendantsOfToElement, nodeToRemove) ->
    allLoadedDescendantsOfToElement.indexOf(nodeToRemove) == -1

  # Do stuff after showElement including;
  # 1. Hide location bar by scrolling 1px down.
  # 2. Scroll back to previous scroll position.
  # 3. Highlight previous click.
  # 4. Reset transition selector.
  # 5. Remove unnecessary nodes from DOM
  cleanUpAfterShowElement = (toElement, callback) ->
    # Removed timeout because on iPhone 4,
    # you could see it scroll up and then back down
    # and it was slow.
    KSPageState.revert()
    # setTimeout -> 
    #   KSPageState.revert()
    # , 0
    KSTransitionSelector.resetEffect();
    removeUnecessaryNodes(toElement)
    callback && callback();

  # Shows the toElement.
  # This is the public interface for the KSCompositor object.
  #
  # Returns the highestHiddenAncestor of the toElement, which
  # is equal to the portion of the screen that will be redrawn (redrawArea).
  showElement = (toElement, animate, callback) ->
    animate = true if typeof(animate) is 'undefined'
    console.log("showElement with id: #{toElement.id} animate #{animate}")
    console.log("FIRE beforeshow");
    kss.sendEvent('ks:beforeshow', toElement, {animate: animate});

    originalTarget = toElement
    toElement = returnHighestHiddenAncestorAndShowDescendants(originalTarget)
    fromElements = calculateFromElements(toElement)

    console.log "from Element are ids: " + stringOfIdsFromElements(fromElements)

    doTransition toElement, fromElements, animate, ->
      cleanUpAfterShowElement(toElement, callback)

    setTitle(originalTarget)
    KSHistory.push() # This shouldn't be here because History is independent from DOM
    kss.sendEvent('ks:aftershown', toElement, {toElement: toElement})

    return toElement;

  setTitle = (toElement) ->
    titleElement = kss.closest( toElement, 
                                (e) -> 
                                  return e.hasAttribute && e.hasAttribute('data-title')
                                , true);
    if !titleElement
      alert('No element with data-title attribute found for current page')
      return
    title = titleElement.getAttribute('data-title');
    document.title = title;

  # Public Interface
  this.showElement = showElement
  return this

window.KSCompositor = new KSCompositorConstructor()