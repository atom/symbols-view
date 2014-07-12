{$$} = require 'atom'
SymbolsView = require './symbols-view'

module.exports =
class FileView extends SymbolsView
  initialize: ->
    super
    @subscribe atom.project.eachBuffer (buffer) =>
      @subscribe buffer, 'after-will-be-saved', =>
        return unless buffer.isModified()
        f = buffer.getPath()
        return unless atom.project.contains(f)
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

  toggleAll: ->
    if @hasParent()
      @cancel()
    else
      @list.empty()
      @maxItems = 10
      tags = []
      for key, val of @ctagsCache.cachedTags
        tags.push val...
      @setItems(tags)
      @attach()

  getCurSymbol: ->
    editor = atom.workspace.getActiveEditor()
    if not editor
      console.error "[atom-ctags:getCurSymbol] failed getActiveEditor "
      return

    if editor.getCursor().getScopes().indexOf('source.ruby') isnt -1
      # Include ! and ? in word regular expression for ruby files
      range = editor.getCursor().getCurrentWordBufferRange(wordRegex: /[\w!?]*/g)
    else
      range = editor.getCursor().getCurrentWordBufferRange()
    return editor.getTextInRange(range)

  rebuild: ->
    projectPath = atom.project.getPath()
    if not projectPath
      console.error "[atom-ctags:rebuild] cancel rebuild, invalid projectPath: #{projectPath}"
      return
    @ctagsCache.cachedTags = {}
    @ctagsCache.generateTags projectPath

  goto: ->
    symbol = @getCurSymbol()
    if not symbol
      console.error "[atom-ctags:goto] failed getCurSymbol"
      return

    tags = @ctagsCache.findTags(symbol)

    if tags.length is 1
      @openTag(tags[0])
    else
      @setItems(tags)
      @attach()

  getPath: -> atom.workspace.getActiveEditor()?.getPath()

  populate: (filePath) ->
    @list.empty()
    @setLoading('Generating symbols\u2026')

    @ctagsCache.getOrCreateTags filePath, (tags) =>
      @maxItem = Infinity
      @setItems(tags)
