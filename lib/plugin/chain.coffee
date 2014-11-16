async = require 'uclogs-async'
assert = require 'assert'
us = require 'underscore'
util = require '../util'

module.exports = (config) ->
  assert.ok(config.output? and us.isArray(config.output), "option output is required for chain plugin")

  output_list = config.output.slice()

  _next = (index, tag, time, chain_next) ->
    return util.only_once (new_record) ->
      if index >= output_list.length
        if chain_next 
          chain_next(new_record)
      else
        next_output = output_list[index]
        data = 
          tag: tag
          time: time
          record : new_record 

        next_output.write data, _next(index + 1, tag, time, chain_next)

    
  return {
    
    start : (callback) ->
      async.eachSeries output_list.slice().reverse()
      , (output, callback) ->
          output.start(callback)
      , callback

    write : ({tag, record, time}, next) ->
      next = _next(0, tag, time, next)
      next(record)
    
    shutdown : (callback) ->
      async.eachSeries output_list
      , (output, callback) ->
          output.shutdown(callback)
      , callback

  }