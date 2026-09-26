import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render } from '@ember/test-helpers';

import EuiFormControlLayout from '#src/components/eui-form-control-layout.gts';
import EuiFormControlLayoutClearButton from '#src/components/eui-form-control-layout-clear-button.gts';
import EuiFormControlLayoutCustomIcon from '#src/components/eui-form-control-layout-custom-icon.gts';
import EuiFormControlLayoutDelimited from '#src/components/eui-form-control-layout-delimited.gts';

module('Integration | Component | eui-form-control-layout', function (hooks) {
  setupRenderingTest(hooks);

  test('it wraps the field with icons, loading and clear', async function (assert) {
    let cleared = 0;
    const clear = () => cleared++;

    await render(
      <template>
        <EuiFormControlLayout @icon="search" @isLoading={{true}} @clear={{clear}} @fullWidth={{true}} @compressed={{true}} @readOnly={{true}} @disabled={{true}}>
          <input class="field" />
        </EuiFormControlLayout>
      </template>
    );

    assert.dom('.euiFormControlLayout').hasClass('euiFormControlLayout--fullWidth').hasClass('euiFormControlLayout--compressed').hasClass('euiFormControlLayout--readOnly').hasClass('euiFormControlLayout--isDisabled');
    assert.dom('.euiFormControlLayout__childrenWrapper input.field').exists();
    assert.dom('.euiFormControlLayoutIcons:not(.euiFormControlLayoutIcons--right) .euiFormControlLayoutCustomIcon').exists('left icon');
    assert.dom('.euiFormControlLayoutIcons--right .euiLoadingSpinner').exists();

    await click('.euiFormControlLayoutIcons--right .euiFormControlLayoutClearButton');
    assert.strictEqual(cleared, 1);
  });

  test('right icon, and prepend/append make a group', async function (assert) {
    await render(
      <template>
        <EuiFormControlLayout @icon="arrowDown" @iconSide="right">
          <:prepend as |classes|><span class="pre {{classes}}">$</span></:prepend>
          <:field><input /></:field>
          <:append as |classes|><span class="post {{classes}}">USD</span></:append>
        </EuiFormControlLayout>
      </template>
    );

    assert.dom('.euiFormControlLayout').hasClass('euiFormControlLayout--group');
    assert.dom('.pre').hasClass('euiFormControlLayout__prepend');
    assert.dom('.post').hasClass('euiFormControlLayout__append');
    assert.dom('.euiFormControlLayoutIcons--right .euiFormControlLayoutCustomIcon').exists();
  });

  test('EuiFormControlLayoutDelimited renders start, delimiter and end controls', async function (assert) {
    await render(
      <template>
        <EuiFormControlLayoutDelimited>
          <:startControl as |classes|><input class="start {{classes}}" /></:startControl>
          <:endControl as |classes|><input class="end {{classes}}" /></:endControl>
        </EuiFormControlLayoutDelimited>
      </template>
    );

    assert.dom('.euiFormControlLayoutDelimited input.start').hasClass('euiFormControlLayoutDelimited__input');
    assert.dom('.euiFormControlLayoutDelimited__delimeter').hasText('→');
    assert.dom('input.end').hasClass('euiFormControlLayoutDelimited__input');
  });

  test('custom icon button and clear button', async function (assert) {
    let clicks = 0;
    const onClick = () => clicks++;

    await render(
      <template>
        <EuiFormControlLayoutCustomIcon @type="calendar" @onClick={{onClick}} />
        <EuiFormControlLayoutClearButton @size="s" @label="Clear input" />
      </template>
    );

    assert.dom('button.euiFormControlLayoutCustomIcon--clickable svg.euiFormControlLayoutCustomIcon__icon').exists();
    await click('button.euiFormControlLayoutCustomIcon');
    assert.strictEqual(clicks, 1);
    assert.dom('button.euiFormControlLayoutClearButton').hasAttribute('aria-label', 'Clear input');
  });
});
