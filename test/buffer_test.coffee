buffer = require '../lib/buffer'

buffer_test = (config) ->

  delay = config.delay

  return {
    
    start : (callback) ->
      callback()

    shutdown : (callback) ->
      callback()

    writeChunk : (chunk, callback) ->
      console.log "writeChunk...: #{chunk.length}"

      setTimeout () ->
        callback()
      , 1000 * delay

  }  

module.exports = (config) -> 
  buffer(config, buffer_test(config))