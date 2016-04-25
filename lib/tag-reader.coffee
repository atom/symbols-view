{Task} = require 'atom'
ctags = require 'ctags'
async = require 'async'
getTagsFile = require "./get-tags-file"
_ = require 'underscore-plus'

handlerPath = require.resolve './load-tags-handler'

module.exports =
  find: (editor, callback) ->
    symbol = editor.getSelectedText()

    unless symbol
      cursor = editor.getLastCursor()
      cursorPosition = cursor.getBufferPosition()
      scope = cursor.getScopeDescriptor()
      rubyScopes = scope.getScopesArray().filter (s) -> /^source\.ruby($|\.)/.test(s)

      wordRegExp = if rubyScopes.length
        nonWordCharacters = _.escapeRegExp(editor.config.get('editor.nonWordCharacters', {scope}))
        new RegExp("[^\\s#{nonWordCharacters}]+[!?=]?|[<=>]+", 'g')
      else
        cursor.wordRegExp()

      # Can't use `getCurrentWordBufferRange` here because we want to select
      # the last match of the potential 2 matches under cursor.
      editor.scanInBufferRange wordRegExp, cursor.getCurrentLineBufferRange(), ({range, match}) ->
        symbol = match[0] if range.containsPoint(cursorPosition)

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
