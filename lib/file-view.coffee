{$$} = require 'atom-space-pen-views'
{CompositeDisposable} = require 'atom'
SymbolsView = require './symbols-view'
TagGenerator = require './tag-generator'
{match} = require 'fuzzaldrin'

module.exports =
class FileView extends SymbolsView
  initialize: ->
    super

    @cachedTags = {}

    @editorsSubscription = atom.workspace.observeTextEditors (editor) =>
      removeFromCache = => delete @cachedTags[editor.getPath()]
      editorSubscriptions = new CompositeDisposable()
      editorSubscriptions.add(editor.onDidChangeGrammar(removeFromCache))
      editorSubscriptions.add(editor.onDidSave(removeFromCache))
      editorSubscriptions.add(editor.onDidChangePath(removeFromCache))
      editorSubscriptions.add(editor.getBuffer().onDidReload(removeFromCache))
      editorSubscriptions.add(editor.getBuffer().onDidDestroy(removeFromCache))
      editor.onDidDestroy -> editorSubscriptions.dispose()

  destroy: ->
    @editorsSubscription.dispose()
    super

  viewForItem: ({position, name}) ->
    # Style matched characters in search results
    filterQuery = @getFilterQuery()
    matches = match(name, filterQuery)

    $$ ->
      highlighter = (name, matches, offsetIndex) =>
        lastIndex = 0
        matchedChars = [] # Build up a set of matched chars to be more semantic

        for matchIndex in matches
          matchIndex -= offsetIndex
          continue if matchIndex < 0 # If marking up the basename, omit name matches
          unmatched = name.substring(lastIndex, matchIndex)
          if unmatched
            @span matchedChars.join(''), class: 'character-match' if matchedChars.length
            matchedChars = []
            @text unmatched
          matchedChars.push(name[matchIndex])
          lastIndex = matchIndex + 1

        @span matchedChars.join(''), class: 'character-match' if matchedChars.length

        # Remaining characters are plain text
        @text name.substring(lastIndex)

      @li class: 'two-lines', =>
        @div class: 'primary-line', -> highlighter(name, matches, 0)
        @div "Line #{position.row + 1}", class: 'secondary-line'

  toggle: ->
    if @panel.isVisible()
      @cancel()
    else if filePath = @getPath()
      @populate(filePath)
      @attach()

  getPath: -> atom.workspace.getActiveTextEditor()?.getPath()

  getScopeName: -> atom.workspace.getActiveTextEditor()?.getGrammar()?.scopeName

  populate: (filePath) ->
    @list.empty()
    @setLoading('Generating symbols\u2026')
    if tags = @cachedTags[filePath]
      @setMaxItems(Infinity)
      @setItems(tags)
    else
      @generateTags(filePath)

  generateTags: (filePath) ->
    new TagGenerator(filePath, @getScopeName()).generate().done (tags) =>
      @cachedTags[filePath] = tags
      @setMaxItems(Infinity)
      @setItems(tags)
