{Task} = require 'atom'
ctags = require 'ctags'
async = require 'async'
getTagsFile = require "./get-tags-file"

handlerPath = require.resolve './load-tags-handler'

module.exports =
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
        tagsFile = getTagsFile(projectPath)
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
