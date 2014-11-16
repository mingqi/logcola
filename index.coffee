exports.Engine = require './lib/engine'
exports.Buffer = require './lib/buffer'
exports.plugin = require './lib/plugin'
exports.plugins = 
  Stdout : require './lib/plugin/stdout'
  Chain : require './lib/plugin/chain'
  Tail : require './lib/plugin/tail'
  File : require './lib/plugin/file'