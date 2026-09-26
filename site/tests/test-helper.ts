import { setApplication } from '@ember/test-helpers';
import * as QUnit from 'qunit';
import { setup } from 'qunit-dom';
import { setupEmberOnerrorValidation, start as qunitStart } from 'ember-qunit';

import Application from 'site/app';
import config from 'site/config/environment';

export function start() {
  setApplication(Application.create(config.APP));

  setup(QUnit.assert);
  setupEmberOnerrorValidation();

  qunitStart();
}
