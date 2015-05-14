Promise = require 'bluebird'
driver  = require './webdriver'

class Widget

  element: null

  constructor: (@element) ->

  hasText: (expectedText) ->
    new Promise (fulfill, reject) =>
      driver.api.elementIdText @element.ELEMENT, (error, text) =>
        if error?
          reject error
        else
          if text.value is expectedText then fulfill(this) else reject()

  click: ->
    Promise.promisify(driver.api.elementIdClick, driver.api)(@element.ELEMENT)

module.exports = Widget
