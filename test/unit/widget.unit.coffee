require '../config'
widgets = require '../../main'
Widget = widgets.Widget
Promise = require 'bluebird'

describe 'Widget', ->

  beforeEach ->
    @api = widgets.driver.api =
      element: sinon.stub()
      elementIdText: sinon.stub()
      elementIdClick: sinon.stub()
      elementIdDisplayed: sinon.stub()
    @element = ELEMENT: {}
    @widget = new Widget @element
    # Simulate successful implicit waiting
    @timeout = timeoutsImplicitWait: sinon.stub()
    @timeout.timeoutsImplicitWait.callsArgWith(1, null)

  describe '#getElement', ->

    it 'handles string selectors', ->
      testSelector = '.test-selector'
      stubElement = {}
      @api.element
        .withArgs(testSelector, sinon.match.func)
        .callsArgWith(1, null, value: stubElement)
      widget = new Widget testSelector
      widget.getElement().should.eventually.equal stubElement

    it 'falls back to the prototype selector if available', ->
      testSelector = '.test-selector'
      stubElement = {}
      class SubWidget extends Widget
        selector: testSelector
      @api.element
        .withArgs(testSelector, sinon.match.func)
        .callsArgWith(1, null, value: stubElement)
      widget = new SubWidget()
      widget.getElement().should.eventually.equal stubElement

    it 'can take a webdriver element directly', ->
      widget = new Widget @element
      widget.getElement().should.eventually.equal @element

    it 'throws an error if an invalid selector is given', ->
      error = Widget.ERRORS.invalidSelector(undefined).message
      (-> new Widget()).should.throw error

  describe '#hasText', ->

    it 'resolves the widget when element text matches', ->
      expectedText = 'test'
      @widget.getText = -> Promise.resolve(expectedText)
      @widget.hasText(expectedText).should.eventually.equal(@widget)

    it 'rejects when the text does not match', ->
      @widget.getText = -> Promise.reject()
      @widget.hasText('test').should.be.rejected

  describe 'promisified widget api', ->

    mappings = [
      method: 'click', api: 'elementIdClick'
      method: 'isVisible', api: 'elementIdDisplayed'
    ]

    it 'resolves when webdriver has no error', ->
      for mapping in mappings
        @api[mapping.api].withArgs(@element.ELEMENT).returns @timeout
        @widget[mapping.method]().should.be.fulfilled

    it 'rejects when webdriver has errors', ->
      error = 'error'
      for mapping in mappings
        @timeout.timeoutsImplicitWait.callsArgWith(1, error)
        @api[mapping.api].withArgs(@element.ELEMENT).returns @timeout
        @widget[mapping.method]().should.be.rejectedWith error

    it 'allows nested selectors', ->
      parentSelector = '.parent'
      parentElement = ELEMENT: {}, isParent: true
      nestedSelector = '.nested'
      nestedElement = ELEMENT: {}, isNested: true
      for mapping in mappings

        # Setup stub webdriver API for nested element selectors
        @api.element
          .withArgs("#{parentSelector} #{nestedSelector}", sinon.match.func)
          .callsArgWith(1, null, value: nestedElement)

        # Setup stub webdriver API to respond to mapped methods
        @api[mapping.api].withArgs(nestedElement.ELEMENT).returns @timeout

        # Invoke the API method with a nested selector
        widget = new Widget parentSelector
        widget[mapping.method](nestedSelector).should.be.fulfilled

    it 'throws error when trying to nest element selector', ->
      for mapping in mappings
        @api[mapping.api].withArgs(@element.ELEMENT).returns @timeout
        (-> @widget[mapping.method]('.nested')).should.throw Error
