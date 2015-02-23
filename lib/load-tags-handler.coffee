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

module.exports = (directoryPath) ->
  tagsFilePath = getTagsFile(directoryPath)
  if tagsFilePath
    callback = @async()
    stream = ctags.createReadStream(tagsFilePath)
    stream.on 'data', (tags) -> emit('tags', tags)
    stream.on('end', callback)
    stream.on('error', callback)
  else
    []
