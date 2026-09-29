import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render, rerender, triggerKeyEvent, waitUntil } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import EuiColorStops from '#src/components/eui-color-stops.gts';

import type { ColorStop } from '#src/components/eui-color-stops.gts';

class State {
  @tracked colorStops: ColorStop[] = [
    { stop: 0, color: '#54B399' },
    { stop: 25, color: '#D36086' },
    { stop: 50, color: '#9170B8' },
  ];
  invalid?: boolean;

  onChange = (colorStops: ColorStop[], isInvalid: boolean) => {
    this.colorStops = colorStops;
    this.invalid = isInvalid;
  };
}

module('Integration | Component | eui-color-stops', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders a thumb per stop over a gradient', async function (assert) {
    const state = new State();

    await render(<template><EuiColorStops @label="Map colors" @colorStops={{state.colorStops}} @onChange={{state.onChange}} @min={{0}} @max={{100}} /></template>);

    assert.dom('.euiColorStops').hasAttribute('tabindex', '0');
    assert.dom('.euiColorStopThumb').exists({ count: 3 });
    assert.dom('.euiColorStops .euiScreenReaderOnly').includesText('Map colors: Color stop picker.');
    assert.ok(
      this.element.querySelector<HTMLElement>('.euiRangeHighlight__progress')!.style.background.includes('linear-gradient'),
      'the gradient'
    );
  });

  test('keyboard: arrows select stops and move them, Enter adds, Backspace removes', async function (assert) {
    const state = new State();

    await render(<template><EuiColorStops @label="Colors" @colorStops={{state.colorStops}} @onChange={{state.onChange}} @min={{0}} @max={{100}} /></template>);

    await triggerKeyEvent('.euiColorStops', 'keydown', 'ArrowDown');
    assert.dom('[data-index="euiColorStop_0"]').isFocused();
    await triggerKeyEvent('.euiColorStops', 'keydown', 'ArrowDown');
    assert.dom('[data-index="euiColorStop_1"]').isFocused();

    await triggerKeyEvent('[data-index="euiColorStop_1"]', 'keydown', 'ArrowRight');
    await rerender();
    assert.strictEqual(state.colorStops[1]!.stop, 26, 'arrow right moves the stop');

    await triggerKeyEvent('[data-index="euiColorStop_1"]', 'keydown', 'Backspace');
    await rerender();
    assert.deepEqual(state.colorStops.map((s) => s.stop), [0, 50], 'Backspace removes it');

    (this.element.querySelector('.euiColorStops') as HTMLElement).focus();
    await triggerKeyEvent('.euiColorStops', 'keydown', 'Enter');
    await rerender();
    assert.deepEqual(state.colorStops.map((s) => s.stop), [0, 50, 100], 'Enter adds a stop after the last one');
    assert.false(state.invalid);
  });

  test('a thumb opens a popover to edit its value and color', async function (assert) {
    const state = new State();

    await render(<template><EuiColorStops @label="Colors" @colorStops={{state.colorStops}} @onChange={{state.onChange}} /></template>);

    await triggerKeyEvent('[data-index="euiColorStop_2"]', 'keydown', 'Enter');
    await waitUntil(() => document.querySelector('[data-test-subj="euiColorStopPopover"]'));

    assert.dom('.euiColorStop input[type="number"]', document.body).hasValue('50');
    assert.dom('.euiColorStop .euiSaturation', document.body).exists('an inline color picker');

    await click(document.querySelector('.euiColorStop .euiButtonIcon') as Element);
    await rerender();
    assert.strictEqual(state.colorStops.length, 2, 'the trash button removes the stop');
  });

  test('read-only and disabled', async function (assert) {
    const state = new State();

    await render(
      <template>
        <EuiColorStops class="readonly" @label="A" @colorStops={{state.colorStops}} @onChange={{state.onChange}} @readOnly={{true}} />
        <EuiColorStops class="disabled" @label="B" @colorStops={{state.colorStops}} @onChange={{state.onChange}} @disabled={{true}} />
      </template>
    );

    assert.dom('.readonly').hasClass('euiColorStops-isReadOnly');
    assert.dom('.readonly .euiColorStops__addContainer').hasClass('euiColorStops__addContainer-isDisabled');
    assert.dom('.disabled').hasClass('euiColorStops-isDisabled').hasAttribute('tabindex', '-1');
  });
});
