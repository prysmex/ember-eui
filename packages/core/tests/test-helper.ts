import EmberApp from 'ember-strict-application-resolver';
import EmberRouter from '@ember/routing/router';
import * as QUnit from 'qunit';
import { setApplication } from '@ember/test-helpers';
import { setup } from 'qunit-dom';
import { start as qunitStart, setupEmberOnerrorValidation } from 'ember-qunit';
import { setTesting } from '@embroider/macros';
import { setConfig as setBasicDropdownConfig } from 'ember-basic-dropdown/config';

import EuiConfigService from '#src/services/eui-config.ts';
import EuiI18nService from '#src/services/eui-i18n.ts';
import EuiToasterService from '#src/services/eui-toaster.ts';

// app-js re-exports of dependencies that are still resolved by name,
// see tests/generate-addon-app-modules.mjs
import addonAppModules from './addon-app-modules.ts';

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

class TestApp extends EmberApp {
  modules = {
    './router': Router,
    './config/environment': { default: config },
    './services/eui-config': EuiConfigService,
    './services/eui-i18n': EuiI18nService,
    './services/eui-toaster': EuiToasterService,
    ...addonAppModules
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
