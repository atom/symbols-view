path = require 'path'
Q = require 'q'
SymbolsView = require './symbols-view'
TagReader = require './tag-reader'

module.exports =
class GoToView extends SymbolsView
  toggle: ->
    if @hasParent()
      @cancel()
    else
      @populate()

  beforeRemove: ->
    @deferredFind?.resolve([])

  findTag: ->
    @deferredFind?.resolve([])

    deferred = Q.defer()
    editor = atom.workspaceView.getActivePaneItem()
    TagReader.find editor, (error, matches=[]) -> deferred.resolve(matches)
    @deferredFind = deferred
    @deferredFind.promise

  populate: ->
    @findTag().then (matches) =>
      if matches.length is 1
        position = @getTagLine(matches[0])
        @openTag(file: matches[0].file, position: position) if position
      else if matches.length > 0
        tags = []
        for match in matches
          position = @getTagLine(match)
          continue unless position
          tags.push
            file: match.file
            name: path.basename(match.file)
            position: position
        @setItems(tags)
        @attach()
