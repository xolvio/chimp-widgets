Promise = require 'bluebird'
driver  = require './webdriver'
Widget  = require './widget'

class List

  api: null
  widgets: null

  constructor: (selector, @driver=driver.api, @Widget=Widget, @Promise=Promise) ->
    @widgets = new @Promise (fulfill, reject) =>
      @driver.elements selector, (error, elements) =>
        if error?
          reject error
        else
          fulfill @_wrapAsWidgets(elements)

  findByText: (text) ->
    @widgets.then (widgets) =>
      Promise.any widgets.map (widget) -> widget.hasText text

  _wrapAsWidgets: (elements) =>
    return elements.value.map (element) => new @Widget element

module.exports = List
