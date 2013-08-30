kamishibai.beforeInitialize ->
  kss.addEventListenerFilteringByTagName document, 'click', 'input', (event, target)->
    if target.type is 'radio' and target.name is "like[score]"
      form = kss.closestByTagName target, 'form', true
      kss.sendEvent 'submit', form
