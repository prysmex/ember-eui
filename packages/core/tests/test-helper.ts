import EmberApp from 'ember-strict-application-resolver';
import EmberRouter from '@ember/routing/router';
import * as QUnit from 'qunit';
import { setApplication } from '@ember/test-helpers';
import { setup } from 'qunit-dom';
import { start as qunitStart, setupEmberOnerrorValidation } from 'ember-qunit';
import { setTesting } from '@embroider/macros';

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

/**
 * ember-power-select 8 uses `{{ensure-safe-component}}` from the v1 addon
 * @embroider/util. On ember-source >= 3.25 it only passes component values
 * through (string names are deprecated), which is all we need in tests.
 */
function ensureSafeComponent(value: unknown) {
  return value;
}

class TestApp extends EmberApp {
  modules = {
    './router': Router,
    './services/eui-config': EuiConfigService,
    './services/eui-i18n': EuiI18nService,
    './services/eui-toaster': EuiToasterService,
    './helpers/ensure-safe-component': { default: ensureSafeComponent },
    ...addonAppModules
  };
}

Router.map(function () {});

export function start() {
  setTesting(true);
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
