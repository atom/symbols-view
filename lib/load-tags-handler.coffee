async = require 'async'
ctags = require 'ctags'
getTagsFile = require './get-tags-file'

module.exports = (directoryPaths) ->
  async.each(
    directoryPaths,
    (directoryPath, done) ->
      tagsFilePath = getTagsFile(directoryPath)
      return done() unless tagsFilePath

      stream = ctags.createReadStream(tagsFilePath)
      stream.on 'data', (tags) ->
        tag.directory = directoryPath for tag in tags
        emit('tags', tags)
      stream.on('end', done)
      stream.on('error', done)
    , @async()
  )
