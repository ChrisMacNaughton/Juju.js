var assign = require('object-assign')
var base = require('./karma.base.config.js')

/**
 * Having too many tests running concurrently on saucelabs
 * causes timeouts and errors, so we have to run them in
 * smaller batches.
 */

var batches = [
  // the cool kids
  {
    sl_chrome: {
      base: 'SauceLabs',
      browserName: 'chrome',
      platform: 'Windows 7'
    },
    sl_firefox: {
      base: 'SauceLabs',
      browserName: 'firefox'
    }
  },
  // ie family
  {
    sl_ie_10: {
      base: 'SauceLabs',
      browserName: 'internet explorer',
      platform: 'Windows 8',
      version: '10'
    },
    sl_ie_11: {
      base: 'SauceLabs',
      browserName: 'internet explorer',
      platform: 'Windows 8.1',
      version: '11'
    }
  },
]

module.exports = function (config) {
  var batch = batches[process.argv[4] || 0]

  config.set(assign(base, {
    browsers: Object.keys(batch),
    customLaunchers: batch,
    reporters: ['progress', 'saucelabs'],
    sauceLabs: {
      testName: 'Juju.js unit tests',
      recordScreenshots: false,
      build: process.env.TRAVIS_JOB_NUMBER || process.env.SAUCE_BUILD_ID || Date.now()
    },
    // mobile emulators are really slow
    captureTimeout: 300000,
    browserNoActivityTimeout: 300000
  }))
}
