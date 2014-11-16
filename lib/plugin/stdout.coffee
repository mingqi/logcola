module.exports = () ->
  
  return {
    name : 'stdout',
    
    start : (cb) ->
      console.log "stdout start"
      cb()

    write : ({tag, record, time}) ->
      console.log "stdout: tag=#{tag}, record=#{JSON.stringify(record)}"
    
    shutdown : (cb) ->
      console.log "stdout shutdown..."          
      cb()
  }
