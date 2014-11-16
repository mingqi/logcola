async = require 'uclogs-async'
us = require 'underscore'
fs = require 'fs'
path = require 'path'
mkdirp = require 'mkdirp'
OutputBuffer = require '../buffer'

empty_cb = `function (err){}`

module.exports = (config) ->
  _ttl = config.ttl
  _path = config.path

  _open_file = (file_path, callback) ->
    dir = path.dirname file_path 
    fs.exists dir, (exists) ->
      if exists  # dir exists
        fs.exists file_path, (exists) ->
          if exists
            fs.stat file_path, (err, stats) ->
              if not stats.isFile()
                throw new Error("file #{file_path} is not a regular file") 
              fs.open file_path, 'a', callback
          else
            fs.open file_path, 'a', callback
      else
        mkdirp dir, (err) ->
          return callback err if err
          fs.open file_path, 'a', callback


  _buffer = OutputBuffer(config)
  _buffer.writeChunk = (chunk, callback) ->
    async.eachSeries us.pairs(us.groupBy(chunk, _this.path)), ([filepath, sub_chunk], callback) ->
      _open_file filepath, (err, fd) ->
        if err
          logger.error err
          return callback(err) 
        async.eachSeries sub_chunk, (data, callback) ->
          buff = new Buffer(JSON.stringify(data)+"\n")
          fs.write fd, buff, 0, buff.length, null, (err) ->
            if err
              logger.error err if err
              return callback(err) 
            callback()
        , (err) ->
            fs.close fd
            callback(err)
        
    , callback
    
  _this = 

    path : (data) ->
      _path

    start : (callback) ->
      callback()

    write : _buffer.write  
    
   
    shutdown : (callback) ->
      _buffer.stop () ->
        _pool.destroy (err) ->
      
  return _this
