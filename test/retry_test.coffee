buffer = require '../lib/buffer'
async = require 'async'

buffer.retry 3, 1, (callback) ->
  console.log "do it: "+ (new Date())
  callback("abc")
, (err) ->
    console.log (new Date()) + ": err is #{err}"

# async.retry 5, (callback, results) ->
#   console.log "do it"
#   setTimeout callback, 1000, "error"
# , (err, results) ->
#   console.log "err is: #{err}"

