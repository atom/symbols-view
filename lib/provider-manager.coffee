{CompositeDisposable, Disposable} = require 'atom'
_ = require 'underscore-plus'
semver = require 'semver'
{Selector} = require 'selector-kit'
stableSort = require 'stable'

{selectorsMatchScopeChain} = require('./scope-helpers')

# Deferred requires
SymbolProvider = null
CtagsProvider =  null
ProviderMetadata = null

module.exports =
class ProviderManager
  defaultProvider: null
  defaultProviderRegistration: null
  store: null
  subscriptions: null
  globalBlacklist: null

  constructor: ->
    @subscriptions = new CompositeDisposable
    @globalBlacklist = new CompositeDisposable
    @subscriptions.add(@globalBlacklist)
    @providers = []
    @subscriptions.add(atom.config.observe('symbols-view.enableBuiltinProvider', (value) => @toggleDefaultProvider(value)))
    @subscriptions.add(atom.config.observe('symbols-view.scopeBlacklist', (value) => @setGlobalBlacklist(value)))

  dispose: ->
    @toggleDefaultProvider(false)
    @subscriptions?.dispose()
    @subscriptions = null
    @globalBlacklist = null
    @providers = null

  toggleDefaultProvider: (enabled) =>
    return unless enabled?

    if enabled
      return if @defaultProvider? or @defaultRegistration?
      CtagsProvider ?= require('./ctags-provider')
      @defaultProvider = new CtagsProvider()
      @defaultRegistration = @registerProvider(@defaultProvider)
    else
      @defaultRegistration.dispose() if @defaultRegistration?
      @defaultProvider.dispose() if @defaultProvider?
      @defaultRegistration = null
      @defaultProvider = null

  setGlobalBlacklist: (globalBlacklist) =>
    @globalBlacklistSelectors = null
    if globalBlacklist?.length
      @globalBlacklistSelectors = Selector.create(globalBlacklist)
