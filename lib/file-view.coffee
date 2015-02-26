{$$} = require 'atom-space-pen-views'
{CompositeDisposable} = require 'atom'
SymbolsView = require './symbols-view'
TagGenerator = require './tag-generator'

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
      editor.onDidDestroy => editorSubscriptions.dispose()

  destroy: ->
    @editorsSubscription.dispose()
    super

  viewForItem: ({position, name}) ->
    $$ ->
      @li class: 'two-lines', =>
        @div name, class: 'primary-line'
        @div "Line #{position.row + 1}", class: 'secondary-line'

  selectItemView: ->
    super
    item = @getSelectedItem()
    @openTag(item) if item?

  cancelled: ->
    super
    if @initialState?
      @deserializeEditorState(@initialState)

  toggle: ->
    if @panel.isVisible()
      @cancel()
    else if filePath = @getPath()
      if editor = atom.workspace.getActiveTextEditor()
        @initialState = @serializeEditorState()
      @populate(filePath)
      @attach()

  serializeEditorState: ->
    editor = atom.workspace.getActiveTextEditor()
    bufferRanges: editor?.getSelectedBufferRanges()
    scrollTop: editor?.getScrollTop()

  deserializeEditorState: (state) ->
    {bufferRanges, scrollTop} = state
    editor = atom.workspace.getActiveTextEditor()
    editor?.setSelectedBufferRanges(bufferRanges)
    editor?.setScrollTop(scrollTop)

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
