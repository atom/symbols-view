path = require 'path'
Q = require 'q'
SymbolsView = require './symbols-view'
TagReader = require './tag-reader'

module.exports =
class GoToView extends SymbolsView
  toggle: ->
    if @panel.isVisible()
      @cancel()
    else
      @populate()

  beforeRemove: ->
    @deferredFind?.resolve([])

  findTag: (editor) ->
    @deferredFind?.resolve([])

    deferred = Q.defer()
    TagReader.find editor, (error, matches=[]) -> deferred.resolve(matches)
    @deferredFind = deferred
    @deferredFind.promise

  populate: ->
    editor = atom.workspace.getActiveTextEditor()
    return unless editor?

    @findTag(editor).then (matches) =>
      tags = []
      for match in matches
        position = @getTagLine(match)
        continue unless position
        tags.push
          file: match.file
          name: path.basename(match.file)
          position: position

      if tags.length is 1
        @openTag(tags[0])
      else if tags.length > 0
        @setItems(tags)
        @attach()
