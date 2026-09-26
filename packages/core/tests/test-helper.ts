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

class Router extends EmberRouter {
  location = 'none';
  rootURL = '/';
}

class TestApp extends EmberApp {
  modules = {
    './router': Router,
    './services/eui-config': EuiConfigService,
    './services/eui-i18n': EuiI18nService,
    './services/eui-toaster': EuiToasterService
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
