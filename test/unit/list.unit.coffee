require '../config'
widgets = require '../../main'

describe 'widgets.List', ->

  beforeEach ->
    @firstElement = ELEMENT: {}
    @secondElement = ELEMENT: {}
    @thirdElement = ELEMENT: {}
    @elements = value: [@firstElement, @secondElement, @thirdElement]

    @api = widgets.driver.api =
      elements: sinon.stub()
      elementIdText: sinon.stub()

    @selector = '.test'

    @api.elements
      .withArgs(@selector)
      .callsArgWith(1, null, @elements)

    @list = new widgets.List @selector

  describe '#findByText', ->

    it 'resolves with the first widget that matches', ->
      text = value: 'test'
      @api.elementIdText.callsArgWith(1, null, text)
      @list.findByText(text.value).should.eventually.eql(
        new widgets.Widget @firstElement, @api
      )

    it 'searches the whole list of widgets', ->
      text = value: 'test'
      @api.elementIdText
        .withArgs(@thirdElement.ELEMENT, sinon.match.func)
        .callsArgWith(1, null, text)
      @list.findByText(text.value).should.eventually.eql(
        new widgets.Widget @thirdElement, @api
      )

    it 'rejects if no widget matches', ->
      @api.elementIdText.callsArgWith(1, null, 'other')
      @list.findByText('test').should.be.rejected
