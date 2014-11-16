module.exports = (config) ->
  interval_obj = null
  count = 0
  monitor = config.monitor

  query = (emit) ->
    emit({
      tag: config.tag
      record: { metric: monitor, value: count+=1 }
      })

  return {
    start : (emit, cb) ->
      console.log "intest start..."
      query(emit)
      interval_obj = setInterval(query, config.interval * 1000, emit)
      if config.interval > 5
        cb(new Error("not support interval more than 5")) 
      else
        cb()
    
    shutdown : (cb) ->
      console.log "intest shutdonw... #{interval_obj}"
      clearInterval(interval_obj) if interval_obj
      cb()
  }