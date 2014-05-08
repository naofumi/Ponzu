// We currently only handle Success
// We should create a new AJAX function and do the work there.

/**
 * Unobtrusive scripting adapter for no JS framework
 * From https://github.com/jjbuckley/rails-ujs/blob/master/src/rails.js
 * https://github.com/bjjb/rails-ujs
 * Modified for use within Kamishibai by Naofumi
 */

new function(e) {
  var ajaxLoadTimeout = 20000; // ms

  var self = this;
  var ajaxTarget;
  this.ajaxTarget = ajaxTarget;
  this.handleEvent = function(e) {
    var target = e.target;

    if (e.type === 'click') {
      target = kss.closestByTagName(target, 'A', true)
    } else if (e.type === 'submit') {
      target = kss.closestByTagName(target, 'FORM', true)
    }

    if (!target) return;
    
    var tagName = target.tagName;
    if ((e.type === 'click' && tagName === 'A') ||
        (e.type === 'submit' && tagName === 'FORM')) {
      self.ajaxTarget = target;
      if (target.hasAttribute('data-confirm')) {
        if (!confirm(target.getAttribute('data-confirm'))) {
          e.preventDefault();
          return false;
        }
      }

      var form;
      if (target.hasAttribute('data-method') || target.hasAttribute('data-remote')) {
        e.preventDefault();
        // A form will be required...
        if (tagName === 'FORM') {
          form = target;
        }
        else {
          form = document.createElement('FORM');
          form.method = 'post';
          form.action = target.getAttribute('href');
          form.setAttribute('hidden', 'hidden');
          form.style.display = 'none';
          form.style.visibility = 'hidden';
          document.body.appendChild(form);
        }
        // Either way, it needs the CSRF token
        if (!form[KSRails.csrfParam()] && form.getAttribute('method').toUpperCase() != 'GET') {
          var field = document.createElement('input');
          field.type = 'hidden';
          field.name = KSRails.csrfParam();
          field.value = KSRails.csrfToken();
          form.appendChild(field);
        }
      }

      var method;
      if (target.hasAttribute('data-method')) {
        // We'll need to send the _method parameter
        method = target.getAttribute('data-method').toLowerCase();
        var field = document.createElement('input');
        field.type = 'hidden';
        field.name = '_method';
        field.value = target.getAttribute('data-method');
        form.appendChild(field);
      }
      else if (tagName === 'A') {
        method = 'get';
      }
      else if (tagName === 'FORM') {        
        method = target.getAttribute('method') || 'post';
      }
      else {
        throw("Couldn't determine a method!");
      }

      var url;
      if (tagName === 'A') {
        url = target.getAttribute('href');
      }
      else if (tagName === 'FORM') {
        url = target.getAttribute('action');
      }
      else {
        throw("Couldn't determine URL!");
      }
      if (target.hasAttribute('data-remote')) {
        // TODO: See if we can move the serialization stuff to KSAjax
        var data = serialize(form);
        var urlWithData = url;
        if (method.toUpperCase() == 'GET' && data) {
          if (url.indexOf('?') == -1) {
            urlWithData = url + "?" + data;
          } else {
            urlWithData = url + "&" + data;
          }
        }

        // Manage success in callbacks.
        KSCache.cachedAjax({
          url: urlWithData,
          data: data,
          method: method,
          timeoutInterval: ajaxLoadTimeout,
          callbackContext: target
        })
      }
      else if (target.hasAttribute('data-method')) {
        form.submit();
      }
    }
  };
  kss.addEventListener(window, 'load', this);
  kss.addEventListener(window, 'click', this);
  kss.addEventListener(window, 'submit', this);
  // window.addEventListener('load', this, false);
  // window.addEventListener('click', this, false);
  // window.addEventListener('submit', this, false);
}();

// form-serialize from http://code.google.com/p/form-serialize/source/browse/trunk/serialize-0.2.js
function serialize(form) {
  if (!form || form.nodeName !== "FORM") {
    return;
  }
  var i, j, q = [];
  for (i = 0; i < form.elements.length; i++) {
  // Not sure why, but the original code read from bottom to top.
  // Fixed to read from top to bottom.
  // for (i = form.elements.length - 1; i >= 0; i = i - 1) {
    if (form.elements[i].name === "") {
      continue;
    }
    switch (form.elements[i].nodeName) {
    case 'INPUT':
      switch (form.elements[i].type) {
      case 'text':
      case 'tel':
      case 'url':
      case 'email':
      case 'datetime':
      case 'date':
      case 'month':
      case 'week':
      case 'time':
      case 'datetime-local':
      case 'number':
      case 'range':
      case 'color':
      case 'search':
      case 'hidden':
      case 'password':
      case 'button':
      case 'reset':
      case 'submit':
        q.push(form.elements[i].name + "=" + encodeURIComponent(form.elements[i].value));
        break;
      case 'checkbox':
      case 'radio':
        if (form.elements[i].checked) {
          q.push(form.elements[i].name + "=" + encodeURIComponent(form.elements[i].value));
        }           
        break;
      case 'file':
        break;
      }
      break;       
    case 'TEXTAREA':
      q.push(form.elements[i].name + "=" + encodeURIComponent(form.elements[i].value));
      break;
    case 'SELECT':
      switch (form.elements[i].type) {
      case 'select-one':
        q.push(form.elements[i].name + "=" + encodeURIComponent(form.elements[i].value));
        break;
      case 'select-multiple':
        for (j = form.elements[i].options.length - 1; j >= 0; j = j - 1) {
          if (form.elements[i].options[j].selected) {
            q.push(form.elements[i].name + "=" + encodeURIComponent(form.elements[i].options[j].value));
          }
        }
        break;
      }
      break;
    case 'BUTTON':
      switch (form.elements[i].type) {
      case 'reset':
      case 'submit':
      case 'button':
        q.push(form.elements[i].name + "=" + encodeURIComponent(form.elements[i].value));
        break;
      }
      break;
    }
  }
  return q.join("&");
}