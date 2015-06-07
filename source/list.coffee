Widget  = require './widget'

class List extends Widget

  widgets: null
  itemSelector: null
  _nestedItemsSelector: null

  constructor: (selector, itemSelector, driver, widget, promise) ->
    super selector, driver, promise
    @Widget = widget ? Widget
    @itemSelector ?= itemSelector
    @_nestedItemsSelector = "#{@selector} #{@itemSelector}"
    @widgets = new @Promise (fulfill, reject) =>
      @driver.elements @_nestedItemsSelector, (error, elements) =>
        if error?
          reject error
        else
          fulfill @_wrapAsWidgets(elements.value)

  findByText: (text) ->
    @widgets.then (widgets) =>
      @Promise.any widgets.map (widget) => widget.hasText(text).then -> widget

  _wrapAsWidgets: (elements) =>
    return elements.map (element, index) =>
      # Return widget with scoped index selector
      new @Widget "#{@_nestedItemsSelector}:nth-child(#{index+1})"

module.exports = List
