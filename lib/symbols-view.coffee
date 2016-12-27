path = require 'path'
{Point} = require 'atom'
{$$, SelectListView} = require 'atom-space-pen-views'
fs = require 'fs-plus'
{match} = require 'fuzzaldrin'

module.exports =
class SymbolsView extends SelectListView
  @highlightMatches: (context, name, matches, offsetIndex=0) ->
    lastIndex = 0
    matchedChars = [] # Build up a set of matched chars to be more semantic

    for matchIndex in matches
      matchIndex -= offsetIndex
      continue if matchIndex < 0 # If marking up the basename, omit name matches
      unmatched = name.substring(lastIndex, matchIndex)
      if unmatched
        context.span matchedChars.join(''), class: 'character-match' if matchedChars.length
        matchedChars = []
        context.text unmatched
      matchedChars.push(name[matchIndex])
      lastIndex = matchIndex + 1

    context.span matchedChars.join(''), class: 'character-match' if matchedChars.length

    # Remaining characters are plain text
    context.text name.substring(lastIndex)

  initialize: (@stack) ->
    super
    @panel = atom.workspace.addModalPanel(item: this, visible: false)
    @addClass('symbols-view')

  destroy: ->
    @cancel()
    @panel.destroy()

  getFilterKey: -> 'name'

  viewForItem: ({position, name, file, directory}) ->
    # Style matched characters in search results
    matches = match(name, @getFilterQuery())

    if atom.project.getPaths().length > 1
      file = path.join(path.basename(directory), file)

    $$ ->
      @li class: 'two-lines', =>
        if position?
          @div "#{name}:#{position.row + 1}", class: 'primary-line'
        else
          @div class: 'primary-line', => SymbolsView.highlightMatches(this, name, matches)
        @div file, class: 'secondary-line'

  getEmptyMessage: (itemCount) ->
    if itemCount is 0
      'No symbols found'
    else
      super

  cancelled: ->
    @panel.hide()

  confirmed: (tag) ->
    if tag.file and not fs.isFileSync(path.join(tag.directory, tag.file))
      @setError('Selected file does not exist')
      setTimeout((=> @setError()), 2000)
    else
      @cancel()
      @openTag(tag)

  openTag: (tag) ->
    if editor = atom.workspace.getActiveTextEditor()
      previous =
        editorId: editor.id
        position: editor.getCursorBufferPosition()
        file: editor.getURI()

    {position} = tag
    position = @getTagLine(tag) unless position
    if tag.file
      atom.workspace.open(path.join(tag.directory, tag.file)).then =>
        @moveToPosition(position) if position
    else if position and not (previous.position.isEqual(position))
      @moveToPosition(position)

    @stack.push(previous)

  moveToPosition: (position, beginningOfLine=true) ->
    if editor = atom.workspace.getActiveTextEditor()
      editor.scrollToBufferPosition(position, center: true)
      editor.setCursorBufferPosition(position)
      editor.moveToFirstCharacterOfLine() if beginningOfLine

  attach: ->
    @storeFocusedElement()
    @panel.show()
    @focusFilterEditor()

  getTagLine: (tag) ->
    # Remove leading /^ and trailing $/
    pattern = tag.pattern?.replace(/(^^\/\^)|(\$\/$)/g, '').trim()

    # `ctags -excmd=number`, giving line numbers instead of patterns to locate
    # symbols. The line number is being interpreted as a pattern by node-ctags
    if not isNaN(pattern) and tag.lineNumber is parseInt(pattern)
      return new Point(tag.lineNumber - 1, 0)

    return unless pattern
    file = path.join(tag.directory, tag.file)
    return unless fs.isFileSync(file)
    for line, index in fs.readFileSync(file, 'utf8').split('\n')
      return new Point(index, 0) if pattern is line.trim()
