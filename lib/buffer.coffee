### 
This module is for help developer to build up buffer feature's output plugin

--- How to use ---
Buffer = rquire 'buffer'
buffered_plugin = Buffer(config, output_plugin) 

output_plguin should be a plugin instance with three methods:
1. start
2. shutdown
3. writeChunk(chunk)
    the chunk is the array of [tag, record, time]

config can below options:
- buffer_type   file or memory
- buffer_flush
- buffer_size
- retry_times
- retry_interval
- buffer_queue_size
- concurrency

only for file buffer:
- buffer_path

###

async = require 'uclogs-async'
us = require 'underscore'
assert = require 'assert'
fs = require 'fs'
mkdirp = require 'mkdirp'
glob = require 'glob'
path = require 'path'
log4js = require 'log4js'
VError = require('verror')

util = require './util'
emitter = require './emitter'

logger = log4js.getLogger('logcola')

empty_cb = `function (err){}`

retry = (times, wait_time, task, cb) ->
  did = 0 
  async.retry(times,
    (cb) ->
      task((err) ->
        did += 1
        if not err
          cb()
        else
          logger.warn err
          # timeout_secs = wait_sec * (2 ** (did - 1) )
          timeout_msec = wait_time
          if did >= times
            cb(err)
          else
            # logger.
            logger.warn "failed to write chunk, wait #{timeout_msec} seconds to try again"
            setTimeout(
              () ->
                cb(err) 
              , 
              timeout_msec
              ))
    ,
    cb)

## memory queue ##
memChunkQueue = () ->
  queue = []

  return {

    push : (chunk, callback) ->
      queue.push chunk
      callback()
    
    pop : (callback) ->
      chunk = queue.shift()
      callback(null, chunk)

    length : () ->
      queue.length

  }

## file queue ##
fileChunkQueue = (config) -> 
  _chunk_sequence = (chunkfile) ->
    m = /-(\d)+\.chunk$/.exec chunkfile
    if not m
      return null
    return parseInt(m[1])

  buffer_path = config.buffer_path
  assert.ok(buffer_path, "option buffer_path is required for file buffered output plugin")

  dir = path.dirname(buffer_path) 
  if not fs.existsSync(dir)
    mkdirp.sync(dir)

  _chunk_files = us.filter glob.sync("#{buffer_path}-*.chunk").sort(), _chunk_sequence
  if _chunk_files.length == 0
    _current_seqneuce = 1
  else
    _current_seqneuce = _chunk_sequence(us.last(_chunk_files)) + 1

  _this = 

    push : (chunk, callback) ->
      currtime_mills = util.systemTime()
      chunk_file =  "#{buffer_path}-#{_current_seqneuce++}.chunk"
      tmp_file = chunk_file+".tmp"
      fs.open tmp_file, 'w', (err, fd) ->
        throw err if err
        async.eachSeries chunk
        , (data, callback) ->
            head = new Buffer(4)
            head.writeUInt32BE(data.length, 0)
            fs.write fd, head, 0, head.length, null,  (err) ->
              throw err if err
              fs.write fd, data, 0, data.length, null, (err) ->
                throw err if err
                callback()
        , (err) ->
            fs.close fd, (close_err) ->
              if err or close_err
                fs.unlink tmp_file, () ->
                  throw err or close_err
              else
                fs.rename tmp_file, chunk_file, (err) ->
                  throw err if err
                  _chunk_files.push chunk_file
                  callback()
                      
    pop : (callback) ->
      return callbacl() if _chunk_files.length == 0
      chunk_file = _chunk_files.shift()
      fs.open chunk_file, 'r', (err, fd) ->
        throw err if err
        get_end = false
        chunk = []
        async.until () -> 
          return get_end
        , (callback) ->
            head = new Buffer(4)
            fs.read fd, head, 0, 4, null, (err, bytesRead) ->
              throw err if err
              if bytesRead == 0
                get_end = true
                return callback() 
              if bytesRead != 4
                throw new Error("file chunk file #{chunk_file} is crushed")
              size = head.readInt32BE(0) 
              data = new Buffer(size)
              fs.read fd, data, 0, size, null, (err, bytesRead) ->
                throw err if err
                if bytesRead != size
                  throw new Error("file chunk file #{chunk_file} is crushed")
                chunk.push data
                return callback()
        , (err) ->
            fs.close fd, (close_err) ->
              if err or close_err
                throw err or close_err
              else
                fs.unlink chunk_file, (err) ->
                  throw err if err
                  callback(null, chunk)

    length : () ->
      return _chunk_files.length
  
  return _this


