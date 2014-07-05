module.exports =
  configDefaults:
    useEditorGrammarAsCtagsLanguage: true
    autoBuildTagsWhenActive: false

  activate: ->
    @stack = []

    @ctagsCache = require "./ctags-cache"
    @ctagsCache.activate()

    @ctagsComplete = require "./ctags-complete"
    @ctagsComplete.activate(@ctagsCache)

    if atom.config.get('atom-ctags.autoBuildTagsWhenActive')
      @createFileView().rebuild()

    atom.workspaceView.command 'atom-ctags:rebuild', =>
      @createFileView().rebuild()

    atom.workspaceView.command 'atom-ctags:toggle-file-symbols', =>
      @createFileView().toggle()

    atom.workspaceView.command 'atom-ctags:go-to-declaration', =>
      @createFileView().goto()

    atom.workspaceView.command 'atom-ctags:return-from-declaration', =>
      @createGoBackView().toggle()

    if not atom.packages.isPackageDisabled("symbols-view")
      atom.packages.disablePackage("symbols-view")
      alert """Warning from atom-ctags+:
        atom-ctags is for replace and enhance symbols-view package.
        Therefore, symbols-view has been disabled.
        """

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

    @ctagsComplete.deactivate()
    @ctagsCache.deactivate()

  createFileView: ->
    unless @fileView?
      FileView  = require './file-view'
      @fileView = new FileView(@stack)
      @fileView.ctagsCache = @ctagsCache
    @fileView

  createGoBackView: ->
    unless @goBackView?
      GoBackView = require './go-back-view'
      @goBackView = new GoBackView(@stack)
    @goBackView;
