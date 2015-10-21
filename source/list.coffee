Widget  = require './widget'

class List extends Widget

  widgets: null
  itemSelector: null
  _nestedItemsSelector: null

  constructor: (selector, itemSelector, driver, widget) ->
    super selector, driver
    @Widget = widget ? Widget
    @itemSelector ?= itemSelector
    @_nestedItemsSelector = "#{@selector} #{@itemSelector}"
    @widgets = @_wrapAsWidgets(@driver.elements(@_nestedItemsSelector).value)

  findWhere: (filter) ->
    for widget of @widgets
      return widget if filter(widget)

  findByText: (text) ->
    @findWhere (widget) => widget if widget.hasText(text)

  map: (mapper) -> @widgets.map mapper

  _wrapAsWidgets: (elements) =>
    return elements.map (element, index) =>
      # Return widget with scoped index selector
      new @Widget "#{@_nestedItemsSelector}:nth-child(#{index+1})"

module.exports = List
