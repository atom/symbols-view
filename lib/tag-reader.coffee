{Task} = require 'atom'
ctags = require 'ctags'
async = require 'async'
getTagsFile = require "./get-tags-file"
_ = require 'underscore-plus'

handlerPath = require.resolve './load-tags-handler'

module.exports =
  find: (editor, callback) ->
    symbols = []

    if symbol = editor.getSelectedText()
      symbols.push symbol

    unless symbols.length
      cursor = editor.getLastCursor()
      cursorPosition = cursor.getBufferPosition()
      scope = cursor.getScopeDescriptor()
      rubyScopes = scope.getScopesArray().filter (s) -> /^source\.ruby($|\.)/.test(s)

      wordRegExp = if rubyScopes.length
        nonWordCharacters = _.escapeRegExp(editor.config.get('editor.nonWordCharacters', {scope}))
        new RegExp("[^\\s#{nonWordCharacters}]+([!?]|\\s*=)?|[<=>]+", 'g')
      else
        cursor.wordRegExp()

      # Can't use `getCurrentWordBufferRange` here because we want to select
      # the last match of the potential 2 matches under cursor.
      editor.scanInBufferRange wordRegExp, cursor.getCurrentLineBufferRange(), ({range, match}) ->
        if range.containsPoint(cursorPosition)
          symbol = match[0]
          if /\s+=$/.test(symbol)
            symbols.push symbol.replace(/\s+=$/, '=')
            symbols.push symbol.replace(/\s+=$/, '')
          else
            symbols.push symbol

    unless symbols.length
      return process.nextTick -> callback(null, [])

    async.map(
      atom.project.getPaths(),
      (projectPath, done) ->
        tagsFile = getTagsFile(projectPath)
        foundTags = []
        foundErr = null
        detectCallback = -> done(foundErr, foundTags)
        return detectCallback() unless tagsFile?
        # Find the first symbol in the list that matches a tag
        async.detectSeries symbols,
          (symbol, doneDetect) ->
            ctags.findTags tagsFile, symbol, (err, tags=[]) ->
              if err
                foundErr = err
                doneDetect false
              else if tags.length
                tag.directory = projectPath for tag in tags
                foundTags = tags
                doneDetect true
              else
                doneDetect false
          detectCallback
      (err, foundTags) ->
        callback err, _.flatten(foundTags)
    )

  getAllTags: (callback) ->
    projectTags = []
    task = Task.once handlerPath, atom.project.getPaths(), -> callback(projectTags)
    task.on 'tags', (tags) -> projectTags.push(tags...)
    task
