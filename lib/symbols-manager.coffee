{CompositeDisposable}  = require 'atom'

ProviderManager = require './provider-manager'

module.exports =
class SymbolsManager
  fileView: null
  goBackView: null
  goToView: null
  projectView: null
  providerManager: null
  stack: null
  subscriptions: null

  constructor: ->
    @stack = []
    @subscriptions = new CompositeDisposable
    @providerManager = new ProviderManager
    @subscriptions.add(@providerManager)

  dispose: ->
    @subscriptions?.dispose()
    @subscriptions = null
    @providerManager = null
    @fileView = null
    @projectView = null
    @goToView = null
    @goBackView = null
    @stack = null

  getFileView: =>
    unless @fileView?
      FileView  = require './file-view'
      @fileView = new FileView(@stack)
      @subscriptions.add(@fileView)
    @fileView

  getProjectView: =>
    unless @projectView?
      ProjectView  = require './project-view'
      @projectView = new ProjectView(@stack)
      @subscriptions.add(@projectView)
    @projectView

  getGoToView: =>
    unless @goToView?
      GoToView = require './go-to-view'
      @goToView = new GoToView(@stack)
      @subscriptions.add(@goToView)
    @goToView

  getGoBackView: =>
    unless @goBackView?
      GoBackView = require './go-back-view'
      @goBackView = new GoBackView(@stack)
      @subscriptions.add(@goBackView)
    @goBackView
