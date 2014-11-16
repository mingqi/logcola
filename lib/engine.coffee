events = require('events');
async = require 'uclogs-async'
us = require 'underscore'
moment = require 'moment'

empty_cb = `function (err){}`

Engine = () ->
  inputs = []
  outputs = []
  eventEmitter = new events.EventEmitter();

  started = false

  emit = (data) ->
    for [match, output] in outputs
      if match == data.tag
        setImmediate(
          (output, data) ->
            output.write(data)
          , output
          , us.clone(data)
        )

  indexOfOutput = (match, output) ->
    for i in [0...outputs.length]
      [m, o] = outputs[i]
      return i if m == match and o == output
    return -1
 
  return {
    
    ## only first argument input is mandatory
    addInput : (input, cb) ->
      cb = empty_cb if not cb
      if inputs.indexOf(input) >= 0
        return cb() 

      inputs.push(input)

      if started
        input.start(emit, cb)
      else
        cb(null) 

    addOutput : (match, output, cb) ->
      cb = empty_cb if not cb
      if indexOfOutput(match, output) >= 0
        cb()

      outputs.push([match, output])
      if started
        output.start(cb)
      else
        cb(null) 

    removeInput : (input, cb) ->
      cb = empty_cb if not cb
      index = inputs.indexOf(input)
      if index < 0
        return cb() 

      inputs.splice(index, 1) 
      if started
        input.shutdown(cb)
      else
        cb()
    
    removeOutput : (match, output, cb) ->
      cb = empty_cb if not cb
      index = indexOfOutput(match, output)
      if index < 0
        return cb() 

      outputs.splice(index, 1) 
      if started
        output.shutdown(cb)
      else
        cb() 
     
    start : (callback) ->
      callback = empty_cb if not callback
      started = true
      async.series([
        (callback) ->
          async.each(
            outputs.slice(0), 
            ([m, o], callback) ->
              o.start(callback) 
            ,        
            callback
            )
        ,
        (callback) ->
          async.each(
            inputs.slice(0), 
            (i, callback) ->
              i.start(emit, callback)
            , 
            callback
            )]
        ,
        (err) ->
          if err
            started = false
          callback(err)  
        )

    shutdown : (callback) ->
      callback = empty_cb if not callback
      started = false
        
      async.series([
        (callback) ->
          async.each(
            inputs.slice(0), 
            (i, callback) ->
              i.shutdown( callback) 
            ,        
            callback
            )

        (callback) ->
          async.each(
            outputs.slice(0), 
            ([m, o], callback) ->
              o.shutdown(callback) 
            ,        
            callback
            )
         
        ],
        (err) ->
          if err
            started = true

          callback(err) 
        )
    }

module.exports = Engine