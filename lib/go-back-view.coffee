SymbolsView = require './symbols-view'

module.exports =
class GoBackView extends SymbolsView
  toggle: ->
    previousTag = @stack.pop()
    return unless previousTag?

    atom.workspace.open(previousTag.file).then =>
      @moveToPosition(previousTag.position, false) if previousTag.position
