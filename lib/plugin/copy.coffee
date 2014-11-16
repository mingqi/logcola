async = require 'uclogs-async'
us = require 'underscore'

module.exports = (config) ->

  _output_list = config.output.slice()
  _empty_next = `function (){}`
  
  return {
    start: (callback) ->
      async.eachSeries _output_list.slice().reverse()
      , (output, callback) ->
          output.start(callback)
      , callback

    shutdown : (callback) ->
      async.eachSeries _output_list.slice()
      , (output, callback) ->
          output.shutdown(callback)
      , callback
    
    write: (data, next) ->
      for output in _output_list
        output.write us.clone(data), _empty_next
      next(data.record)
  }