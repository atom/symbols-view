async = require 'async'
ctags = require 'ctags'
getTagsFile = require './get-tags-file'

module.exports = (tagDirectoryObjects) ->
  async.each(
    tagDirectoryObjects,
    ({tagsPath, projectPath}, done) ->
      tagsFilePath = getTagsFile(tagsPath)
      return done() unless tagsFilePath

      stream = ctags.createReadStream(tagsFilePath)
      stream.on 'data', (tags) ->
        for tag in tags
          tag.projectPath = projectPath
          tag.directory = tagsPath
        emit('tags', tags)
      stream.on('end', done)
      stream.on('error', done)
    , @async()
  )
