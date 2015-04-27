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

  subscriptions: null
  symbolsManager: null

  activate: ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace',
      'symbols-view:toggle-project-symbols': => @getSymbolsManager().getProjectView().toggle()

    @subscriptions.add atom.commands.add 'atom-text-editor',
      'symbols-view:toggle-file-symbols': => @getSymbolsManager().getFileView().toggle()
      'symbols-view:go-to-declaration': => @getSymbolsManager().getGoToView().toggle()
      'symbols-view:return-from-declaration': => @getSymbolsManager().getGoBackView().toggle()

  deactivate: ->
    @subscriptions.dispose()
    @subscriptions = null
    @symbolsManager = null

  getSymbolsManager: ->
    unless @symbolsManager?
      SymbolsManager = require './symbols-manager'
      @symbolsManager = new SymbolsManager()
      @subscriptions.add(@symbolsManager)
    @symbolsManager

  # 0.1.0 API
  # providers - either a provider or a list of providers
  consumeProvider: (providers, apiVersion='0.1.0') ->
    providers = [providers] if providers? and not Array.isArray(providers)
    return unless providers?.length > 0
    registrations = new CompositeDisposable
    for provider in providers
      registrations.add(@getSymbolsManager().providerManager.registerProvider(provider, apiVersion))
    registrations
