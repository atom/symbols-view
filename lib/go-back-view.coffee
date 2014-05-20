SymbolsView = require './symbols-view'

module.exports =
class GoBackView extends SymbolsView
  toggle: ->
    previousTag = @stack.pop()
    return unless previousTag?

    atom.workspaceView.open(previousTag.file).done =>
      @moveToPosition(previousTag.position, false) if previousTag.position
