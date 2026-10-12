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
    const clear = () => {};

    await render(
      <template>
        <EuiFormControlLayout @icon="search" @isLoading={{true}} @clear={{clear}} @fullWidth={{true}} @compressed={{true}} @readOnly={{true}} @disabled={{true}}>
          <input class="field" />
        </EuiFormControlLayout>
      </template>
    );

    // Legacy `--fullWidth`/`--compressed` modifiers are gone (computed
    // styles instead); the state classes are upstream's `-readOnly`/`-isDisabled`.
    assert.dom('.euiFormControlLayout').hasClass('euiFormControlLayout-readOnly').hasClass('euiFormControlLayout-isDisabled');
    const layout = document.querySelector('.euiFormControlLayout')!;
    assert.strictEqual(getComputedStyle(layout).maxWidth, '100%', 'full width');
    assert.strictEqual(getComputedStyle(layout).height, '32px', 'compressed');
    assert.dom('.euiFormControlLayout__childrenWrapper input.field').exists();
    // One icon group per side, start side first (no `--right` modifier).
    const [left, right] = document.querySelectorAll('.euiFormControlLayoutIcons');
    assert.dom(left!.querySelector('.euiFormControlLayoutCustomIcon')).exists('left icon');
    assert.dom(right!.querySelector('.euiBorealisLoadingSpinner')).exists();

    // Upstream disables the clear button while the layout is disabled.
    assert.dom(right!.querySelector('.euiFormControlLayoutClearButton')).isDisabled();
  });

  test('the clear button calls @clear', async function (assert) {
    let cleared = 0;
    const clear = () => cleared++;

    await render(
      <template>
        <EuiFormControlLayout @clear={{clear}}><input /></EuiFormControlLayout>
      </template>
    );

    await click('.euiFormControlLayoutClearButton');
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
    // Upstream wraps each side in its own styled `__prepend` / `__append` div.
    assert.dom('.euiFormControlLayout > div.euiFormControlLayout__prepend > .pre').exists();
    assert.dom('.euiFormControlLayout > div.euiFormControlLayout__append > .post').exists();
    assert.dom('.euiFormControlLayoutIcons .euiFormControlLayoutCustomIcon').exists();
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
    // Upstream spelling (`__delimiter`); the misspelled legacy class is gone.
    assert.dom('.euiFormControlLayoutDelimited__delimiter').hasText('→');
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

    assert.dom('button.euiFormControlLayoutCustomIcon svg.euiFormControlLayoutCustomIcon__icon').exists();
    await click('button.euiFormControlLayoutCustomIcon');
    assert.strictEqual(clicks, 1);
    assert.dom('button.euiFormControlLayoutClearButton').hasAttribute('aria-label', 'Clear input');
  });
});
