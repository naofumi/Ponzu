ViewHelperConstructor = ->
  randomSelect = (array, number = 1) ->
    # array is passed by value so we can safely change
    result = []

    for i in [0...number]
      range = array.length
      break if range is 0
      choice = Math.floor(Math.random() * array.length)
      result.push(array.splice(choice, 1)[0])

    result

  # language is a string like 'en', 'ja'
  speechLanguageSelection = {en: "In English", ja: "日本語発表"}
  speechLanguageIndicator = (language) ->
    speechLanguageSelection[language]


  # public interface

  this.randomSelect = randomSelect
  this.speechLanguageIndicator = speechLanguageIndicator

  return this

window.ViewHelper = new ViewHelperConstructor()