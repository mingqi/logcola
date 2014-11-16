Engine = require '../lib/engine'
in_test = require './in_test'
stdout = require '../lib/plugin/stdout'
file = require '../lib/plugin/file'

engine = Engine()
engine.addInput(in_test(
  tag: 'test'
  monitor: 'fortest'
  interval: 1
  ))

engine.addOutput 'test', stdout()

engine.addOutput('test', file
  path: '/var/tmp/aa/bb/111.log'
  buffer_type: 'memory'
  buffer_flush : 2
  buffer_size : 200
  buffer_queue_size : 300
  concurrency: 1
  )


engine.start()

setTimeout () ->
  engine.shutdown()
, 5000