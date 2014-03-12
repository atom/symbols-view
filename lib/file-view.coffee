SymbolsView = require './symbols-view'
TagGenerator = require './tag-generator'

module.exports =
class FileView extends SymbolsView
  initialize: ->
    super

    @cachedTags = {}

    @subscribe atom.project.eachBuffer (buffer) =>
      @subscribe buffer, 'reloaded saved destroyed path-changed', =>
        delete @cachedTags[buffer.getPath()]

      @subscribe buffer, 'destroyed', =>
        @unsubscribe(buffer)

    @subscribe atom.workspace.eachEditor (editor) =>
      @subscribe editor, 'grammar-changed', =>
        delete @cachedTags[editor.getPath()]

      @subscribe editor, 'destroyed', =>
        @unsubscribe(editor)

  toggle: ->
    if @hasParent()
      @cancel()
    else if filePath = @getPath()
      @populate(filePath)
      @attach()

  getPath: -> atom.workspace.getActiveEditor()?.getPath()

  getScopeName: -> atom.workspace.getActiveEditor()?.getGrammar()?.scopeName

  populate: (filePath) ->
    @list.empty()
    @setLoading('Generating symbols\u2026')
    if tags = @cachedTags[filePath]
      @maxItem = Infinity
      @setItems(tags)
    else
      @generateTags(filePath)

  generateTags: (filePath) ->
    new TagGenerator(filePath, @getScopeName()).generate().done (tags) =>
      @cachedTags[filePath] = tags
      @maxItem = Infinity
      @setItems(tags)
