var webpackConfig = require('./webpack.test.config')
delete webpackConfig.entry
webpackConfig.devtool = 'inline-source-map'

// shared config for all unit tests
module.exports = {
  frameworks: ['jasmine'],
  files: [
    '../test/unit/lib/jquery.js',
    '../test/unit/specs/index.coffee'
  ],
  preprocessors: {
    '../test/unit/specs/index.coffee': ['webpack', 'sourcemap']
  },
  webpack: webpackConfig,
  webpackMiddleware: {
    noInfo: true
  },
  singleRun: true
}
