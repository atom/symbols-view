module.exports =
  config:
    useEditorGrammarAsCtagsLanguage:
      default: true
      type: 'boolean'

  activate: ->
    @stack = []

    atom.commands.add 'atom-workspace',
      'symbols-view:toggle-project-symbols': => @createProjectView().toggle()

    atom.commands.add 'atom-text-editor',
      'symbols-view:toggle-file-symbols': => @createFileView().toggle()
      'symbols-view:go-to-declaration': => @createGoToView().toggle()
      'symbols-view:return-from-declaration': => @createGoBackView().toggle()

  deactivate: ->
    if @fileView?
      @fileView.destroy()
      @fileView = null

    if @projectView?
      @projectView.destroy()
      @projectView = null

    if @goToView?
      @goToView.destroy()
      @goToView = null

    if @goBackView?
      @goBackView.destroy()
      @goBackView = null

  createFileView: ->
    unless @fileView?
      FileView  = require './file-view'
      @fileView = new FileView(@stack)
    @fileView

  createProjectView:  ->
    unless @projectView?
      ProjectView  = require './project-view'
      @projectView = new ProjectView(@stack)
    @projectView

  createGoToView: ->
    unless @goToView?
      GoToView = require './go-to-view'
      @goToView = new GoToView(@stack)
    @goToView

  createGoBackView: ->
    unless @goBackView?
      GoBackView = require './go-back-view'
      @goBackView = new GoBackView(@stack)
    @goBackView
