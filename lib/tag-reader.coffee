{fs, Task} = require 'atom'
ctags = require 'ctags'
Q = require 'q'

handlerPath = require.resolve('./load-tags-handler')

module.exports =
getTagsFile: (project) ->
  tagsFile = project.resolve("tags") or project.resolve("TAGS")
  return tagsFile if fs.isFileSync(tagsFile)

find: (editor) ->
  word = editor.getTextInRange(editor.getCursor().getCurrentWordBufferRange())
  return [] unless word.length > 0

  tagsFile = @getTagsFile(atom.project)
  return [] unless tagsFile

  ctags.findTags(tagsFile, word)

getAllTags: (project, callback) ->
  deferred = Q.defer()

  task = new Task(handlerPath)
  task.start project.getPath(), (tags) ->
    deferred.resolve(tags)
    task.terminate()

  deferred.promise
