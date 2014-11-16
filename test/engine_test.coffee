Engine = require '../lib/engine'
in_test = require './in_test'
stdout = require '../lib/plugin/stdout'
buffer_test = require './buffer_test'
# http = require '../lib/plugin/http'

engine = Engine()
engine.addInput(in_test(
  tag: 'test'
  monitor: 'fortest'
  interval: 1
  ))

# engine.addInput(http
#   port: '8010'
#   bind: 'localhost'
#   )

engine.addOutput('test', buffer_test
  buffer_type: 'memory'
  buffer_flush : 200
  buffer_size : 200
  buffer_queue_size : 300
  concurrency: 1
  buffer_path: '/var/tmp/file_chunk/tt'
  delay: 3
  )

engine.addOutput 'test', stdout()

engine.start()

setTimeout () ->
  engine.shutdown()
, 3000