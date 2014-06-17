{Task} = require 'atom'
ctags = require 'ctags'
fs = require 'fs-plus'

handlerPath = require.resolve('./load-tags-handler')

module.exports =
  getTagsFile: ->
    tagsFile = atom.project.resolve("tags")
    return tagsFile if fs.isFileSync(tagsFile)

    tagsFile = atom.project.resolve(".tags")
    return tagsFile if fs.isFileSync(tagsFile)

    tagsFile = atom.project.resolve("TAGS")
    return tagsFile if fs.isFileSync(tagsFile)

  find: (editor, callback) ->
    range = editor.getCursor().getCurrentWordBufferRange()
    symbol = getSymbolFromRange(editor, range)

    tagsFile = @getTagsFile()

    if symbol?.length > 0 and tagsFile
      ctags.findTags(tagsFile, symbol, callback)
    else
      process.nextTick -> callback(null, [])

  getAllTags: (callback) ->
    projectTags = []
    task = Task.once handlerPath, atom.project.getPath(), -> callback(projectTags)
    task.on 'tags', (paths) -> projectTags.push(paths...)
    task

getSymbolFromRange = (editor, range) ->
  word = editor.getTextInRange(range)
  charAfterWord = getCharAfterWord(editor, range)

  if charAfterWord == "?" or charAfterWord == "!"
    return word + charAfterWord
  else
    return word

getCharAfterWord = (editor, range) ->
  return editor.getTextInRange([[range.end.row, range.end.column], [range.end.row, range.end.column + 1]])
