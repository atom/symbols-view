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

    @relativeTagsDirectoryWatcher = atom.config.onDidChange 'symbols-view.tagsDirectory', (newValue) =>
      @triggerReloadTags()

  destroy: ->
    @stopTask()
    @unwatchTagsFiles()
    @relativeTagsDirectoryWatcher.dispose()
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

  triggerReloadTags: ->
    @reloadTags = true
    @watchTagsFiles()

  watchTagsFiles: ->
    @unwatchTagsFiles()

    @tagsFileSubscriptions = new CompositeDisposable()

    relativeTagsDirectory = atom.config.get('symbols-view.tagsDirectory')
    for {tagsPath} in TagReader.getTagsPaths(relativeTagsDirectory)
      if tagsFilePath = getTagsFile(tagsPath)
        tagsFile = new File(tagsFilePath)
        @tagsFileSubscriptions.add(tagsFile.onDidChange(=> @triggerReloadTags()))
        @tagsFileSubscriptions.add(tagsFile.onDidDelete(=> @triggerReloadTags()))
        @tagsFileSubscriptions.add(tagsFile.onDidRename(=> @triggerReloadTags()))

    return

  unwatchTagsFiles: ->
    @tagsFileSubscriptions?.dispose()
    @tagsFileSubscriptions = null
