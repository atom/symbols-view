module.exports =
  configDefaults:
    useEditorGrammarAsCtagsLanguage: true
    autoBuildTagsWhenActive: false
    buildTimeout: 5000
    cmdArgs: ""
    extraTagFiles: ""

  activate: ->
    @stack = []

    @ctagsCache = require "./ctags-cache"

    @ctagsCache.activate()

    @ctagsComplete = require "./ctags-complete"
    setTimeout((=> @ctagsComplete.activate(@ctagsCache)), 2000)

    if atom.config.get('atom-ctags.autoBuildTagsWhenActive')
      t = setTimeout((=>
        @createFileView().rebuild()
        t = null
      ), 2000)

    atom.workspaceView.command 'atom-ctags:rebuild', (e, cmdArgs)=>
      @ctagsCache.cmdArgs = cmdArgs if Array.isArray(cmdArgs)
      @createFileView().rebuild()
      if t
        clearTimeout(t)
        t = null

    atom.workspaceView.command 'atom-ctags:toggle-file-symbols', =>
      @createFileView().toggle()

    atom.workspaceView.command 'atom-ctags:toggle-project-symbols', =>
      @createFileView().toggleAll()

    atom.workspaceView.command 'atom-ctags:go-to-declaration', =>
      @createFileView().goto()

    atom.workspaceView.command 'atom-ctags:return-from-declaration', =>
      @createGoBackView().toggle()

    if not atom.packages.isPackageDisabled("symbols-view")
      atom.packages.disablePackage("symbols-view")
      alert "Warning from atom-ctags:
              atom-ctags is for replace and enhance symbols-view package.
              Therefore, symbols-view has been disabled."

    initExtraTagsTime = null
    atom.config.observe 'atom-ctags.extraTagFiles', =>
      clearTimeout initExtraTagsTime if initExtraTagsTime
      initExtraTagsTime = setTimeout((=>
        @ctagsCache.initExtraTags(atom.config.get('atom-ctags.extraTagFiles').split(" "))
        initExtraTagsTime = null
      ), 1000)



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
    @goBackView
