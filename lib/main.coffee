module.exports =
  config:
    useEditorGrammarAsCtagsLanguage:
      default: true
      type: 'boolean'
      description: 'Force ctags to use the name of the current file\'s language in Atom when generating tags. By default, ctags automatically selects the language of a source file, ignoring those files whose language cannot be determined. This option forces the specified language to be used instead of automatically selecting the language based upon its extension.'

  activate: ->
    @stack = []

    @workspaceSubscription = atom.commands.add 'atom-workspace',
      'symbols-view:toggle-project-symbols': => @createProjectView().toggle()

    @editorSubscription = atom.commands.add 'atom-text-editor',
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

    if @workspaceSubscription?
      @workspaceSubscription.dispose()
      @workspaceSubscription = null

    if @editorSubscription?
      @editorSubscription.dispose()
      @editorSubscription = null

  createFileView: ->
    unless @fileView?
      FileView  = require './file-view'
      @fileView = new FileView(@stack)
    @fileView

  createProjectView: ->
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
