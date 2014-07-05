
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

  getTagLine: (tag) ->
    file = atom.project.resolve(tag.file)
    if not fs
      fs = require 'fs-plus'

    if not fs.isFileSync(file)
      console.error "[atom-ctags:getTagLine] @#{tag.file}@ not exist?"
      return

    debug = []
    for line, index in fs.readFileSync(file, 'utf8').split('\n')
      if line.indexOf(tag.pattern) == 0
        tag.position.row = index
        return true

    console.error "[atom-ctags:getTagLine] @#{tag.pattern}@ not find in @#{tag.file}@?"
    return true

  generateTags:(path, callback) ->
    delete @cachedTags[path]

    scopeName = atom.workspace.getActiveEditor()?.getGrammar()?.scopeName
    if not TagGenerator
      TagGenerator = require './tag-generator'

    new TagGenerator(path, scopeName).generate().done (tags) =>
      ret = [] if callback
      for tag in tags
        if @getTagLine(tag)
            ret.push tag if callback
          data = @cachedTags[tag.file]
          if not data
            data = []
            @cachedTags[tag.file] = data
          data.push tag

      callback?(ret)

  getOrCreateTags: (filePath, callback) ->
    tags = @cachedTags[filePath]
    return callback?(tags) if tags
    @generateTags(filePath, callback)