chunkScheduler = (queue, worker, concurrency) ->
  workers_count = 0

  _this = null

  next = () ->
    if queue.length() == 0 
      return

    if workers_count >= concurrency 
      logger.info "all workers is busy, concurrency is #{concurrency}"
      return

    workers_count += 1

    worker_callback = () ->
      workers_count -= 1
      if queue.length() == 0 and  workers_count == 0
        _this.emit('drain')
      next()
        
    queue.pop (err, chunk) ->
      if err
        worker_callback()
        return

      worker chunk, util.only_once(worker_callback)
  
  _this = emitter {

    push : (chunk, callback) ->
      callback ?= empty_cb
      queue.push chunk, (err) ->
        throw err if err
        setImmediate(next)
        callback()

    length : () ->
      return queue.length()

  }
  next() 
  return _this
  

## TODO: change name back to module.exports = ...
module.exports = (config) ->
  buffer_type = config.buffer_type
  buffer_size = parseInt(config.buffer_size)
  buffer_flush = parseInt(config.buffer_flush)
  buffer_queue_size = parseInt(config.buffer_queue_size)
  concurrency = parseInt(config.concurrency)
  assert.ok(buffer_type, "option buffer_type is required for buffered output plugin")  
  assert.ok(buffer_size, "option buffer_size is required for buffered output plugin")  
  assert.ok(buffer_flush, "option buffer_flush is required for buffered output plugin")  
  assert.ok(buffer_queue_size, "option buffer_queue_size is required for buffered output plugin")  
  assert.ok(concurrency, "option concurrency is required for buffered output plugin")  

  retry_times = parseInt(config.retry_times) || 5
  retry_interval = parseInt(config.retry_interval) || 10000

  buffer = []
  size = 0
  buffer_birth_time = util.systemTime()
  _this = null

  _clean_buffer = () ->
    buffer = []
    size = 0 
    buffer_birth_time = util.systemTime()

  _worker = (chunk, callback) ->
    retry(
      retry_times
    , retry_interval
    , (callback) ->
        _this.writeChunk(us.map(chunk, _this.unserialize), callback)
    , callback
    )

  queue = switch buffer_type
    when "file" then fileChunkQueue(config)
    when "memory" then memChunkQueue()
    else throw new Error("buffer_type must be file or memory, #{buffer_type} is illegal")
  
  scheduler = chunkScheduler(queue , _worker, concurrency)
  intervalObj = null 
    
  _collectBuffer = (callback) ->
    callback ?= empty_cb
    if scheduler.length() >= buffer_queue_size
      logger.warn "buffer was discard because of queue exceed limitation. queue=#{scheduler.length()}, buffer_queue_size=#{buffer_queue_size}"
      _clean_buffer()
      return callback()

    if buffer.length > 0
      scheduler.push(buffer, callback)
      _clean_buffer()

  intervalObj = setInterval () ->
    if util.systemTime() - buffer_birth_time > buffer_flush
      if buffer.length > 0
        logger.info "collect buffer because of expired, buffer_flush=#{buffer_flush}"
        _collectBuffer()
  , 1000  

  _this = 

    serialize : (data) ->
      new Buffer(JSON.stringify(data), 'utf-8')
    
    unserialize : (buff) ->
      JSON.parse(buff.toString('utf-8'))

    writeChunk : (chunk, callback) ->
      throw new Error("writeChunk not be implemented yet")

    write : (data) ->
      byte_data = _this.serialize(us.clone(data))
      buffer.push(byte_data)
      size += byte_data.length
      if size >= buffer_size
        logger.info "collect buffer because of exceed buffer_size, size=#{size}, buffer_size=#{buffer_size}"
        _collectBuffer() 

    stop : (done) ->
      logger.info "buffer stop..."
      if intervalObj
        clearInterval(intervalObj)
      if buffer.length > 0
        _collectBuffer () ->
          if scheduler.length() > 0
            scheduler.once 'drain', () ->
              done()
      else
        done()

  return _this

module.exports.retry = retry
module.exports.chunkScheduler = chunkScheduler
module.exports.memChunkQueue = memChunkQueue
module.exports.fileChunkQueue = fileChunkQueue
