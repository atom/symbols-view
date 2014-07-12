{$$, SelectListView} = require 'atom'
fs = null

module.exports =
class SymbolsView extends SelectListView

  initialize: (@stack) ->
    super
    @addClass('atom-ctags overlay from-top')

  destroy: ->
    @cancel()
    @remove()

  getFilterKey: -> 'name'

  viewForItem: ({position, name, file}) ->
    $$ ->
      @li class: 'two-lines', =>
        if position?
          @div "#{name}:#{position.row + 1}", class: 'primary-line'
        else
          @div name, class: 'primary-line'
        @div file, class: 'secondary-line'

  getEmptyMessage: (itemCount) ->
    if itemCount is 0
      'No symbols found'
    else
      super

  confirmed : (tag) ->
    @cancel()
    @openTag(tag)

  openTag: (tag) ->
    if editor = atom.workspace.getActiveEditor()
      previous =
        position: editor.getCursorBufferPosition()
        file: editor.getUri()

    {position} = tag


    atom.workspaceView.open(tag.file).done =>
      @moveToPosition(position) if position

    @stack.push(previous)

  moveToPosition: (position) ->
    editorView = atom.workspaceView.getActiveView()
    if editor = editorView.getEditor?()
      editorView.scrollToBufferPosition(position, center: true)
      editor.setCursorBufferPosition(position)

  attach: ->
    @storeFocusedElement()
    atom.workspaceView.appendToTop(this)
    @focusFilterEditor()
