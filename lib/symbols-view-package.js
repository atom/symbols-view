import {CompositeDisposable} from 'atom';

export default class SymbolsViewPackage {
  constructor() {
    this.subscriptions = new CompositeDisposable();
    this.stack = [];
  }

  activate() {
    this.stack = [];

    this.workspaceSubscription = atom.commands.add('atom-workspace', {
      'symbols-view:toggle-project-symbols': () => {
        this.createProjectView().toggle();
      },
    });
    this.subscriptions.add(this.workspaceSubscription);

    this.editorSubscription = atom.commands.add('atom-text-editor', {
      'symbols-view:toggle-file-symbols': () => {
        this.createFileView().toggle();
      },
      'symbols-view:go-to-declaration': () => {
        this.createGoToView().toggle();
      },
      'symbols-view:return-from-declaration': () => {
        this.createGoBackView().toggle();
      },
    });
    this.subscriptions.add(this.editorSubscription);
  }

  deactivate() {
    if (this.subscriptions) {
      this.subscriptions.dispose();
    }
    this.subscriptions = new CompositeDisposable();
    this.fileView = null;
    this.projectView = null;
    this.goToView = null;
    this.goBackView = null;
    this.workspaceSubscription = null;
    this.editorSubscription = null;
    this.providerManager = null;
  }

  getProviderManager() {
    if (this.providerManager) {
      return this.providerManager;
    }

    const ProviderManager = require('./provider-manager').default;
    this.providerManager = new ProviderManager();
    this.subscriptions.add(this.providerManager);
    return this.providerManager;
  }

  createFileView() {
    if (this.fileView) {
      return this.fileView;
    }
    const FileView = require('./file-view').default;
    this.fileView = new FileView(this.stack);
    this.subscriptions.add(this.fileView);
    return this.fileView;
  }

  createProjectView() {
    if (this.projectView) {
      return this.projectView;
    }
    const ProjectView = require('./project-view').default;
    this.projectView = new ProjectView(this.stack);
    this.subscriptions.add(this.projectView);
    return this.projectView;
  }

  createGoToView() {
    if (this.goToView) {
      return this.goToView;
    }
    const GoToView = require('./go-to-view').default;
    this.goToView = new GoToView(this.stack);
    this.subscriptions.add(this.goToView);
    return this.goToView;
  }

  createGoBackView() {
    if (this.goBackView) {
      return this.goBackView;
    }
    const GoBackView = require('./go-back-view').default;
    this.goBackView = new GoBackView(this.stack);
    this.subscriptions.add(this.goBackView);
    return this.goBackView;
  }

  consumeProviders(providers) {
    // No-op
    if (!providers) {
      return undefined;
    }

    return this.getProviderManager().registerProviders(providers);
  }
}
