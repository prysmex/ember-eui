import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';

import EuiI18nNumber from '#src/components/eui-i18n-number.gts';

import type EuiI18n from '#src/services/eui-i18n.ts';

module('Integration | Component | eui-i18n-number', function (hooks) {
  setupRenderingTest(hooks);

  test('it formats numbers in English by default', async function (assert) {
    await render(<template><span class="one"><EuiI18nNumber @value={{1234567.5}} /></span></template>);

    assert.dom('.one').hasText('1,234,567.5');
  });

  test('several values are yielded as an array', async function (assert) {
    const values = [1000, 2000];

    await render(
      <template>
        <EuiI18nNumber @values={{values}} as |formatted|>
          {{#each formatted as |text|}}<i>{{text}}</i>{{/each}}
        </EuiI18nNumber>
      </template>
    );

    assert.deepEqual([...this.element.querySelectorAll('i')].map((el) => el.textContent), ['1,000', '2,000']);
  });

  test('the service formatter can be replaced', async function (assert) {
    const i18n = this.owner.lookup('service:eui-i18n') as EuiI18n;

    i18n.formatNumber = (value) => new Intl.NumberFormat('de').format(value);

    await render(<template><span class="de"><EuiI18nNumber @value={{1234.5}} /></span></template>);

    assert.dom('.de').hasText('1.234,5');
  });
});
