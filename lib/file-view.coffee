{$$} = require 'atom'
SymbolsView = require './symbols-view'

module.exports =
class FileView extends SymbolsView
  initialize: ->
    super
    @subscribe atom.project.eachBuffer (buffer) =>
      @subscribe buffer, 'saved path-changed', =>
        f = buffer.getPath()
        @ctagsCache.generateTags(f)

      @subscribe buffer, 'destroyed', =>
        @unsubscribe(buffer)

    @subscribe atom.workspace.eachEditor (editor) =>

      @subscribe editor, 'destroyed', =>
        @unsubscribe(editor)


  viewForItem: ({position, name, file, pattern}) ->
    $$ ->
      @li class: 'two-lines', =>
        @div class: 'primary-line', =>
          @span name, class: 'pull-left'
          @span pattern, class: 'pull-right'

        @div class: 'secondary-line', =>
          @span "Line #{position.row + 1}", class: 'pull-left'
          @span file, class: 'pull-right'

  toggle: ->
    if @hasParent()
      @cancel()
    else if filePath = @getPath()
      @populate(filePath)
      @attach()

  getCurSymbol: ->
    editor = atom.workspace.getActiveEditor()
    return unless editor?

    if editor.getCursor().getScopes().indexOf('source.ruby') isnt -1
      # Include ! and ? in word regular expression for ruby files
      range = editor.getCursor().getCurrentWordBufferRange(wordRegex: /[\w!?]*/g)
    else
      range = editor.getCursor().getCurrentWordBufferRange()
    return editor.getTextInRange(range)

  goto: ->
    symbol = @getCurSymbol()

    return unless symbol?.length > 0

    tags = @ctagsCache.findTags(symbol)
    if tags.length is 1
      @openTag(tags[0])
    else if tags.length > 0
      @setItems(tags)
      @attach()

  getPath: -> atom.workspace.getActiveEditor()?.getPath()

  populate: (filePath) ->
    @list.empty()
    @setLoading('Generating symbols\u2026')

    @ctagsCache.getOrCreateTags filePath, (tags) =>
      @maxItem = Infinity
      @setItems(tags)
