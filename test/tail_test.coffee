Engine = require '../lib/engine'
stdout = require '../lib/plugin/stdout'
Tail = require '../lib/plugin/tail'

engine = Engine()


ext_tail = (config) ->

  _emit = null
  t = tail(config)

  t.line = (line) ->
    _emit
      tag: 'test'
      record : 
        aaa : 'ccccbbbb'
  
  return {
    start : (emit, callback) ->
      _emit = emit
      t.start(emit, callback)

    shutdown : (callback) ->
      t.shutdown(callback)    
    
  }

t = Tail
  tag: 'test'
  path: '/var/tmp/tt*.log'
  pos_file: '/var/tmp/pos.db'
  refresh_interval_seconds: 1
  max_size : 3

engine.addInput  t

engine.addOutput('test', stdout())


engine.start()

process.on('SIGINT', () ->
  console.log "aaaaaaa"
  engine.shutdown()
)