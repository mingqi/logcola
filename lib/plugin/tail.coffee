util = require '../util'
Tail = require('tail-forever')
glob = require 'glob'
path = require 'path'
us = require 'underscore'
NeDB = require 'nedb'
fs = require 'fs'
moment = require 'moment'
os = require 'os'
assert = require 'assert'
async = require 'uclogs-async'
log4js = require 'log4js'

###
- path
- pos_file
- refresh_interval
- save_posotion_interval
- max_size
- max_line_size
- buffer_size
- encoding: default is utf-8

line function will use:
- tag
- message_key
- file_key
###

logger = log4js.getLogger('logcola')

module.exports = (config) ->

  assert.ok(config.path, "option path is required for tail plugin")
  if us.isString config.path
    _paths = [config.path]
  else if us.isArray config.path
    _paths = config.path.slice()
  else
    throw new Error('path must be a string or array')

  assert.ok us.isNumber(config.max_size), "max_size should be number" if config.max_size?
  assert.ok us.isNumber(config.max_line_size), "max_line_size should be number" if config.max_line_size?
  assert.ok us.isNumber(config.buffer_size), "buffer_size should be number" if config.buffer_size?
  assert.ok us.isNumber(config.refresh_interval), "refresh_interval should be number" if config.refresh_interval?
  assert.ok us.isNumber(config.save_posotion_interval), "save_posotion_interval should be number" if config.save_posotion_interval?

  _max_size = config.max_size ? 0
  _max_line_size = config.max_line_size ? 5000
  _buffer_size = config.buffer_size ? 1024 * 1024
  _refresh_interval = config.refresh_interval ? 3000
  _save_posotion_interval = config.save_posotion_interval ? 10000
  _encoding = config.encoding || 'utf-8'

  # save the current watching file, 
  # key is the path, value is tail object
  _watching = {}

  # dirty db
  _posdb = null

  # intervalObj of refresh interval
  _interval = null
  _save_posotion_interval_obj = null

  # inodes save the the set of inode of last flush
  # we can use this to check if new found files
  # is just a rename old file, e.g web.log name to web.log.1
  # we shouldn't treat web.log.1 as a new file as from start
  # , instead we should read if from end
  _inodes = []

  _emit = null

  ## return {inode: xx, pos: xx} ##
  _unwatch = (f) ->
    mem = _watching[f].unwatch()
    delete _watching[f] 
    return mem

  _matched_files = () ->
    result = []
    for p in _paths
      result = result.concat(glob.sync(p).map((f) -> path.resolve(f)))

    result = result.filter (f) -> fs.statSync(f).isFile()
    return us.uniq result

  _refresh = (line_listener) ->
    curr_files = us.keys(_watching)
    new_files = _matched_files()

    to_add = us.difference(new_files, curr_files)
    to_remove = us.difference(curr_files, new_files)

    async.map new_files
    , (f, callback) ->
        fs.stat f, (err, stat) ->
          return callback(err)  if err
          callback(null, stat.ino)

    , (err, stats) ->
        throw err if err
        new_inodes = us.object new_files, stats

        for f in to_add
          logger.info "new file was found, adding wathcing list, #{f}"

          inode = new_inodes[f]
          ## null indicate read file from tail 
          [start, maxSize] = if us.contains(_inodes, inode) then [null,0] else [0, _max_size]
          tail_options = 
            start: start 
            maxSize: maxSize 
            bufferSize: _buffer_size
            encoding: _encoding
            maxLineSize: _max_line_size

          logger.info "tail file #{f} by #{JSON.stringify tail_options}"
          _watching[f] = new Tail(f, tail_options)
          do (f) ->
            _watching[f].on 'line', (line) ->
              line_listener f, line, (err, emit_data) ->
                _emit emit_data            

        _inodes = us.union(_inodes, us.values(new_inodes))
        for f in to_remove
          logger.info "old file is removing from wathcing list, #{f}"
          _unwatch(f)

  _this = {

    line : (file, line, callback) ->
      file_key = config.file_key or "file"
      message_key = config.message_key or "message"

      record = {}
      record[file_key]  = file
      record[message_key] = line

      callback null, {
        tag: config.tag
        time: (new Date()).getTime()
        record: record
      }

    start : (emit, callback) ->
      _emit = emit
      _posdb = new NeDB({filename: config.pos_file})
      _posdb.loadDatabase (err) ->
        return callback(err) if err
        _posdb.ensureIndex {fieldName: "key", unique: true}, (err) ->
          return callback(err) if err
          async.each _matched_files(), (f, callback) ->
            _inodes.push(fs.statSync(f).ino)
            _posdb.findOne {'key': f}, (err, doc) ->
              return callback(err) if err
              mem = doc?.val
              if mem
                tail_options = 
                  start: mem.pos 
                  inode: mem.inode 
                  maxSize: _max_size
                  maxLineSize: _max_line_size
                  bufferSize: _buffer_size
                  encoding: _encoding
              else
                tail_options = 
                  maxLineSize: _max_line_size
                  bufferSize: _buffer_size 
                  encoding: _encoding

              logger.info "tail file #{f} by #{JSON.stringify tail_options}"
              _watching[f] = new Tail(f, tail_options)
              _watching[f].on 'line', (line) ->
                _this.line f, line, (err, emit_data) ->
                  _emit emit_data
              callback()
          , (err) ->
            return callback(err) if err
            _interval = setInterval(_refresh, _refresh_interval , _this.line) 
            _save_posotion_interval_obj = setInterval () ->
              _posdb.persistence.compactDatafile() 
              for [file, tail] in us.pairs(_watching)
                _posdb.update {key: file}, {'$set': {val: tail.where()}}, {upsert: true}
            , _save_posotion_interval

            callback()

    shutdown : (callback) ->
      if _interval
        clearInterval(_interval)
      if _save_posotion_interval_obj
        clearInterval(_save_posotion_interval_obj)

      async.each us.pairs(_watching)
      , ([file, tail], callback) ->
          _posdb.update {key: file}, {'$set': {val: _unwatch(file)}}, {upsert: true}, callback
      , (err) ->
          # _posdb.close()
          callback()
  }

  return _this