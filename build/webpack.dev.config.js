var path = require('path')
var webpack = require('webpack')

module.exports = {
  entry: './src/index.coffee',
  output: {
    path: path.resolve(__dirname, '../dist'),
    filename: 'juju.js',
    library: 'Juju',
    libraryTarget: 'umd'
  },
  resolve: {
    extensions: ["", ".coffee"],
  },
  module: {
    loaders: [
      { test: /\.coffee$/, loader: "coffee-loader" },
      { test: /\.(coffee\.md|litcoffee)$/, loader: "coffee-loader?literate" }
    ]
  },
  plugins: [
    new webpack.DefinePlugin({
      'process.env': {
        NODE_ENV: '"development"'
      }
    })
  ],
  devtool: 'source-map'
}
