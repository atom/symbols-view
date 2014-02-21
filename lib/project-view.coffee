humanize = require 'humanize-plus'
SymbolsView = require './symbols-view'
TagReader = require './tag-reader'

module.exports =
class ProjectView extends SymbolsView
  initialize: ->
    super
    @reloadTags = true
    @maxItems = 10

  beforeRemove: ->
    @loadTagsTask?.terminate()

  toggle: ->
    if @hasParent()
      @cancel()
    else
      @populate()
      @attach()

  getEmptyMessage: (itemCount) ->
    if itemCount is 0
      'Project has no tags file or it is empty'
    else
      super

  populate: ->
    if @tags
      @setItems(@tags)

    if @reloadTags
      @reloadTags = false
      @loadTagsTask?.terminate()
      @loadTagsTask = TagReader.getAllTags (@tags) => @populate()

      if @tags
        @setLoading("Reloading project symbols\u2026")
      else
        @setLoading('Loading project symbols\u2026')
        @loadingBadge.text('0')
        tagsRead = 0
        @loadTagsTask.on 'tags', (tags) =>
          tagsRead += tags.length
          @loadingBadge.text(humanize.intComma(tagsRead))
