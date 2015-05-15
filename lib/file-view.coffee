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
    matches = match(name, @getFilterQuery())

    $$ ->
      @li class: 'two-lines', =>
        @div class: 'primary-line', => FileView.highlightMatches(this, name, matches)
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

  dispose: ->
    @destroy()
