async = require 'async'

async.until () -> 
  return false
, (callback) ->
    callback()
, (err) ->
    console.log err


  