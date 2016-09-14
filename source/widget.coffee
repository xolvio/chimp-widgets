driver  = require './webdriver'
Base    = require './base'

class Widget extends Base

  # A widget can represent a screen within your app that
  # can be visited at a specific url
  @url: null

  # Static method to visit a screen and check that it is visible
  @visit: (wait=5000) ->
    driver.api.url(@url)

    screen = new this() # Create an instance of the widget
    screen.waitForExist(wait)
    screen # Resolve with screen instance

  # The webdriver api that is used by the widget
  driver: null
  # All widgets have a selector that maps to one or multiple DOM elements
  selector: null

  constructor: (selector, @driver=driver.api) ->
    @selector = selector if selector?
    if not typeof @selector is 'string'
      throw new Error "Invalid selector given: #{@selector}"

  # Returns a new widget that is scoped within the parent selector.
  find: (nestedSelector) -> new Widget "#{@selector} #{nestedSelector}"

  # Convenient wrapper around text expectation
  hasText: (expected) -> @getText().should.eventually.become(expected)

  # ========== GENERATE WRAPPED WIDGET API ============ #

  Widget.API = [
    # Actions
    'addValue', 'clearElement', 'click', 'doubleClick', 'dragAndDrop',
    'leftClick', 'middleClick', 'moveToObject', 'rightClick', 'setValue'
    'submitForm',
    # Property
    'getAttribute', 'getCssProperty', 'getElementSize', 'getHTML',
    'getLocation', 'getLocationInView', 'getSource', 'getTagName',
    'getText', 'getTitle', 'getValue',
    # State
    'isEnabled', 'isExisting', 'isSelected', 'isVisible',
    # Utility
    'waitForChecked', 'waitForEnabled', 'waitForExist', 'waitForSelected',
    'waitForText', 'waitForValue', 'waitForVisible'
  ]

  # The generated methods are running in the context of the widget!
  generateApiMethod = (method) -> return ->
    callArgs = Array.prototype.slice.call arguments
    # Add selector as first argument
    callArgs.unshift @selector

    # Invoke the webdriver.io API method with prepared args
    @driver[method].apply @driver, callArgs

  Widget.prototype[method] = generateApiMethod(method) for method in Widget.API

module.exports = Widget
