ctags = require 'ctags'
{fs} = require 'atom-api'
path = require 'path'

getTagsFile = (directoryPath) ->
  tagsFile = path.join(directoryPath, "tags")
  return tagsFile if fs.isFileSync(tagsFile)

  tagsFile = path.join(directoryPath, "TAGS")
  return tagsFile if fs.isFileSync(tagsFile)

module.exports = (directoryPath) ->
  tagsFilePath = getTagsFile(directoryPath)
  if tagsFilePath
    ctags.getTags(tagsFilePath)
  else
    []
