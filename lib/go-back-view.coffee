SymbolsView = require './symbols-view'

module.exports =
class GoBackView extends SymbolsView
  toggle: ->
    previousTag = @stack.pop()
    return unless previousTag?

    restorePosition = =>
      @moveToPosition(previousTag.position, false) if previousTag.position

    previousEditor = atom.workspace.getTextEditors().find (e) -> e.id is previousTag.editorId

    if previousEditor
      pane = atom.workspace.paneForItem(previousEditor)
      pane.setActiveItem(previousEditor)
      restorePosition()
    else if previousTag.file
      atom.workspace.open(previousTag.file).then restorePosition
