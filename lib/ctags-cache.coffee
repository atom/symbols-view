
TagGenerator = null
matchOpt = {matchBase: true}
module.exports =
  activate: () ->
    @cachedTags = {}
    @extraTags = {}

  deactivate: ->
    @cachedTags = null

  initExtraTags: (paths) ->
    @extraTags = {}
    for path in paths
      path = path.trim()
      continue unless path
      @readTags(path)

  readTags: (path) ->
    if not TagGenerator
      TagGenerator = require './tag-generator'
    new TagGenerator(path).read().done (tags) =>
      for tag in tags
        data = @extraTags[tag.file]
        if not data
          data = []
          @extraTags[tag.file] = data
        data.push tag

  #options = { partialMatch: true, maxItems }
  findTags: (prefix, options) ->
    tags = []
    return tags if @findOf(@cachedTags, tags, prefix, options)
    return tags if @findOf(@extraTags, tags, prefix, options)

    #TODO: prompt in editor
    console.warn("[atom-ctags:findTags] tags empty, did you RebuildTags or set extraTagFiles?") if tags.length == 0
    return tags

  findOf: (source, tags, prefix, options)->
    for key, value of source
      for tag in value
        if options?.partialMatch and tag.name.indexOf(prefix) == 0
            tags.push tag
        else if tag.name == prefix
          tags.push tag
        return true if options?.maxItems and tags.length == options.maxItems
    return false

  generateTags:(path, callback) ->
    delete @cachedTags[path]

    scopeName = atom.workspace.getActiveEditor()?.getGrammar()?.scopeName
    if not TagGenerator
      TagGenerator = require './tag-generator'

    startTime = Date.now()
    console.log "[atom-ctags:rebuild] start @#{path}@ tags..."
    cmdArgs = atom.config.get("atom-ctags.cmdArgs")
    cmdArgs = cmdArgs.split(" ") if cmdArgs
    new TagGenerator(path, scopeName, @cmdArgs || cmdArgs ).generate().done (tags) =>
      console.log "[atom-ctags:rebuild] command done @#{path}@ tags. cost: #{Date.now() - startTime}ms"
      startTime = Date.now()

      for tag in tags
        data = @cachedTags[tag.file]
        if not data
          data = []
          @cachedTags[tag.file] = data
        data.push tag

      console.log "[atom-ctags:rebuild] parse end @#{path}@ tags. cost: #{Date.now() - startTime}ms"
      callback?(tags)

  getOrCreateTags: (filePath, callback) ->
    tags = @cachedTags[filePath]
    return callback?(tags) if tags
    @generateTags(filePath, callback)
