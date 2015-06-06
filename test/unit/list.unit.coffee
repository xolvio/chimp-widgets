require '../config'
widgets = require '../../main'
Widget = widgets.Widget
List = widgets.List
Promise = require 'bluebird'

describe 'widgets.List', ->

  beforeEach ->
    @firstElement = ELEMENT: {}
    @secondElement = ELEMENT: {}
    @thirdElement = ELEMENT: {}
    @elements = value: [@firstElement, @secondElement, @thirdElement]
    @listSelector = '.test'

    # Simulate webdriver API
    @api = elements: sinon.stub()
    @api.elements.withArgs(@listSelector).callsArgWith(1, null, @elements)

    # Provide fake Widgets for testing
    @widgetFactory = sinon.stub()
    @widgetFactory.returns hasText: -> Promise.reject()

  describe '#findByText', ->

    it 'resolves with the first widget that matches', ->
      text = value: 'test'
      testWidget = hasText: -> Promise.resolve(testWidget)
      @widgetFactory.withArgs(@firstElement).returns testWidget

      list = new List @listSelector, @api, @widgetFactory
      list.findByText(text.value).then (widget) =>
        widget.should.equal testWidget

    it 'rejects if no widget matches', ->
      list = new List @listSelector, @api, @widgetFactory
      list.findByText('test').should.be.rejected
