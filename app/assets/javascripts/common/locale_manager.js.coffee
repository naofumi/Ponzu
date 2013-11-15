LocaleManagerConstructor = ->
  availableLocales = ['en', 'ja']
  toggle = ()->
    current = KSCookie.get('locale')
    KSCookie.create('locale', nextLocale(current), 90)

  nextLocale = (currentLocale) ->
    index = availableLocales.indexOf(currentLocale)
    # if indexOf returns -1, then we probably are
    # showing 'en' (index 0) since this is the default.
    index = 0 if index is -1
    index = (index + 1)%(availableLocales.length)
    availableLocales[index]





  #public interface
  this.toggle = toggle
  this.nextLocale = nextLocale

  return this


window.LocaleManager = new LocaleManagerConstructor()