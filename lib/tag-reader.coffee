{Task} = require 'atom'
ctags = require 'ctags'
async = require 'async'
getTagsFile = require "./get-tags-file"
_ = require 'underscore-plus'

handlerPath = require.resolve './load-tags-handler'

wordAtCursor = (text, cursorIndex, wordSeparator) ->
  beforeCursor = text.slice(0, cursorIndex)
  afterCursor = text.slice(cursorIndex)
  beforeCursorWordBegins = beforeCursor.lastIndexOf(wordSeparator) + 1
  afterCursorWordEnds = afterCursor.indexOf(wordSeparator)
  afterCursorWordEnds = afterCursor.length if afterCursorWordEnds is -1
  beforeCursor.slice(beforeCursorWordBegins) + afterCursor.slice(0, afterCursorWordEnds)

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
        nonWordCharacters = editor.config.get 'editor.nonWordCharacters', {scope}
        # Allow special handling for fully-qualified ruby constants
        nonWordCharacters = nonWordCharacters.replace(/:/g, '')
        new RegExp("[^\\s#{_.escapeRegExp nonWordCharacters}]+([!?]|\\s*=>?)?|[<=>]+", 'g')
      else
        cursor.wordRegExp()

      addSymbol = (symbol) ->
        if rubyScopes.length
          # Normalize assignment syntax
          symbols.push symbol.replace(/\s+=$/, '=') if /\s+=?$/.test(symbol)
          # Strip away assignment & hashrocket syntax
          symbols.push symbol.replace(/\s+=>?$/, '')
        else
          symbols.push symbol

      # Can't use `getCurrentWordBufferRange` here because we want to select
      # the last match of the potential 2 matches under cursor.
      editor.scanInBufferRange wordRegExp, cursor.getCurrentLineBufferRange(), ({range, match}) ->
        if range.containsPoint(cursorPosition)
          symbol = match[0]
          addSymbol symbol
          if rubyScopes.length and symbol.indexOf(':') > -1
            # Beside fully-qualified Ruby constant, also look up the bare word under cursor
            addSymbol wordAtCursor(symbol, cursorPosition.column - range.start.column, ':')

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
