Promise = require 'bluebird'
driver  = require './webdriver'
Widget  = require './widget'

class Screen extends Widget

  @url: null

  # Static method to visit a screen and check that it is visible
  @visit: ->
    Promise.promisify(driver.api.url, driver.api)(@url)
    .then => new this().isVisible()

module.exports = Screen
