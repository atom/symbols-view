{_, $, $$, fs, Point, SelectList} = require 'atom'
TagGenerator = require './tag-generator'
TagReader = require './tag-reader'
path = require 'path'

module.exports =
class SymbolsView extends SelectList
  @activate: ->
    new SymbolsView

  @viewClass: -> "#{super} symbols-view overlay from-top"

  filterKey: 'name'

  initialize: ->
    super

    @cachedTags = {}
    rootView.eachBuffer (buffer) =>
      @subscribe buffer, 'reloaded saved destroyed path-changed', =>
        delete @cachedTags[buffer.getPath()]
      @subscribe buffer, 'destroyed', =>
        @unsubscribe(buffer)

    rootView.command 'symbols-view:toggle-file-symbols', => @toggleFileSymbols()
    rootView.command 'symbols-view:toggle-project-symbols', => @toggleProjectSymbols()
    rootView.command 'symbols-view:go-to-declaration', => @goToDeclaration()

  itemForElement: ({position, name, file}) ->
    $$ ->
      @li class: 'two-lines', =>
        @div name, class: 'primary-line'
        if position
          text = "Line #{position.row + 1}"
        else
          text = path.basename(file)
        @div text, class: 'secondary-line'

  getEmptyMessage: (itemCount) ->
    if itemCount is 0
      'No symbols found'
    else
      super

  toggleFileSymbols: ->
    if @hasParent()
      @cancel()
    else if filePath = @getPath()
      @populateFileSymbols(filePath)
      @attach()

  getPath: -> rootView.getActiveView()?.getPath?()

  populateFileSymbols: (filePath) ->
    @list.empty()
    @setLoading("Generating symbols...")
    if tags = @cachedTags[filePath]
      @maxItem = Infinity
      @setArray(tags)
    else
      @generateTags(filePath)

  generateTags: (filePath) ->
    new TagGenerator(filePath).generate().done (tags) =>
      @cachedTags[filePath] = tags
      @maxItem = Infinity
      @setArray(tags)

  toggleProjectSymbols: ->
    if @hasParent()
      @cancel()
    else
      @populateProjectSymbols()
      @attach()

  populateProjectSymbols: ->
    @list.empty()
    @setLoading("Loading symbols...")
    TagReader.getAllTags(project).done (tags) =>
      @maxItems = 10
      @setArray(tags)

  confirmed : (tag) ->
    if tag.file and not fs.isFileSync(project.resolve(tag.file))
      @setError('Selected file does not exist')
      setTimeout((=> @setError()), 2000)
    else
      @cancel()
      @openTag(tag)

  openTag: (tag) ->
    position = tag.position
    position = @getTagLine(tag) unless position
    rootView.open(tag.file, {changeFocus: true, allowActiveEditorChange:true}) if tag.file
    @moveToPosition(position) if position

  moveToPosition: (position) ->
    editor = rootView.getActiveView()
    editor.scrollToBufferPosition(position, center: true)
    editor.setCursorBufferPosition(position)
    editor.moveCursorToFirstCharacterOfLine()

  attach: ->
    super

    rootView.append(this)
    @miniEditor.focus()

  getTagLine: (tag) ->
    pattern = $.trim(tag.pattern?.replace(/(^^\/\^)|(\$\/$)/g, '')) # Remove leading /^ and trailing $/
    return unless pattern
    file = project.resolve(tag.file)
    return unless fs.isFileSync(file)
    for line, index in fs.read(file).split('\n')
      return new Point(index, 0) if pattern is $.trim(line)

  goToDeclaration: ->
    editor = rootView.getActiveView()
    matches = TagReader.find(editor)
    return unless matches.length

    if matches.length is 1
      position = @getTagLine(matches[0])
      @openTag(file: matches[0].file, position: position) if position
    else
      tags = []
      for match in matches
        position = @getTagLine(match)
        continue unless position
        tags.push
          file: match.file
          name: path.basename(match.file)
          position: position
      @miniEditor.show()
      @setArray(tags)
      @attach()
