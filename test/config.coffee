chai = require "chai"
global.sinon = require "sinon"
sinonChai = require "sinon-chai"
chaiAsPromised = require "chai-as-promised"

chai.should()
chai.use sinonChai
chai.use chaiAsPromised
