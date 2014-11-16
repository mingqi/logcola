Pool = require('../lib/plugin/file').Pool

p = Pool(1000)

p.createObj = (id, callback) ->
  callback(null, "created #{id}")

p.destroyObj = (obj, callback) ->
  console.log "destroyed #{obj}"
  callback()

a = [1..5]

for i in a
  # id = if i > 5  then "mingqi" else "xulei"
  id = 'mingqi'
  p.checkout id, (err, obj, callback) ->
    console.log "checkouted: #{obj}"
    setTimeout callback, 1000

setTimeout () ->
  for i in a
    # id = if i > 5  then "mingqi" else "xulei"
    id = 'xulei'
    p.checkout id, (err, obj, callback) ->
      console.log "checkouted: #{obj}"
      setTimeout callback, 1000
, 5000
