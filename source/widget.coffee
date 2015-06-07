Promise = require 'bluebird'
driver  = require './webdriver'

class Widget

  @ERRORS:
    invalidSelector: (id) -> new Error "Invalid selector given: #{id}"

  driver: null
  selector: null

  constructor: (selector, @driver=driver.api, @Promise=Promise) ->
    @selector ?= selector
    if not typeof @selector is 'string'
      throw Widget.ERRORS.invalidSelector(@selector)

  # Returns a new widget that is scoped within the parent selector.
  find: (nestedSelector) -> new Widget "#{@selector} #{nestedSelector}"

  # Convenient wrapper around text expectation
  hasText: (expected) -> @getText().should.eventually.become(expected)

  # Wraps webdriver API methods into promises
  _promisifyWebdriverApi: (method, callArgs) ->
    new Promise (fulfill, reject) =>
      # Add selector as first argument
      callArgs.unshift @selector
      # Add the handler function as last argument
      callArgs.push (error, result) =>
        # Provide the result value for convenience!
        if error? then reject(error) else fulfill(result)
      # Invoke the webdriver.io API method with prepared args
      @driver[method].apply @driver, callArgs

  # ========== GENERATE PROMISIFIED WIDGET API ============ #

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
    @_promisifyWebdriverApi method, callArgs

  Widget.prototype[method] = generateApiMethod(method) for method in Widget.API

module.exports = Widget
