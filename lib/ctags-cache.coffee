
TagGenerator = null
matchOpt = {matchBase: true}
module.exports =
  activate: () ->
    @cachedTags = {}

  deactivate: ->
    @cachedTags = null

  #options = { partialMatch: true, maxItems }
  findTags: (prefix, options) ->
    tags = []
    empty = true
    for key, value of @cachedTags
      empty = false
      for tag in value
        if options?.partialMatch and tag.name.indexOf(prefix) == 0
            tags.push tag
        else if tag.name == prefix
          tags.push tag
        return tags if options?.maxItems and tags.length == options.maxItems

    #TODO: prompt in editor
    console.warn("[atom-ctags:findTags] tags empty, did you RebuildTags?") if empty
    return tags

  generateTags:(path, callback) ->
    delete @cachedTags[path]

    scopeName = atom.workspace.getActiveEditor()?.getGrammar()?.scopeName
    if not TagGenerator
      TagGenerator = require './tag-generator'

    startTime = Date.now()
    console.log "[atom-ctags:rebuild] start @#{path}@ tags..."
    new TagGenerator(path, scopeName, @cmdArgs || atom.config.get("atom-ctags.cmdArgs") ).generate().done (tags) =>
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
