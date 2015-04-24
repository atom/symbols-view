{CompositeDisposable} = require 'atom'

module.exports =
  config:
    enableBuiltinProvider:
      title: 'Enable Built-In Provider'
      description: 'The package comes with a built-in Ctags symbols provider.'
      type: 'boolean'
      default: true
      order: 1
    scopeBlacklist:
      title: 'Scope Blacklist'
      description: 'Symbols will not be provided for scope selectors matching this list (use commas to separate items). See: https://atom.io/docs/latest/behind-atom-scoped-settings-scopes-and-scope-descriptors'
      type: 'array'
      default: []
      items:
        type: 'string'
      order: 2
    useEditorGrammarAsCtagsLanguage:
      title: 'Use The Editor\'s Grammar As The Ctags Language'
      description: 'If disabled, Ctags will try to determine the language itself.'
      default: true
      type: 'boolean'
      order: 3

  providerManager: null
  subscriptions: null

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

  getProviderManager: ->
    unless @providerManager?
      ProviderManager = require './provider-manager'
      @providerManager = new ProviderManager()
      @subscriptions.add(@providerManager)
    @providerManager

  # 0.1.0 API
  # providers - either a provider or a list of providers
  consumeProvider: (providers, apiVersion='0.1.0') ->
    providers = [providers] if providers? and not Array.isArray(providers)
    return unless providers?.length > 0
    registrations = new CompositeDisposable
    for provider in providers
      registrations.add @getProviderManager().registerProvider(provider, apiVersion)
    registrations
