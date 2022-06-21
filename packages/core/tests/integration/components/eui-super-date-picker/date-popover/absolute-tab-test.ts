import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';
import hbs from 'htmlbars-inline-precompile';

module(
  'Integration | Component | eui-super-date-picker/date-popover/absolute-tab',
  function (hooks) {
    setupRenderingTest(hooks);

    test('it renders', async function (assert) {
      // Set any properties with this.set('myProperty', 'value');
      // Handle any actions with this.set('myAction', function(val) { ... });

      await render(hbs`{{eui-super-date-picker/date-popover/absolute-tab}}`);

      assert.equal(this.element.textContent.trim(), '');

      // Template block usage:
      await render(hbs`
      {{#eui-super-date-picker/date-popover/absolute-tab}}
        template block text
      {{/eui-super-date-picker/date-popover/absolute-tab}}
    `);

      assert.equal(this.element.textContent.trim(), 'template block text');
    });
  }
);
