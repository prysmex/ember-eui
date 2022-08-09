import { module, test } from 'qunit';
import { setupTest } from 'ember-qunit';

module('Unit | Service | eui-i18n', function (hooks) {
  setupTest(hooks);

  // Replace this with your real tests.
  test('it exists', function (assert) {
    let service = this.owner.lookup('service:eui-i18n');
    assert.ok(service);
  });
});
