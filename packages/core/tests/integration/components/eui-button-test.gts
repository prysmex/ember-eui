import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { on } from '@ember/modifier';
import { click, render } from '@ember/test-helpers';

import EuiButton from '#src/components/eui-button.gts';
import EuiButtonEmpty from '#src/components/eui-button-empty.gts';

module('Integration | Component | eui-button', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders a primary button', async function (assert) {
    let clicks = 0;
    const onClick = () => clicks++;

    await render(<template><EuiButton {{on "click" onClick}}>Save</EuiButton></template>);

    assert.dom('button.euiButton').hasClass('euiButton--primary').hasAttribute('type', 'button').hasText('Save');
    assert.dom('.euiButton .euiButton__content .euiButton__text').hasText('Save');
    await click('button.euiButton');
    assert.strictEqual(clicks, 1);
  });

  test('color, fill, size, full width and selected', async function (assert) {
    await render(
      <template>
        <EuiButton @color="danger" @fill={{true}} @size="s" @fullWidth={{true}} @isSelected={{true}}>Delete</EuiButton>
      </template>
    );

    assert.dom('.euiButton').hasClass('euiButton--danger').hasClass('euiButton--fill').hasClass('euiButton--small').hasClass('euiButton--fullWidth').hasAttribute('aria-pressed', 'true');
  });

  test('@href renders a link unless disabled or loading', async function (assert) {
    await render(
      <template>
        <EuiButton @href="#go" class="link">Go</EuiButton>
        <EuiButton @href="#go" @isDisabled={{true}} class="disabled">Go</EuiButton>
        <EuiButton @isLoading={{true}} class="loading">Wait</EuiButton>
      </template>
    );

    assert.dom('a.link').hasAttribute('href', '#go');
    assert.dom('button.disabled').isDisabled().hasClass('euiButton-isDisabled');
    assert.dom('button.loading').isDisabled();
    assert.dom('button.loading .euiButtonContent__spinner').exists();
  });

  test('@iconType and @iconSide', async function (assert) {
    await render(<template><EuiButton @iconType="plus" @iconSide="right">Add</EuiButton></template>);

    assert.dom('.euiButtonContent').hasClass('euiButtonContent--iconRight');
    assert.dom('.euiButtonContent svg.euiButtonContent__icon').exists();
  });

  test('EuiButtonEmpty: color, size, flush, link and disabled', async function (assert) {
    let clicks = 0;
    const onClick = () => clicks++;

    await render(
      <template>
        <EuiButtonEmpty @color="danger" @size="xs" @flush="left" class="empty" {{on "click" onClick}}>Remove</EuiButtonEmpty>
        <EuiButtonEmpty @href="#docs" class="link">Docs</EuiButtonEmpty>
        <EuiButtonEmpty @isDisabled={{true}} class="disabled">Nope</EuiButtonEmpty>
      </template>
    );

    assert.dom('button.empty').hasClass('euiButtonEmpty--danger').hasClass('euiButtonEmpty--xSmall').hasClass('euiButtonEmpty--flushLeft');
    await click('button.empty');
    assert.strictEqual(clicks, 1);
    assert.dom('a.link').hasAttribute('href', '#docs');
    assert.dom('button.disabled').isDisabled().hasClass('euiButtonEmpty-isDisabled');
  });
});
