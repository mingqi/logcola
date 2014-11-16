EventEmitter = require('events').EventEmitter

module.exports = (obj) ->
  emitter = new EventEmitter()

  obj.on = () ->
    emitter.on.apply emitter, arguments

  obj.once = () ->
    emitter.once.apply emitter, arguments
  
  obj.emit = () ->
    emitter.emit.apply emitter, arguments
  
  return obj 