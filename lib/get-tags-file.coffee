path = require 'path'
fs = require 'fs-plus'

module.exports = (directoryPath) ->
  return unless directoryPath?

  tagsFile = path.join(directoryPath, "tags")
  return tagsFile if fs.isFileSync(tagsFile)

  tagsFile = path.join(directoryPath, "TAGS")
  return tagsFile if fs.isFileSync(tagsFile)

  tagsFile = path.join(directoryPath, ".tags")
  return tagsFile if fs.isFileSync(tagsFile)

  tagsFile = path.join(directoryPath, ".TAGS")
  return tagsFile if fs.isFileSync(tagsFile)
