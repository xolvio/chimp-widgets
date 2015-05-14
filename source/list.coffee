Promise = require 'bluebird'
driver  = require './webdriver'
Widget  = require './widget'

class List

  widgets: null

  constructor: (selector) ->
    @widgets = new Promise (fulfill, reject) =>
      driver.api.elements selector, (error, elements) =>
        if error?
          reject error
        else
          fulfill @_wrapAsWidgets(elements)

  findByText: (text) ->
    @widgets.then (widgets) =>
      Promise.any widgets.map (widget) -> widget.hasText text

  _wrapAsWidgets: (elements) =>
    return elements.value.map (element) => new Widget element

module.exports = List
