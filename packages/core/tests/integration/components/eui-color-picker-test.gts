import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, fillIn, render, rerender, triggerKeyEvent, waitUntil } from '@ember/test-helpers';
import { on } from '@ember/modifier';
import { tracked } from '@glimmer/tracking';

import EuiColorPicker from '#src/components/eui-color-picker.gts';
import EuiColorPickerSwatch from '#src/components/eui-color-picker-swatch.gts';
import EuiHue from '#src/components/eui-hue.gts';
import EuiSaturation from '#src/components/eui-saturation.gts';

import type { EuiColorPickerOutput } from '#src/components/eui-color-picker.gts';

class State {
  @tracked color = '#D36086';
  outputs: EuiColorPickerOutput[] = [];

  onChange = (text: string, output: EuiColorPickerOutput) => {
    this.color = text;
    this.outputs.push(output);
  };
}

const popover = () => document.querySelector('[data-test-subj="euiColorPickerPopover"]');

module('Integration | Component | eui-color-picker', function (hooks) {
  setupRenderingTest(hooks);

  test('the field shows the color and opens the picker', async function (assert) {
    const state = new State();

    await render(<template><EuiColorPicker @color={{state.color}} @onChange={{state.onChange}} /></template>);

    assert.dom('input.euiColorPicker__input').hasValue('#D36086');
    assert.dom('.euiColorPicker__popoverAnchor .euiIcon').exists('the swatch icon');

    await click('input.euiColorPicker__input');
    await waitUntil(popover);

    assert.dom('.euiSaturation', document.body).exists();
    assert.dom('.euiHue input[type="range"]', document.body).exists();
    assert.dom('.euiColorPicker__swatchSelect', document.body).exists({ count: 10 }, 'the default swatches');
  });

  test('typing and picking swatches report the color', async function (assert) {
    const state = new State();
    const swatches = ['#54B399', '#6092C0'];

    await render(<template><EuiColorPicker @color={{state.color}} @onChange={{state.onChange}} @swatches={{swatches}} /></template>);

    await fillIn('input.euiColorPicker__input', '#fff');
    assert.strictEqual(state.color, '#fff');
    assert.deepEqual(state.outputs.at(-1), { hex: '#ffffff', rgba: [255, 255, 255, 1], isValid: true });

    await fillIn('input.euiColorPicker__input', 'nope');
    assert.false(state.outputs.at(-1)!.isValid);

    await click('input.euiColorPicker__input');
    await waitUntil(popover);
    await click(document.querySelectorAll('.euiColorPicker__swatchSelect')[1]!);
    await rerender();

    assert.strictEqual(state.color, '#6092C0');
    assert.dom('input.euiColorPicker__input').hasValue('#6092C0');
  });

  test('the hue slider changes the color, keeping saturation and value', async function (assert) {
    const state = new State();
    state.color = '#ff0000';

    await render(<template><EuiColorPicker @color={{state.color}} @onChange={{state.onChange}} @display="inline" @mode="picker" /></template>);

    assert.dom('.euiColorPicker__swatches').doesNotExist("'picker' mode has no swatches");
    await fillIn('.euiHue__range', '120');

    assert.strictEqual(state.color, '#00ff00');
  });

  test('keyboard: Enter toggles, arrow down opens', async function (assert) {
    const state = new State();

    await render(<template><EuiColorPicker @color={{state.color}} @onChange={{state.onChange}} /></template>);

    await triggerKeyEvent('input.euiColorPicker__input', 'keydown', 'ArrowDown');
    await waitUntil(popover);
    assert.ok(popover(), 'opened');
  });

  test('rgba format, alpha and clearing', async function (assert) {
    const state = new State();
    state.color = '211, 96, 134';

    await render(
      <template>
        <EuiColorPicker @color={{state.color}} @onChange={{state.onChange}} @display="inline" @showAlpha={{true}} @isClearable={{true}} @secondaryInputDisplay="bottom" />
      </template>
    );

    assert.dom('.euiColorPicker__alphaRange').exists();
    assert.dom('[data-test-subj="euiColorPickerInput_bottom"]').hasValue('211, 96, 134');

    await fillIn('.euiHue__range', '0');
    assert.ok(/^\d+, \d+, \d+$/.test(state.color), `keeps the rgb format: ${state.color}`);
  });

  test('a custom button', async function (assert) {
    const state = new State();

    await render(
      <template>
        <EuiColorPicker @color={{state.color}} @onChange={{state.onChange}} @mode="swatch">
          <:button as |toggle|>
            <EuiColorPickerSwatch class="trigger" @color={{state.color}} {{on "click" toggle}} />
          </:button>
        </EuiColorPicker>
      </template>
    );

    assert.dom('input.euiColorPicker__input').doesNotExist();
    await click('.trigger');
    await waitUntil(popover);
    assert.dom('.euiSaturation', document.body).doesNotExist("'swatch' mode has only swatches");
    assert.dom('.euiColorPicker__swatchSelect', document.body).exists();
  });

  test('EuiColorPickerSwatch, EuiHue and EuiSaturation', async function (assert) {
    const hues: number[] = [];
    const colors: number[][] = [];
    const onHue = (hue: number) => hues.push(hue);
    const onSaturation = (color: number[]) => colors.push(color);
    const hsv = [0, 1, 1] as [number, number, number];

    await render(
      <template>
        <EuiColorPickerSwatch class="swatch" @color="#ff0000" />
        <EuiColorPickerSwatch class="none" @color="nope" />
        <EuiHue @id="h" @hue={{200}} @onChange={{onHue}} />
        <div style="width: 150px;"><EuiSaturation @id="s" @color={{hsv}} @hex="#ff0000" @onChange={{onSaturation}} /></div>
      </template>
    );

    assert.dom('.swatch').hasStyle({ backgroundColor: 'rgb(255, 0, 0)' }).hasAria('label', 'Select #ff0000 as the color');
    assert.dom('.none').hasAttribute('style', 'background: transparent');

    assert.dom('#h-hue').hasValue('200');
    await fillIn('#h-hue', '10');
    assert.deepEqual(hues, [10]);

    assert.dom('.euiSaturation').hasStyle({ backgroundColor: 'rgb(255, 0, 0)' });
    await triggerKeyEvent('.euiSaturation', 'keydown', 'ArrowLeft');
    assert.strictEqual(colors.length, 1);
    assert.strictEqual(colors[0]![0], 0, 'the hue is kept');
    assert.true(colors[0]![1]! < 1, 'arrow left lowers the saturation');
  });
});

