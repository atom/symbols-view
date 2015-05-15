{CompositeDisposable}  = require 'atom'
{Selector} = require 'selector-kit'

module.exports =
class CtagsProvider
  selector: '*'
  inclusionPriority: 0
  suggestionPriority: 0

  constructor: ->
    @subscriptions = new CompositeDisposable

  dispose: =>
    @subscriptions.dispose()
