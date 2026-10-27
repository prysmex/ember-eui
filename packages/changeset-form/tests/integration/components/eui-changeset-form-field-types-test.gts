import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';

import { Changeset } from 'ember-changeset';

import EuiChangesetForm from '#src/components/eui-changeset-form.gts';

module(
  'Integration | Component | eui-changeset-form | yielded field types',
  function (hooks) {
    setupRenderingTest(hooks);

    test('a yielded field takes its element attributes', async function (assert) {
      const changeset = Changeset({ color: '#ff0000', subdomain: 'acme' });

      await render(
        <template>
          <EuiChangesetForm @changeset={{changeset}} as |form|>
            <form.FieldText @fieldName="color" type="color" class="pl-24" />
            <form.FieldText
              @fieldName="subdomain"
              id="subdomain"
              name="subdomain"
              autocomplete="subdomain"
            />
          </EuiChangesetForm>
        </template>
      );

      assert.dom('input[type="color"]').hasClass('pl-24');
      assert
        .dom('input#subdomain')
        .hasAttribute('name', 'subdomain')
        .hasAttribute('autocomplete', 'subdomain');
    });

    test('a yielded field takes its named blocks', async function (assert) {
      const changeset = Changeset({ url: 'acme', accepted: true });

      await render(
        <template>
          <EuiChangesetForm @changeset={{changeset}} as |form|>
            <form.FieldText @fieldName="url">
              <:prepend as |classes|>
                <span class="prefix {{classes}}">https://</span>
              </:prepend>
            </form.FieldText>
            <form.FieldCheckbox @fieldName="accepted" @label="Accept" />
          </EuiChangesetForm>
        </template>
      );

      assert.dom('.prefix.euiFormControlLayout__prepend').hasText('https://');
      assert.dom('input[type="checkbox"]').isChecked();
    });
  }
);
