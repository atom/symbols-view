module.exports =
  configDefaults:
    useEditorGrammarAsCtagsLanguage: true

  activate: ->
    @stack = []

    atom.workspaceView.command 'symbols-view:toggle-file-symbols', =>
      @createFileView().toggle()

    atom.workspaceView.command 'symbols-view:toggle-project-symbols', =>
      @createProjectView().toggle()

    atom.workspaceView.command 'symbols-view:go-to-declaration', =>
      @createGoToView().toggle()

    atom.workspaceView.command 'symbols-view:return-from-declaration', =>
      @createGoBackView().toggle()

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
      @fileView = new FileView()
    @fileView

  createProjectView:  ->
    unless @projectView?
      ProjectView  = require './project-view'
      @projectView = new ProjectView()
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
    @goBackView;
