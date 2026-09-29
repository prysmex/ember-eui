import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render, rerender, waitUntil } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import EuiColorPaletteDisplay from '#src/components/eui-color-palette-display.gts';
import EuiColorPalettePicker from '#src/components/eui-color-palette-picker.gts';

import type { EuiColorPalettePickerPalette } from '#src/components/eui-color-palette-picker.gts';

module('Integration | Component | eui-color-palette-display and picker', function (hooks) {
  setupRenderingTest(hooks);

  test('fixed and gradient displays', async function (assert) {
    const colors = ['#ff0000', '#00ff00', '#0000ff'];
    const stops = [
      { stop: 0, color: '#ff0000' },
      { stop: 50, color: '#00ff00' },
    ];

    await render(
      <template>
        <EuiColorPaletteDisplay class="fixed" @palette={{colors}} @title="Primary" />
        <EuiColorPaletteDisplay class="gradient" @palette={{stops}} @type="gradient" @size="m" />
      </template>
    );

    assert.dom('.fixed').hasClass('euiColorPaletteDisplay').hasClass('euiColorPaletteDisplay--sizeSmall');
    assert.dom('.fixed .euiColorPaletteDisplayFixed__bleedArea span').exists({ count: 3 });
    assert.dom('.fixed .euiScreenReaderOnly').hasText('Primary');
    assert.dom('.gradient').hasClass('euiColorPaletteDisplay--sizeMedium').hasAttribute('aria-hidden', 'true');
    assert.ok(this.element.querySelector<HTMLElement>('.gradient')!.style.background.includes('linear-gradient'));
  });

  test('the picker lists palettes and picks one', async function (assert) {
    class State {
      @tracked value = 'cool';
    }
    const state = new State();
    const onChange = (value: string) => (state.value = value);
    const palettes: EuiColorPalettePickerPalette[] = [
      { value: 'cool', title: 'Cool', type: 'fixed', palette: ['#6092C0', '#54B399'] },
      { value: 'warm', title: 'Warm', type: 'gradient', palette: ['#D36086', '#E7664C'] },
      { value: 'custom', title: 'Custom', type: 'text' },
    ];

    await render(<template><EuiColorPalettePicker @palettes={{palettes}} @valueOfSelected={{state.value}} @onChange={{onChange}} /></template>);

    assert.dom('.euiSuperSelectControl .euiColorPaletteDisplay').exists('the selected palette is shown');

    await click('button.euiSuperSelectControl');
    await waitUntil(() => document.querySelector('.euiColorPalettePicker__item'));
    assert.dom('.euiColorPalettePicker__item', document.body).exists({ count: 3 });
    assert.dom('.euiColorPalettePicker__itemTitle', document.body).exists({ count: 2 }, 'text options have no palette title');

    await click(document.querySelectorAll('.euiSuperSelect__item')[2]!);
    await rerender();
    assert.strictEqual(state.value, 'custom');
    assert.dom('.euiSuperSelectControl').hasText('Custom');
  });
});
