import EmberApp from 'ember-strict-application-resolver';
import EmberRouter from '@ember/routing/router';
import * as QUnit from 'qunit';
import { setApplication } from '@ember/test-helpers';
import { setup } from 'qunit-dom';
import { start as qunitStart, setupEmberOnerrorValidation } from 'ember-qunit';
import { setTesting } from '@embroider/macros';
import EuiConfigService from '@ember-eui/core/services/eui-config';
import EuiI18nService from '@ember-eui/core/services/eui-i18n';
import EuiToasterService from '@ember-eui/core/services/eui-toaster';
import { setConfig as setBasicDropdownConfig } from 'ember-basic-dropdown/config';
import KeyboardService from 'ember-keyboard/services/keyboard';

class Router extends EmberRouter {
  location = 'none';
  rootURL = '/';
}

// ember-basic-dropdown reads `config:environment`, which every real app has
const config = {
  modulePrefix: 'test-app',
  environment: 'test',
  rootURL: '/',
  locationType: 'none',
  APP: {}
};

/**
 * The strict resolver only knows the modules listed here. A real app gets
 * the @ember-eui/core services and ember-keyboard's service from their
 * app re-exports.
 */
class TestApp extends EmberApp {
  modules = {
    './router': Router,
    './config/environment': { default: config },
    './services/eui-config': EuiConfigService,
    './services/eui-i18n': EuiI18nService,
    './services/eui-toaster': EuiToasterService,
    './services/keyboard': KeyboardService
  };
}

Router.map(function () {});

export function start() {
  setTesting(true);
  setBasicDropdownConfig({ rootElement: '#ember-testing' });
  setApplication(
    TestApp.create({
      autoboot: false,
      rootElement: '#ember-testing'
    })
  );
  setup(QUnit.assert);
  setupEmberOnerrorValidation();
  qunitStart();
}
