
TagGenerator = require './tag-generator'
fs = require 'fs-plus'
minimatch = require "minimatch"

{Point} = require "atom"

module.exports =
  activate: (build) ->
    @cachedTags = {}

    if build
      @rebuild()

  deactivate: ->
    @cachedTags = null

  #options = { partialMatch: true }
  findTags: (prefix, options) ->
    tags = []
    for key, value of @cachedTags
      tags.push (value.filter (x) ->
        if options and options.partialMatch == true
          return x.name.indexOf(prefix) == 0
        else
         return x.name == prefix
      )...
    return tags

  # Private: Checks whether the file is blacklisted
  #
  # Returns {Boolean} that defines whether the file is blacklisted
  FileBlacklisted: (blacklist, f, opt) ->
    for blacklistGlob in blacklist
      if minimatch(f, blacklistGlob, opt)
        return true
    return false

  listTreeSync: (rootPath) ->
    blacklist = (atom.config.get("symbols-view.fileBlacklist") or "")
      .split ","
      .map (s) -> s.trim()

    opt = {matchBase: true}
    paths = []

    onPath = (filePath) =>
      if @FileBlacklisted(blacklist, filePath, opt)
        return false
      paths.push(filePath)
      return true

    onDirectory = (dirPath) =>
      return not @FileBlacklisted(blacklist, dirPath, opt)

    fs.traverseTreeSync(rootPath, onPath, onDirectory)
    return paths

  rebuild: ->
    
    list = @listTreeSync(atom.project.getPath())
    @generateTags(f) for f in list

  getScopeName: -> atom.workspace.getActiveEditor()?.getGrammar()?.scopeName

  getTagLine: (tag) ->
    return unless tag.pattern
    file = atom.project.resolve(tag.file)
    return unless fs.isFileSync(file)
    debug = []
    for line, index in fs.readFileSync(file, 'utf8').split('\n')
      if line.indexOf(tag.pattern) == 0
        return new Point(index, 0)

  generateTags:(filePath, callback) ->
    new TagGenerator(filePath, @getScopeName()).generate().done (matches) =>
      tags = []
      for match in matches
        match.position = @getTagLine(match)
        if match.position
          tags.push(match)

      @cachedTags[filePath] = tags
      if callback
        callback(tags)

  getOrCreateTags: (filePath, callback) ->
    tags = @cachedTags[filePath]
    if tags
      if callback
        callback(tags)
      return
    generateTags(filePath, callback)
