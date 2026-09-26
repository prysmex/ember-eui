import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';
import { hash } from '@ember/helper';

import EuiI18n from '#src/components/eui-i18n.gts';

import type { TOC } from '@ember/component/template-only';

const Shout: TOC<{ Args: { token: string }; Blocks: { default: [string] } }> =
  <template>
    <strong class="shout">{{yield @token}}!</strong>
  </template>;

module('Integration | Component | eui-i18n', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders the default with interpolated values', async function (assert) {
    await render(
      <template>
        <EuiI18n
          @token="test.hello"
          @default="Hello {name}"
          @values={{hash name="World"}}
          as |Token|
        >
          <Token as |text|><span class="out">{{text}}</span></Token>
        </EuiI18n>
      </template>
    );

    assert.dom('.out').hasText('Hello World');
  });

  test('it uses i18n.mapping and a custom renderComponent', async function (assert) {
    const i18n = {
      mapping: { 'test.hello': 'Hola' },
      renderComponent: Shout
    };

    await render(
      <template>
        <EuiI18n
          @token="test.hello"
          @default="Hello"
          @i18n={{i18n}}
          as |Token|
        >
          <Token as |text|>{{text}}</Token>
        </EuiI18n>
      </template>
    );

    assert.dom('strong.shout').hasText('Hola!');
  });
});
