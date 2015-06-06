Promise = require 'bluebird'
driver  = require './webdriver'

class Widget

  @ERRORS:
    invalidSelector: (id) -> new Error "Invalid selector given: #{id}"
    cannotDoNesting: -> new Error "Can't do nesting with element selectors."

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

  _promisifyWebdriverApi: (method) ->
    @getElement().then (element) =>
      new Promise (fulfill, reject) =>
        action = @driver[method](element.ELEMENT)
        action.timeoutsImplicitWait Widget.TIMEOUT, (error) =>
          # Handle errors and hand on widget instance on success
          if error? then reject(error) else fulfill this

  # ========== GENERATE PROMISIFIED WIDGET API ============ #

  WIDGET_API = [
    { method: 'click', webdriverMethod: 'elementIdClick' }
    { method: 'isVisible', webdriverMethod: 'elementIdDisplayed' }
    { method: 'getText', webdriverMethod: 'elementIdText' }
  ]

  # The generated methods are running in the context of the widget!
  generateApiMethod = (api) -> return (nestedSelector) ->
    if nestedSelector?
      if @_isStringSelector
        # Create widget with nested selectors and call api method
        new Widget("#{@selector} #{nestedSelector}")[api.method]()
      else
        # We can't nest if we have an element selector
        throw Widget.ERRORS.cannotDoNesting()
    else
      # No nesting, just invoke webdriver API on this widget
      @_promisifyWebdriverApi api.webdriverMethod

  for api in WIDGET_API
    Widget.prototype[api.method] = generateApiMethod(api)

module.exports = Widget
