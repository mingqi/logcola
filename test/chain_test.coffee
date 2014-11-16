Engine = require '../lib/engine'

chain = require '../lib/plugin/chain'
stdout = require '../lib/plugin/stdout'
in_test = (config) ->

  return {
    start : (emit, cb) ->
      emit
        tag : 'test' 
        record :
          message: "hello"
    shutdown : (cb) ->
      cb()
  }

append_output = (append, is_suffix) ->
  is_suffix ?= false

  return {
    start : (cb) ->
      # console.log "append start #{append}"
      cb()

    write : ({tag, record, time}, next) ->
      # console.log "#{append} append : tag=#{tag}, record=#{JSON.stringify(record)}, time=#{time}"
      new_message = "#{append} - #{record.message}"
      if is_suffix
        new_message = "#{record.message} - #{append}"
      new_record = 
        message : new_message
      next(new_record)
    
    shutdown : (cb) ->
      cb()    
  }


engine = Engine()

engine.addInput(in_test())

inner_chain = chain({output : [
  append_output('aaaa'),
  append_output('bbbb'),
  append_output('cccc'),
]})

outer_chain = chain({
  output: [append_output("nnnn", true), inner_chain, stdout()]
  })

engine.addOutput('test', outer_chain)

engine.start()

