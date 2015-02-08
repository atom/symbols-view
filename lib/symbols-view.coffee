path = require 'path'
{Point} = require 'atom'
{$$, SelectListView} = require 'atom-space-pen-views'
fs = require 'fs-plus'

module.exports =
class SymbolsView extends SelectListView
  @activate: ->
    new SymbolsView

  initialize: (@stack) ->
    super
    @panel = atom.workspace.addModalPanel(item: this, visible: false)
    @addClass('symbols-view')

  destroy: ->
    @cancel()
    @panel.destroy()

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

  cancelled: ->
    @panel.hide()

  confirmed : (tag) ->
    @cancel()
    @openTag(tag)

  openTag: (tag) ->
    if tag.file and not fs.isFileSync(atom.project.getDirectories()[0]?.resolve(tag.file))
      @setError('Selected file does not exist')
      setTimeout((=> @setError()), 2000)
    else
      if editor = atom.workspace.getActiveTextEditor()
        previous =
          position: editor.getCursorBufferPosition()
          file: editor.getURI()

      {position} = tag
      position = @getTagLine(tag) unless position
      if tag.file
        atom.workspace.open(tag.file).done =>
          @moveToPosition(position) if position
      else if position and not (previous.position.isEqual(position))
        @moveToPosition(position)

      @stack.push(previous)

  moveToPosition: (position, beginningOfLine=true) ->
    if editor = atom.workspace.getActiveTextEditor()
      editor.scrollToBufferPosition(position, center: true)
      editor.setCursorBufferPosition(position)
      editor.moveToFirstCharacterOfLine() if beginningOfLine

  attach: ->
    @storeFocusedElement()
    @panel.show()
    @focusFilterEditor()

  getTagLine: (tag) ->
    # Remove leading /^ and trailing $/
    pattern = tag.pattern?.replace(/(^^\/\^)|(\$\/$)/g, '').trim()

    return unless pattern
    file = atom.project.getDirectories()[0]?.resolve(tag.file)
    return unless fs.isFileSync(file)
    for line, index in fs.readFileSync(file, 'utf8').split('\n')
      return new Point(index, 0) if pattern is line.trim()
