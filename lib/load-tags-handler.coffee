async = require 'async'
path = require 'path'
ctags = require 'ctags'
fs = require 'fs-plus'

getTagsFile = (directoryPath) ->
  tagsFile = path.join(directoryPath, "tags")
  return tagsFile if fs.isFileSync(tagsFile)

  tagsFile = path.join(directoryPath, ".tags")
  return tagsFile if fs.isFileSync(tagsFile)

  tagsFile = path.join(directoryPath, "TAGS")
  return tagsFile if fs.isFileSync(tagsFile)

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
