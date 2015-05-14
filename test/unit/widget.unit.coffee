require '../config'
widgets = require '../../main'

describe 'widgets.Widget', ->

  beforeEach ->
    @api = widgets.driver.api =
      elementIdText: sinon.stub()
      elementIdClick: sinon.stub()
    @element = ELEMENT: {}
    @widget = new widgets.Widget @element

  describe '#hasText', ->

    it 'resolves the widget when element text matches', ->
      expectedText = 'test'
      @api.elementIdText
        .withArgs(@element.ELEMENT, sinon.match.func)
        .callsArgWith(1, null, expectedText)
      @widget.hasText(expectedText).should.eventually.equal(@widget)

    it 'rejects when the text does not match', ->
      @api.elementIdText.callsArgWith 1, null, 'other'
      @widget.hasText('test').should.be.rejected

    it 'rejects when there is a webdriver error', ->
      expectedError = 'error'
      @api.elementIdText.callsArgWith 1, expectedError, null
      @widget.hasText('test').should.be.rejectedWith(expectedError)

  describe '#click', ->

    it 'resolves when webdriver has no error', ->
      @api.elementIdClick
        .withArgs(@element.ELEMENT, sinon.match.func)
        .callsArgWith(1, null)
      @widget.click().should.be.fulfilled

    it 'rejects when webdriver has errors', ->
      error = 'error'
      @api.elementIdClick
        .withArgs(@element.ELEMENT, sinon.match.func)
        .callsArgWith(1, error)
      @widget.click().should.be.rejectedWith error
