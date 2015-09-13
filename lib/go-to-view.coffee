path = require 'path'
SymbolsView = require './symbols-view'
TagReader = require './tag-reader'

module.exports =
class GoToView extends SymbolsView
  toggle: ->
    if @panel.isVisible()
      @cancel()
    else
      @populate()

  detached: ->
    @resolveFindTagPromise?([])

  findTag: (editor) ->
    @resolveFindTagPromise?([])

    new Promise (resolve, reject) =>
      @resolveFindTagPromise = resolve
      TagReader.find editor, (error, matches=[]) ->
        if error
          reject(error)
        else
          resolve(matches)

  populate: ->
    editor = atom.workspace.getActiveTextEditor()
    return unless editor?

    @findTag(editor).then (matches) =>
      tags = []
      for match in matches
        position = @getTagLine(match)
        continue unless position
        match.name = path.basename(match.file)
        tags.push(match)

      if tags.length is 1
        @openTag(tags[0])
      else if tags.length > 0
        @setItems(tags)
        @attach()
