// Generic event handlers

// TODO: We should move each group of event listeners to their own file.
kamishibai.beforeInitialize(function(){

  kss.addEventListener(document, 'click', function(event) {
    var target = event.target && kss.closestByTagName(event.target, 'a', true);
    if (target) {
      KSTransitionSelector.setAnimationAndDirectionFromElement(target);
      KSScrollMemory.set({clicked: target.getAttribute('href')});
    }

    if (target && target.hasAttribute('data-ks_animate')) {
      KSCompositor.showElement(target.getAttribute('data-ks_animate'), true);
      event.preventDefault();
      event.stopPropagation();
    }

  })

  //// UI WIDGETS //////////////
  // Kamishibai does not provide ready made widgets.
  // Instead, we provide libraries that help designers create their
  // own widgets.

  ///// Menu selection ////

  // Radio buttons
  // To make a set of siblings into a set of radio buttons,
  // simply set the parent element's class to 'radio_button_set'.
  // Then only the clicked button will be selected. All the others
  // will be non-selected.

  // This exclusively selects a child and unselects siblings.
  function exclusiveSelect(target) {
    if (target) {
      kss.addClass(target, 'selected');
      var siblings = kss.siblings(target);
      for (var i = 0; i < siblings.length; i++) {
        kss.removeClass(siblings[i], 'selected');
      };      
    }
  }

  // Select the button (the element which we set the 'selected' class on)
  // for an anchor. 
  // Often times, the button is not the <a> tag itself but is an element
  // that surrounds the <a> tag and provides padding, borders, images, etc.
  // Often the button is a <li> tag inside a <ul> or <ol>.
  // The anchor does not necessarily have to be a <a> tag. It can be
  // anything that is inside the button.
  // The button can be the anchor itself.
  function buttonForAnchor(anchor) {
    return kss.closest(anchor, 
                        function(e){ 
                          if (e.parentNode){
                            return kss.hasClass(e.parentNode, 'radio_button_set')
                          } else {
                            return false;
                          }
                        }, true)
  }

  kss.addEventListener(document, 'click', function(event){
    var link = event.target && kss.closestByTagName(event.target, 'a', true);
    var button;
    if (link && (button = buttonForAnchor(link))) {
      exclusiveSelect(button);
    }
  })



  // Set selected based on location.hash
  // We want to select elements that are radio buttons sets.
  // The only information we have at this point is the hash. We want to select
  // menus if they are ancestors of the hash target.
  // For menus where we can't simply deduce the selection from the hash,
  // we use the toElement to set the menu.
  //
  // The idea is to select a menu item based on 
  // 1.  The data-menu attribute on any visible children of the toElement.
  // 2.  The current location.hash.
  //
  // Since the current location.hash does not have much information and
  // hierarchy is not apparent, the second approach is only for when
  // the designer is lazy. We generally rely on the first approach.
  //
  // Since the menu system might be several hierarchies deep and the data-menu
  // might be set on sub-elements (not only the .page element), we search into
  // all the decendants of the toElement to find 'data-menu' attributes.
  // Elements that are deeper in the DOM (are returned later by querySelectorAll)
  // take precedence.
  //
  // The menus themselves might be anywhere in the DOM, so we search the whole
  // page for menus.
  kss.addEventListener(document, 'ks:beforeshow', function(event) {
    KSBench.startBench('menu selector start');
    var toElement = event.target;
    var page = kss.closestByClass(toElement, 'page', true);

    allMenuClasses = getMenuClassesFromDecendantsAndSelf(toElement);

    selectMenusWithClassesWithinPage(allMenuClasses, page);

    selectButtonsWithinPageCorrespondingToCurrentLocationHash(page);

    KSBench.endBench('menu selector end');

  })

  function selectButtonsWithinPageCorrespondingToCurrentLocationHash(page) {
    // var hash = location.hash;
    // var linksToHash = page.querySelectorAll("[href='" + hash + "'], [data-href='" + hash + "']");
    // selectButtonsForAnchors(linksToHash);    
  }

  function selectButtonsForAnchors(anchors) {
    for (var i = 0; i < anchors.length; i++) {
      var button = buttonForAnchor(anchors[i]);
      exclusiveSelect(button);
    };
  }

  function selectMenusWithClassesWithinPage(allMenuClasses, page) {
    for (var i = 0; i < allMenuClasses.length; i++) {
      var menuClass = allMenuClasses[i];
      var links;
      if (links = page.querySelectorAll('.' + menuClass)) {
        selectButtonsForAnchors(links);
      }
    }  
  }

  function getMenuClassesFromDecendantsAndSelf(element){
    var dataMenus = element.querySelectorAll("[data-menu]");
    var allMenuClasses = [];
    if (element.hasAttribute('data-menu')) {
      var menuString = element.getAttribute('data-menu');
      var menuClasses = menuString ? menuString.split(' ') : [];
      for (var j = 0; j < menuClasses.length; j++) {
        allMenuClasses.push(menuClasses[j]);
      }
    }
    for (var i = 0; i < dataMenus.length; i++) {
      if (kss.isVisible(dataMenus[i])) {
        var menuString = dataMenus[i].getAttribute('data-menu');
        var menuClasses = menuString ? menuString.split() : [];
        for (var j = 0; j < menuClasses.length; j++) {
          allMenuClasses.push(menuClasses[j]);
        }        
      }
    };

    allMenuClasses = kss.uniquify(allMenuClasses);
    return allMenuClasses;
  }

  // Cancel after clicked indicator transition
  kss.addEventListener(document, 'webkitAnimationEnd', function(event){
    var target = event.target;
    if (kss.hasClass(target, 'was_clicked_indicator')) {
      kss.removeClass(target, 'was_clicked_indicator');
    }
  })

  // With regular links, if you click on a link that is identical
  // to the current location, the window is reloaded.
  // However with regards to the hashchange event, if the
  // hash on that link is the same as the one in the current location,
  // a hashchange event will not fire. The following fixes this
  // and fires a hashchange if it was a Kamishibai link.
  kss.addEventListener(document, 'click', function(event){
    var target = kss.closestByTagName(event.target, 'A', true);
    if (target) {
      var href = target.getAttribute('href');
      // We ignore hrefs that aren't hash only.
      if (href.indexOf('#!') == 0) {
        var currentHash = location.hash.replace(/^#/, '');
        var newHash = href.replace(/^#/, '');
        if (currentHash == newHash) {
          // Send a hashchange even if the hash hasn't changed.
          kss.sendEvent('hashchange', window);
          event.stopPropagation();
          event.preventDefault();
        }
      }
    }
  })
})

