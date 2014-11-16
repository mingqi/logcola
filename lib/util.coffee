moment = require 'moment'
humanFormat = require 'human-format'


exports.systemTime = systemTime = () ->
  (new Date()).getTime()



exports.dateISOFormat = dateISOFormat = (d) ->
  moment(d).format('YYYY-MM-DDTHH:mm:ssZ')

exports.only_once = (fn) ->
  called = false
  return () ->
    if called 
      throw new Error('functon already been called')
    called = true
    fn(arguments...)



exports.parseHumaneSize = (ssize) ->
  lower_opts = 
    unit: 'b'
    prefixes: humanFormat.makePrefixes(',k,m,g,t'.split(','), 1024 )

  upper_opts = 
    unit: 'B'
    prefixes: humanFormat.makePrefixes(',K,M,G,T'.split(','), 1024 )
  
  value = humanFormat.parse(ssize, lower_opts) or humanFormat.parse(ssize, upper_opts)

  if not value
    throw new Error("illegal size format: #{ssize}")
  return value