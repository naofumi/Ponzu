# Method that allows you to set stylesheets via Javascript.
# It works by adding a style element with the text set in
# cssString, to the header.
#
# Subsequent calls will replace the previously set stylesheet.
# More than one stylesheet can be used by providing a unique
# cssId attribute.
window.cssSet = (cssString, cssId)->
  cssId = cssId || "css-changer-inserted"
  css = document.getElementById(cssId) || createCssElement(cssId)
  css.textContent = cssString
  
createCssElement = (cssId)->
  css = document.createElement('style')
  css.id = cssId
  document.getElementsByTagName('head')[0].appendChild(css)
