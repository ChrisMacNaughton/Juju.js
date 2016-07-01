var path = require('path')
var webpack = require('webpack')

module.exports = {
  entry: './test/unit/specs/index.coffee',
  output: {
    path: path.resolve(__dirname, '../test/unit'),
    filename: 'specs.js'
  },
  resolve: {
    extensions: ["", ".coffee"],
    alias: {
      src: path.resolve(__dirname, '../src')
    }
  },
  module: {
    loaders: [
    { test: /\.coffee$/, loader: "coffee-loader" }
    ]
  },
  babel: {
    loose: 'all',
    optional: ['runtime']
  },
  plugins: [
    new webpack.DefinePlugin({
      'process.env': {
        NODE_ENV: '"development"'
      }
    })
  ],
  devServer: {
    contentBase: './test/unit',
    noInfo: true
  },
  devtool: 'source-map'
}
