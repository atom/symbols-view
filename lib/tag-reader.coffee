{Task} = require 'atom'
ctags = require 'ctags'
fs = require 'fs-plus'
path = require 'path'
async = require "async"

handlerPath = require.resolve './load-tags-handler'

module.exports =
  getTagsFile: (directoryPath) ->
    return unless directoryPath?

    tagsFile = path.join(directoryPath, "tags")
    return tagsFile if fs.isFileSync(tagsFile)

    tagsFile = path.join(directoryPath, "TAGS")
    return tagsFile if fs.isFileSync(tagsFile)

    tagsFile = path.join(directoryPath, ".tags")
    return tagsFile if fs.isFileSync(tagsFile)

    tagsFile = path.join(directoryPath, ".TAGS")
    return tagsFile if fs.isFileSync(tagsFile)

  find: (editor, callback) ->
    if editor.getLastCursor().getScopeDescriptor().getScopesArray().indexOf('source.ruby') isnt -1
      # Include ! and ? in word regular expression for ruby files
      range = editor.getLastCursor().getCurrentWordBufferRange(wordRegex: /[\w!?]*/g)
    else
      range = editor.getLastCursor().getCurrentWordBufferRange()

    symbol = editor.getTextInRange(range)

    unless symbol?.length > 0
      return process.nextTick -> callback(null, [])

    allTags = []

    async.each(
      atom.project.getPaths(),
      (projectPath, done) =>
        tagsFile = @getTagsFile(projectPath)
        return done() unless tagsFile?
        ctags.findTags tagsFile, symbol, (err, tags=[]) ->
          tag.directory = projectPath for tag in tags
          allTags.push(tags...)
          done(err)
      (err) -> callback(err, allTags)
    )

  getAllTags: (callback) ->
    projectTags = []
    task = Task.once handlerPath, atom.project.getPaths(), -> callback(projectTags)
    task.on 'tags', (tags) -> projectTags.push(tags...)
    task
