{Selector} = require 'selector-kit'
{selectorForScopeChain, selectorsMatchScopeChain} = require './scope-helpers'

module.exports =
class ProviderMetadata
  constructor: (@provider, @apiVersion) ->
    @selectors = Selector.create(@provider.selector)
    @disableForSelectors = Selector.create(@provider.disableForSelector) if @provider.disableForSelector?

  matchesScopeChain: (scopeChain) ->
    if @disableForSelectors?
      return false if selectorsMatchScopeChain(@disableForSelectors, scopeChain)

    if selectorsMatchScopeChain(@selectors, scopeChain)
      true
    else
      false

  getSpecificity: (scopeChain) ->
    if selector = selectorForScopeChain(@selectors, scopeChain)
      selector.getSpecificity()
    else
      0
