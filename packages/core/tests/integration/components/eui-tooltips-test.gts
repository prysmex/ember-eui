import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { array } from '@ember/helper';
import { render, triggerEvent, waitUntil } from '@ember/test-helpers';

import EuiColorPickerSwatch from '#src/components/eui-color-picker-swatch.gts';
import EuiHue from '#src/components/eui-hue.gts';
import EuiPagination from '#src/components/eui-pagination.gts';
import EuiSaturation from '#src/components/eui-saturation.gts';

const tip = () => document.querySelector('.euiToolTip') as HTMLElement | null;
const noop = () => {};

module('Integration | Component | visual tooltips (pagination, swatches, hue, saturation)', function (hooks) {
  setupRenderingTest(hooks);

  test('pagination arrows show their label in a visual tooltip (not while disabled)', async function (assert) {
    await render(<template><EuiPagination @pageCount={{5}} @activePage={{0}} @onPageClick={{noop}} /></template>);

    assert.dom('.euiToolTipAnchor [data-test-subj="pagination-button-next"]').exists();
    assert.dom('.euiToolTipAnchor [data-test-subj="pagination-button-previous"]').doesNotExist('disabled arrows have none');
    assert.dom('[data-test-subj="pagination-button-next"]').doesNotHaveAttribute('aria-describedby');

    await triggerEvent('[data-test-subj="pagination-button-next"]', 'mouseover');
    await waitUntil(tip);
    assert.dom(tip()).hasText('Next page');
  });

  test('swatches show the color in a tooltip; showToolTip and toolTipProps', async function (assert) {
    const toolTipProps = { content: 'Brand', position: 'bottom' as const };

    await render(
      <template>
        <EuiColorPickerSwatch @color="#ff0000" class="a" />
        <EuiColorPickerSwatch @color="#00ff00" @showToolTip={{false}} class="b" />
        <EuiColorPickerSwatch @color="#0000ff" @toolTipProps={{toolTipProps}} class="c" />
      </template>
    );

    assert.dom('.euiToolTipAnchor .a').exists();
    assert.dom('.euiToolTipAnchor .b').doesNotExist();
    assert.dom('.b').exists();
    assert.dom('.a').doesNotHaveAttribute('aria-describedby');
    assert.dom('.a').hasAttribute('aria-label', 'Select #ff0000 as the color');

    await triggerEvent('.a', 'mouseover');
    await waitUntil(tip);
    assert.dom(tip()).hasText('#ff0000');

    await triggerEvent('.a', 'mouseout');
    await waitUntil(() => !tip());
    await triggerEvent('.c', 'mouseover');
    await waitUntil(tip);
    assert.dom(tip()).hasText('Brand');
  });

  test('the hue slider shows the hex on the side closer to the thumb', async function (assert) {
    await render(<template><EuiHue @hue={{10}} @hex="#abcdef" @id="h" @onChange={{noop}} /></template>);

    assert.dom('.euiToolTipAnchor input.euiHue__range').exists();
    await triggerEvent('.euiHue__range', 'mouseover');
    await waitUntil(tip);
    assert.dom(tip()).hasText('#abcdef').hasClass('euiToolTip');
    assert.ok(tip()!.querySelector('.euiToolTip__arrow'));
  });

  test('the saturation indicator shows the hex and is positioned by its anchor', async function (assert) {
    await render(<template><EuiSaturation @color={{(array 100 0.5 0.5)}} @hex="#123456" @id="s" @onChange={{noop}} /></template>);

    assert.dom('.euiToolTipAnchor .euiSaturation__indicator').exists();
    assert.dom('.euiToolTipAnchor').hasStyle({ position: 'absolute' });
    await triggerEvent('.euiSaturation__indicator', 'mouseover');
    await waitUntil(tip);
    assert.dom(tip()).hasText('#123456');
  });
});
