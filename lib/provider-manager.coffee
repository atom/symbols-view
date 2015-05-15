{CompositeDisposable, Disposable} = require 'atom'
_ = require 'underscore-plus'
{Selector} = require 'selector-kit'

{selectorsMatchScopeChain} = require('./scope-helpers')

# Deferred requires
SymbolProvider = null
CtagsProvider =  null
ProviderMetadata = null

module.exports =
class ProviderManager
  defaultProvider: null
  defaultProviderRegistration: null
  providers: null
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

  isValidProvider: (provider, apiVersion) ->
    provider? and _.isString(provider.selector) and !!provider.selector.length

  metadataForProvider: (provider) =>
    for providerMetadata in @providers
      return providerMetadata if providerMetadata.provider is provider
    null
    
  apiVersionForProvider: (provider) =>
    @metadataForProvider(provider)?.apiVersion

  isProviderRegistered: (provider) =>
    @metadataForProvider(provider)?

  addProvider: (provider, apiVersion='0.1.0') =>
    return if @isProviderRegistered(provider)
    ProviderMetadata ?= require './provider-metadata'
    @providers.push new ProviderMetadata(provider, apiVersion)
    @subscriptions.add(provider) if provider.dispose?

  removeProvider: (provider) =>
    return unless @providers
    for providerMetadata, i in @providers
      if providerMetadata.provider is provider
        @providers.splice(i, 1)
        break
    @subscriptions?.remove(provider) if provider.dispose?

  registerProvider: (provider, apiVersion='0.1.0') =>
    return unless provider?

    unless @isValidProvider(provider, apiVersion)
      console.warn "Provider #{provider.constructor.name} is not valid", provider
      return

    return if @isProviderRegistered(provider)

    @addProvider(provider, apiVersion)
    disposable = new Disposable =>
      @removeProvider(provider)

    # When the provider is disposed, remove its registration
    if originalDispose = provider.dispose
      provider.dispose = ->
        originalDispose.call(provider)
        disposable.dispose()

    disposable
