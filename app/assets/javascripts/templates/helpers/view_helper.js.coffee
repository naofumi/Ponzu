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

  # public interface

  this.randomSelect = randomSelect

  return this

window.ViewHelper = new ViewHelperConstructor()