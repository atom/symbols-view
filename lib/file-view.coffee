{$$} = require 'atom-space-pen-views'
{CompositeDisposable} = require 'atom'
SymbolsView = require './symbols-view'
TagGenerator = require './tag-generator'
{match} = require 'fuzzaldrin'

# TODO: remove references to logical display buffer when it is released.

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

  selectItemView: ->
    super
    if atom.config.get('symbols-view.quickJumpToFileSymbol')
      item = @getSelectedItem()
      @openTag(item) if item?

  cancelled: ->
    super
    if @initialState? and editor = @getEditor()
      @deserializeEditorState(editor, @initialState)
    @initialState = null

  toggle: ->
    if @panel.isVisible()
      @cancel()
    else if filePath = @getPath()
      if atom.config.get('symbols-view.quickJumpToFileSymbol') and editor = @getEditor()
        @initialState = @serializeEditorState(editor)
      @populate(filePath)
      @attach()

  serializeEditorState: (editor) ->
    editorElement = atom.views.getView(editor)
    if editorElement.logicalDisplayBuffer
      scrollTop = editorElement.getScrollTop()
    else
      scrollTop = editor.getScrollTop()

    bufferRanges: editor.getSelectedBufferRanges()
    scrollTop: scrollTop

  deserializeEditorState: (editor, {bufferRanges, scrollTop}) ->
    editorElement = atom.views.getView(editor)

    editor.setSelectedBufferRanges(bufferRanges)
    if editorElement.logicalDisplayBuffer
      editorElement.setScrollTop(scrollTop)
    else
      editor.setScrollTop(scrollTop)

  getEditor: -> atom.workspace.getActiveTextEditor()

  getPath: -> @getEditor()?.getPath()

  getScopeName: -> @getEditor()?.getGrammar()?.scopeName

  populate: (filePath) ->
    @list.empty()
    @setLoading('Generating symbols\u2026')
    if tags = @cachedTags[filePath]
      @setMaxItems(Infinity)
      @setItems(tags)
    else
      @generateTags(filePath)

  generateTags: (filePath) ->
    new TagGenerator(filePath, @getScopeName()).generate().then (tags) =>
      @cachedTags[filePath] = tags
      @setMaxItems(Infinity)
      @setItems(tags)
