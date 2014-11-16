async = require 'async'
buffer = require '../lib/buffer'

_worker = (n, callback) ->
  console.log "worker #{n}"
  setTimeout(callback, 500)

q = buffer.chunkScheduler(buffer.fileChunkQueue({buffer_path:'/var/tmp/chunkqueue/tt'}), _worker, 1)

# i = 0
# intervalObj = setInterval( 
#   () ->
#     i += 1
#     console.log "i="+i
#     q.push [new Buffer(''+i)]
# , 100
# )

for i in [1..100]
  q.push [new Buffer(''+i)]

# setTimeout () ->
#   clearInterval intervalObj
# , 3000

q.on 'drain', () ->
  console.log "drainnnnnnnnnnnnn"
