{Task} = require 'atom'
ctags = require 'ctags'
fs = require 'fs-plus'

handlerPath = require.resolve('./load-tags-handler')

module.exports =
  getTagsFile: ->
    tagsFile = atom.project.resolve("tags")
    return tagsFile if fs.isFileSync(tagsFile)

    tagsFile = atom.project.resolve("TAGS")
    return tagsFile if fs.isFileSync(tagsFile)

  find: (editor, callback) ->
    word = editor.getTextInRange(editor.getCursor().getCurrentWordBufferRange())
    tagsFile = @getTagsFile()

    if word?.length > 0 and tagsFile
      ctags.findTags(tagsFile, word, callback)
    else
      process.nextTick -> callback(null, [])

  getAllTags: (callback) ->
    projectTags = []
    task = Task.once handlerPath, atom.project.getPath(), -> callback(projectTags)
    task.on 'tags', (paths) -> projectTags.push(paths...)
    task
