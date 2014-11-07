{File} = require 'pathwatcher'
humanize = require 'humanize-plus'
SymbolsView = require './symbols-view'
TagReader = require './tag-reader'

module.exports =
class ProjectView extends SymbolsView
  initialize: ->
    super
    @reloadTags = true
    @setMaxItems(10)

  beforeRemove: ->
    @stopTask()
    @unwatchTagsFile()

  toggle: ->
    if @hasParent()
      @exit()
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
      @startTask()

      if @tags
        @setLoading("Reloading project symbols\u2026")
      else
        @setLoading('Loading project symbols\u2026')
        @loadingBadge.text('0')
        tagsRead = 0
        @loadTagsTask.on 'tags', (tags) =>
          tagsRead += tags.length
          @loadingBadge.text(humanize.intComma(tagsRead))

  stopTask: ->
    @loadTagsTask?.terminate()

  startTask: ->
    @stopTask()

    @loadTagsTask = TagReader.getAllTags (@tags) =>
      @reloadTags = @tags.length is 0
      @setItems(@tags)

    @watchTagsFile()

  watchTagsFile: ->
    @unwatchTagsFile()

    if tagsFilePath = TagReader.getTagsFile()
      @tagsFile = new File(tagsFilePath)
      @tagsFile.on 'moved removed contents-changed', =>
        @reloadTags = true
        @watchTagsFile()

  unwatchTagsFile: ->
    @tagsFile?.off()
