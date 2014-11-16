async = require 'uclogs-async'
us = require 'underscore'

fs = require 'fs'

# fs.open '/var/tmp/1.log', 'w', (err ,fd) ->
#   buff = new Buffer("1234")
#   fs.write fd, buff, 0, buff.length, null, (err) ->
#     fs.close(fd)
  

fs.open '/var/tmp/1.log', 'r', (err, fd) ->
  console.log "aaaaaaaaa"
  fs.close fd
