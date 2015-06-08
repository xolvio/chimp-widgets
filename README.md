# chimp-widgets
Write award winning step definitions while working with [meteor-cucumber](https://github.com/xolvio/meteor-cucumber).

## Installation
`npm install chimp-widgets`

## Why?
The management of step definitions is arguably one of the biggest weaknesses
of cucumber and can get out of hand quite fast. There are multiple reasons that
contribute to this problem but `chimp-widgets` tackles one of them specifically:
**The duplication of DOM selectors in step defintions**.

Let me show you an example of some innocent looking steps:

```javascript
this.When(/^I go to my projects$/, function(done) {
  this.browser.url(process.env.ROOT_URL + 'projects')
  .waitForVisible('.projects-list')
  .call(done);
});

this.Then(/^I should see my projects$/, function(done) {
  this.browser.waitForVisible('.projects-list').call(done);
});

this.When(/^I select the first project$/, function(done) {
  this.browser.click('.projects-list .project:nth-child(1)')
  .call(done);
});
```

When we look closer we realize that they contain several (implicit) facts about a *project page* and its *list markup*:

  1. The URL of the project page `process.env.ROOT_URL + 'projects'`
  2. The CSS selector of the project list `.projects-list`
  3. The nested CSS selector to access a project `.projects-list .project`

The problem is hidden behind the word *implicit*, because those three steps also have in common that they never talk about the real thing (the project page) *explicitely*. To understand what is happening you have to parse the calls to the webdriver API and infer the action targets from DOM selectors.

Let's make the interaction with the DOM more *explicit*:

```javascript
this.When(/^I go to my projects$/, function() {
  return this.ProjectsPage.visit();
});

this.Then(/^I should see my projects$/, function() {
  return new this.ProjectsPage().waitForVisible();
});

this.When(/^I select the first project$/, function() {
  return new this.ProjectsPage().selectProjectAt(1);
});
```

Wow, look at that – we got rid of all the DOM selectors and used some
kind of class to represent a real world concept (project page) within
our application. This class and its instances expose a simple API
that hide the implementation details for the reader. Additionally we
could get rid of the `done` parameter because all API methods return
a `Promise` to indicate success or failure to the test runner.

## How?

Let's look at the definition of the `ProjectsPage` class:

```javascript
module.exports = function() {
  this.Before(function(done) {

    this.ProjectsPage = this.widgets.Widget.extend({

      selector: '.projects-list',

      selectProjectAt: function(index) {
        this.find('.project:nth-child('+index+')').click();
      }
    });

    this.ProjectsPage.url = process.env.ROOT_URL + 'projects';

    done();
  });
};
```

Let's analyize what we did here, step by step:

  1. Setup a standard `Before` hook from `meteor-cucumber` which
  provides access to the world, so we can expose our widget class
  to all step definitions.
  2. Extend the `Widget` class by providing prototype properties and methods.
  3. Define the CSS `selector` of the widget, which is used to scope
  all webdriver calls to instances of the widget.
  4. Define a custom method `selectProjectAt` which uses the `Widget::find`
  method to create a new (anonymous) widget instance that is scoped
  within the `ProjectsPage` selector. The resulting widget has the
  selector `.projects-list .project:nth-child(index)` which is what
  we used to select a project in our first step definitions example
  5. Call `click` on the ad-hoc project widget

Now you may ask: Where does `visit`, `waitForVisible` and `click`
come from? That's the really cool part: **You can
use the complete webdriver.io API without any changes**. You just leave out
the first param (*selector*) to all api calls because your *widgets*
are taking care of that transparently. The second nice side effect
is that the chimp-widgets API wraps the raw webdriver.io calls with
Promises. That's why you can just return `new this.ProjectsPage().waitForVisible();` in your step definition and and the
test runner handles the resolved or rejected promise.

## API

### this.widgets.Widget

The base class of all widgets that wraps the complete webdriver.io API
by scoping all calls to the provided `selector` and returning Promises only.

Here is the bare-bones definition of a widget:
```javascript
this.MyWidget = this.widgets.Widget.extend({
  selector: '.my-dom-selector',
});
```

#### `find(selector)`

Creates and immediately returns a new widget instance with `selector` scoped
within the parent widget. Calling `new this.MyWidget().find('.test')` is the
same as creating `new this.widgets.Widget('.my-dom-selector .test')`.

It is important to know that although the method is called `find` there is
no interaction with webdriver.io happening. It really just nests CSS selectors
so that API calls on the nested widget target nested DOM elements.

#### `hasText(text)`

Convenience method around the webdriver.io `getText` method. Is the same as
calling `widget.getText().should.eventually.become(expected)`.

#### Exposed webdriver.io Methods:

The cool thing about chimp-widgets is that you don't have to learn a lot
of new concepts. It exposes exactly the same API as webdriver.io `client`
or `browser` but scopes it to the widget `selector` and wraps it into a
Promise automatically.

Here is the complete list of supported webdriver.io methods:

```coffeescript
Widget.API = [
  # Actions
  'addValue', 'clearElement', 'click', 'doubleClick', 'dragAndDrop',
  'leftClick', 'middleClick', 'moveToObject', 'rightClick', 'setValue',
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
```
#### Creating anynomous ad-hoc widgets:
Sometimes it is too cumbersome to define a separate class to represent a
DOM object, that's where creating ad-hoc instances can be helpful:
`new this.widgets.Widget(selector, [driver], [Promise])`

### this.widgets.List

Documentation coming soon, in the meanwhile checkout this `Leaderboard`
class defined in the [chimp-widgets-demo](https://github.com/xolvio/chimp-widgets-demo)
which represents the leaderboard from the standard Meteor examples:

```javascript
var widgets = this.widgets;
// Define a widget by extending the base class
this.Leaderboard = widgets.List.extend({

  selector: '.leaderboard', // All widgets need a CSS selector
  itemSelector: '.player', // Selector of nested items

  // Define high-level methods that you can call from steps
  givePointsTo: function(name, points) {
    self = this;
    return this.selectPlayer(name).then(function() {
      return self.givePointsToSelectedPlayer(points);
    });
  },

  selectPlayer: function(name) {
    return this.getPlayerByName(name).then(function(player) {
      return player.click();
    });
  },

  getPlayerByName: function(name) {
    return this.findWhere(function(player) {
      return player.find('.name').getText().then(function(text) {
        return text.match(new RegExp(name, "g"));
      });
    });
  },

  givePointsToSelectedPlayer: function() {
    return new widgets.Widget('.details .inc').click();
  },

  checkScoreOf: function(name, expectedPoints) {
    return this.getPlayerByName(name).then(function(player) {
      return player.find('.score').getText().should.become(expectedPoints);
    });
  },

  checkPlayerIsAbove: function(player1, player2) {
    var self = this;
    return this.getPlayerPosition(player1).then(function(position1) {
      return self.getPlayerPosition(player2).then(function(position2) {
        return self.Promise.resolve(position1 < position2).should.become(true);
      });
    });
  },

  getPlayerPosition: function(name) {
    var Promise = this.Promise;
    return Promise.any(this.map(function(player, position) {
      return player.find('.name').getText().then(function(playerName) {
        if(playerName === name) {
          return Promise.resolve(position);
        }
        else {
          return Promise.reject();
        }
      });
    }));
  }
});
// Set the URL of the leaderboard screen statically
this.Leaderboard.url = process.env.ROOT_URL;
```

# How to run the tests
Install dev dependencies with `npm install` then run all tests with `npm test`
