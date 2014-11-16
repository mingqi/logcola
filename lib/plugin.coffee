us = require 'underscore'
path = require 'path'

_findModule = (name) ->
  try
    require.resolve name
  catch e
    return null

  require name

_paths = []


module.exports = plugin = (config) ->

  type = config.type

  for p in _paths
    m = _findModule(path.join(path.resolve(p), type))
    break if not m


  if not m
    m = _findModule("./plugin/#{type}") or _findModule(type)
  
  if not m
    throw new Error("can't not find the plugin #{type}")  

  tr_config = {}
  for k, v of config
    if k == 'output' 
      if us.isArray v
        tr_v = v.map plugin
      else
        tr_v = plugin(v)
    else
      tr_v = v
    tr_config[k] = tr_v

  return m(tr_config)
  

module.exports.setPluginPath = (path) ->
  if us.isString path
    _paths = [path]

  else if us.isArray path
    _paths = path

  else
    throw new Error('path must be a string or a string array') 