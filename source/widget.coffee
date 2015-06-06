Promise = require 'bluebird'
driver  = require './webdriver'

class Widget

  @ERRORS:
    invalidSelector: (id) -> new Error "Invalid selector given: #{id}"

  @TIMEOUT: 5000

  driver: null
  selector: null

  constructor: (selector, @driver=driver.api, @Promise=Promise) ->
    if selector? then @selector = selector
    @_isStringSelector = typeof @selector is 'string'
    @_isElementSelector = !@_isStringSelector and selector? and selector.ELEMENT?
    if !@_isStringSelector and !@_isElementSelector
      throw Widget.ERRORS.invalidSelector(selector)

  getElement: ->
    new Promise (fulfill, reject) =>
      if @_isStringSelector
        @driver.element @selector, (error, element) ->
          if error? then reject(error) else fulfill(element.value)
      if @_isElementSelector then fulfill(@selector)

  hasText: (expectedText) ->
    @getText().then (text) =>
      if text.value is expectedText
        @Promise.resolve(this)
      else
        @Promise.reject()

  find: (nestedSelector) ->
    if @_isElementSelector
      # We can't find nested elements if we dont have a parent selector
      new Widget nestedSelector
    else
      new Widget "#{@selector} #{nestedSelector}"

  _promisifyWebdriverApi: (method, callArgs) ->
    @getElement().then (element) =>
      new Promise (fulfill, reject) =>
        callArgs.unshift element.ELEMENT
        action = @driver[method].apply @driver, callArgs
        action.timeoutsImplicitWait Widget.TIMEOUT, (error) =>
          # Handle errors and hand on widget instance on success
          if error? then reject(error) else fulfill this

  # ========== GENERATE PROMISIFIED WIDGET API ============ #

  WIDGET_API = [
    { method: 'click', webdriverMethod: 'elementIdClick' }
    { method: 'isVisible', webdriverMethod: 'elementIdDisplayed' }
    { method: 'getText', webdriverMethod: 'elementIdText' }
    { method: 'setValue', webdriverMethod: 'elementIdValue' }
  ]

  # The generated methods are running in the context of the widget!
  generateApiMethod = (api) -> return ->
    callArgs = Array.prototype.slice.call arguments
    @_promisifyWebdriverApi api.webdriverMethod, callArgs

  for api in WIDGET_API
    Widget.prototype[api.method] = generateApiMethod(api)

module.exports = Widget
