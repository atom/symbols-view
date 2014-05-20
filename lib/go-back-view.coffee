SymbolsView = require './symbols-view'

module.exports =
class GoBackView extends SymbolsView
  toggle: =>
    return if @stack.length is 0

    top = @stack.pop()
    atom.workspaceView.open(top.file).done =>
      @moveToPosition(top.position, false) if top.position
