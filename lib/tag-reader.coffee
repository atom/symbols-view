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
    if editor.getCursor().getScopes().indexOf('source.ruby') isnt -1
      # Include ! and ? in word regular expression for ruby files
      range = editor.getCursor().getCurrentWordBufferRange(wordRegex: /[\w!?]*/g)
    else
      range = editor.getCursor().getCurrentWordBufferRange()
    symbol = editor.getTextInRange(range)

    tagsFile = @getTagsFile()

    if symbol?.length > 0 and tagsFile
      ctags.findTags(tagsFile, symbol, callback)
    else
      process.nextTick -> callback(null, [])

  getAllTags: (callback) ->
    projectTags = []
    [projectPath] = atom.project.getPaths()
    task = Task.once handlerPath, projectPath, -> callback(projectTags)
    task.on 'tags', (paths) -> projectTags.push(paths...)
    task
