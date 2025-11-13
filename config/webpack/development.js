process.env.NODE_ENV = process.env.NODE_ENV || 'development'

const environment = require('./environment')

const config = environment.toWebpackConfig()

// Fix for webpack-dev-server: use [hash] instead of [contenthash] in development
if (config.output && config.output.filename) {
  config.output.filename = config.output.filename.replace('[contenthash]', '[hash]')
}
if (config.output && config.output.chunkFilename) {
  config.output.chunkFilename = config.output.chunkFilename.replace('[contenthash]', '[hash]')
}

module.exports = config
