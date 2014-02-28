SymbolsView = require './symbols-view'
TagGenerator = require './tag-generator'

module.exports =
class FileView extends SymbolsView
  initialize: ->
    super

    @cachedTags = {}
    atom.project.eachBuffer (buffer) =>
      @subscribe buffer, 'reloaded saved destroyed path-changed', =>
        delete @cachedTags[buffer.getPath()]
      @subscribe buffer, 'destroyed', =>
        @unsubscribe(buffer)

  toggle: ->
    if @hasParent()
      @cancel()
    else if filePath = @getPath()
      @populate(filePath)
      @attach()

  getPath: -> atom.workspace.getActiveEditor()?.getPath()

  populate: (filePath) ->
    @list.empty()
    @setLoading('Generating symbols\u2026')
    if tags = @cachedTags[filePath]
      @maxItem = Infinity
      @setItems(tags)
    else
      @generateTags(filePath)

  generateTags: (filePath) ->
    new TagGenerator(filePath).generate().done (tags) =>
      @cachedTags[filePath] = tags
      @maxItem = Infinity
      @setItems(tags)
