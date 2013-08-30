window.KSBaseResourceValidator = function(){
  function validate(){
    validateDataDefaultElements();
    validateBaseResourcePageElements();
  }

  function validateDataDefaultElements(){
    var elements = document.querySelectorAll("[data-default]");
    if (elements.length != 1) {
      // alert('ERROR: Number of elements with data-default attribute should be exactly one!');      
    } else {
      if (!kss.isVisible(elements[0])) {
        // alert('ERROR: Element with data-default should be visible');
      }      
    }
  }

  function validateBaseResourcePageElements(){
    var elements = document.querySelectorAll(".page");
    var numberOfVisiblePages = 0;
    var numberOfPagesWithoutId = 0;
    for (var i = 0; i < elements.length; i++) {
      if (kss.isVisible(elements[i])) {
        numberOfVisiblePages += 1;
      }
      if (!elements[i].hasAttribute('id')) {
        numberOfPagesWithoutId += 1;
      }
    };
    if (numberOfVisiblePages != 0) {
      alert('ERROR: No pages should be visible on baseResourcePage.')
    }
    if (numberOfPagesWithoutId > 0) {
      alert('ERROR: Some pages do not have an id attribute');
    }
  }

  return {
    validate: validate
  }
}();

window.KSAjaxResponseValidator = function(){
  function validate(responseContainer){
    if (!kamishibai.config.validateAjax)
      return;
    validatePresenceOfIds(responseContainer);
    validateVisibilityOfChildren(responseContainer);
  }

  function validatePresenceOfIds(responseContainer) {
    var children = responseContainer.children;
    for (var i = 0; i < children.length; i++) {
      if (!children[i].hasAttribute('id')) {
        alert('More than one top level element lacks an ID');
      }
    };
  }

  function validateVisibilityOfChildren(responseContainer) {
    var children = responseContainer.children;
    for (var i = 0; i < children.length; i++) {
      if (children[i].style.display == 'none' && 
          !(kss.hasClass(children[i], 'page') || kss.hasClass(children[i], 'modal'))) {
        console.log(children[i])
        alert('Top level elements should not have display:none unless .page class.');
      }
    };
  }

  return {
    validate: validate
  }
}();