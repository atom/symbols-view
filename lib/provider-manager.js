import {CompositeDisposable, Disposable} from 'atom';

export default class ProviderManager {
  constructor() {
    this.subscriptions = new CompositeDisposable();
  }

  dispose() {
    if (!this.subscriptions) {
      return;
    }
    this.subscriptions.dispose();
    this.subscriptions = null;
  }

  registerProviders(p, apiVersion = '0.0.1') {
    if (!p) {
      return undefined;
    }

    let providers = p;

    if (!Array.isArray(providers)) {
      providers = [providers];
    }

    for (const provider of providers) {
      this.registerProvider(provider, apiVersion);
    }

    return new Disposable(() => {
      for (const provider of providers) {
        this.removeProvider(provider);
      }
    });
  }

  registerProvider(provider, apiVersion = '0.0.1') {
    return new Disposable(() => {
      this.removeProvider(provider);
    });
  }
}
