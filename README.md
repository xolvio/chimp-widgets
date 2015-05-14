# chimp-widgets
Provides a high-level contextual API for interacting with webdriverIO elements when writing acceptance tests with [meteor-cucumber](https://github.com/xolvio/meteor-cucumber).

This greatly simplifies your step definitions:
```javascript
this.When(/^I select the "([^"]*)" project$/, function(projectTitle, done) {
  new this.widgets.List('.project-list-item .label') // selector that potentially includes multiple elements
  .findByText(projectTitle) // act on the result-set of the selector above
  .then(function(widget) { // the first element with the searched text, wrapped as widget
    widget.click(); 
  })
  .then(function() { done(); });
});
```

This idea is borrowed from [Pioneer.js Widgets](https://github.com/mojotech/pioneer/blob/master/docs/widget.md)

# How to install
`npm install chimp-widgets`

# How to run the tests
First install any dev dependencies with `npm install`
Then you can run all tests with `npm test`
