{CompositeDisposable, File} = require 'atom'
humanize = require 'humanize-plus'
SymbolsView = require './symbols-view'
TagReader = require './tag-reader'
getTagsFile = require './get-tags-file'

module.exports =
class ProjectView extends SymbolsView
  initialize: ->
    super
    @reloadTags = true
    @setMaxItems(10)

  destroy: ->
    @stopTask()
    @unwatchTagsFiles()
    super

  toggle: ->
    if @panel.isVisible()
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

    @watchTagsFiles()

  watchTagsFiles: ->
    @unwatchTagsFiles()

    @tagsFileSubscriptions = new CompositeDisposable()
    reloadTags = =>
      @reloadTags = true
      @watchTagsFiles()

    for projectPath in atom.project.getPaths()
      if tagsFilePath = getTagsFile(projectPath)
        tagsFile = new File(tagsFilePath)
        @tagsFileSubscriptions.add(tagsFile.onDidChange(reloadTags))
        @tagsFileSubscriptions.add(tagsFile.onDidDelete(reloadTags))
        @tagsFileSubscriptions.add(tagsFile.onDidRename(reloadTags))

    return

  unwatchTagsFiles: ->
    @tagsFileSubscriptions?.dispose()
    @tagsFileSubscriptions = null
