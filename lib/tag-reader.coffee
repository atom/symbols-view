{Task} = require 'atom'
ctags = require 'ctags'
async = require 'async'
getTagsFile = require "./get-tags-file"

handlerPath = require.resolve './load-tags-handler'

module.exports =
  find: (editor, callback) ->
    symbol = editor.getSelectedText()

    unless symbol
      cursor = editor.getLastCursor()
      scopes = cursor.getScopeDescriptor().getScopesArray()
      rubyScopes = scopes.filter (scope) -> /^source\.ruby($|\.)/.test(scope)
      wordRegex = /[a-zA-Z_][\w!?]*/g if rubyScopes.length

      range = cursor.getCurrentWordBufferRange({wordRegex})
      symbol = editor.getTextInRange(range)

    unless symbol
      return process.nextTick -> callback(null, [])

    allTags = []

    async.each(
      atom.project.getPaths(),
      (projectPath, done) ->
        tagsFile = getTagsFile(projectPath)
        return done() unless tagsFile?
        ctags.findTags tagsFile, symbol, (err, tags=[]) ->
          tag.directory = projectPath for tag in tags
          allTags = allTags.concat(tags)
          done(err)
      (err) -> callback(err, allTags)
    )

  getAllTags: (callback) ->
    projectTags = []
    task = Task.once handlerPath, atom.project.getPaths(), -> callback(projectTags)
    task.on 'tags', (tags) -> projectTags.push(tags...)
    task
