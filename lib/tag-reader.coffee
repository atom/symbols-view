path = require 'path'
{Task} = require 'atom'
ctags = require 'ctags'
async = require 'async'
getTagsFile = require "./get-tags-file"

handlerPath = require.resolve './load-tags-handler'

module.exports =
  find: (editor, callback) ->
    if editor.getLastCursor().getScopeDescriptor().getScopesArray().indexOf('source.ruby') isnt -1
      # Include ! and ? in word regular expression for ruby files
      range = editor.getLastCursor().getCurrentWordBufferRange(wordRegex: /[\w!?]*/g)
    else
      range = editor.getLastCursor().getCurrentWordBufferRange()

    symbol = editor.getTextInRange(range)

    unless symbol?.length > 0
      return process.nextTick -> callback(null, [])

    allTags = []

    async.each(
      @getTagsPaths(atom.config.get('symbols-view.tagsDirectory'))
      ({tagsPath, projectPath}, done) ->
        tagsFile = getTagsFile(tagsPath)
        return done() unless tagsFile?
        ctags.findTags tagsFile, symbol, (err, tags=[]) ->
          for tag in tags
            tag.projectPath = projectPath
            tag.directory = tagsPath
          allTags = allTags.concat(tags)
          done(err)
      (err) -> callback(err, allTags)
    )

  getAllTags: (callback) ->
    projectTags = []
    relativeTagsDirectory = atom.config.get('symbols-view.tagsDirectory')
    task = Task.once handlerPath, @getTagsPaths(relativeTagsDirectory), -> callback(projectTags)
    task.on 'tags', (tags) -> projectTags.push(tags...)
    task

  getTagsPaths: (relativeTagsDirectory) ->
    paths = []
    for projectPath in atom.project.getPaths()
      paths.push(
        projectPath: projectPath
        tagsPath: path.join(projectPath, relativeTagsDirectory)
      )
    paths
