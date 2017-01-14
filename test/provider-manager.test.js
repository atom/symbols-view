import ProviderManager from './../lib/provider-manager';
import {expect} from 'chai';

describe('Provider Manager', () => {
  let providerManager;
  beforeEach(() => {
    providerManager = new ProviderManager();
  });

  describe('registerProviders()', () => {
    let provider;

    describe('when an invalid provider is used', () => {
      beforeEach(() => {
        provider = undefined;
      });

      it('returns undefined', () => {
        const registration = providerManager.registerProviders(provider);
        expect(registration).to.be.undefined;
      });
    });

    describe('when a valid 1.0.0 provider is used', () => {
      beforeEach(() => {
        provider = {};
      });

      it('returns a disposable', () => {
        const registration = providerManager.registerProviders(provider);
        expect(registration).to.be.ok;
        expect(registration.dispose).to.be.ok;
      });
    });
  });
});
