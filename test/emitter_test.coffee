emitter = require '../lib/emitter'

Test = () ->

  _this = {

    sayHello : () ->
      _this.emit('hello')
    
  }

  return emitter(_this)


t = Test()
t.on 'hello', (i) ->
  console.log "listener #{i}"

t.sayHello()
t.sayHello()
