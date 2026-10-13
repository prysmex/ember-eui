import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render, triggerEvent, waitUntil } from '@ember/test-helpers';

import EuiComboBox from '#src/components/eui-combo-box.gts';
import EuiToolTip from '#src/components/eui-tool-tip.gts';

const OPTIONS = [{ label: 'Apple' }, { label: 'Banana' }];
const noop = () => {};
const NONE: unknown[] = [];
const INPUT =
  'input.euiComboBox__input:not(.fake-input-for-html-form-validity)';

const zIndexOf = (element: Element | null) =>
  Number(getComputedStyle(element!).zIndex);
const list = () => document.querySelector('.ember-basic-dropdown-content');
const tooltip = () => document.querySelector('.euiToolTip');

module('Integration | stacking (combo box list, tooltips)', function (hooks) {
  setupRenderingTest(hooks);

  // The test container is itself a stacking context (z-index), which would
  // cap every layer inside it; apps have no such wrapper.
  let containerZIndex = '';
  hooks.beforeEach(function () {
    const container = document.getElementById('ember-testing-container');
    containerZIndex = container?.style.zIndex ?? '';
    container?.style.setProperty('z-index', 'auto');
  });
  hooks.afterEach(function () {
    document
      .getElementById('ember-testing-container')
      ?.style.setProperty('z-index', containerZIndex);
  });

  test('the combo box list stacks like upstream EuiInputPopover (menu level), below tooltips', async function (assert) {
    await render(
      <template>
        <EuiComboBox
          @options={{OPTIONS}}
          @selectedOptions={{NONE}}
          @onChange={{noop}}
          @searchField="label"
          as |option|
        >{{option.label}}</EuiComboBox>
      </template>
    );
    await click(INPUT);
    await waitUntil(list);

    assert.strictEqual(zIndexOf(list()), 2000, 'anchor 0 + levels.menu');
    assert.true(zIndexOf(list()) < 9000, 'below tooltips (levels.toast)');
  });

  test('inside a modal-level layer the list stacks above that layer', async function (assert) {
    await render(
      <template>
        <div style="position: relative; z-index: 8000;">
          <EuiComboBox
            @options={{OPTIONS}}
            @selectedOptions={{NONE}}
            @onChange={{noop}}
            @searchField="label"
            as |option|
          >{{option.label}}</EuiComboBox>
        </div>
      </template>
    );
    await click(INPUT);
    await waitUntil(list);

    assert.strictEqual(zIndexOf(list()), 10000);
  });

  test('a tooltip never stacks below its anchor', async function (assert) {
    await render(
      <template>
        <div style="position: relative; z-index: 10000;">
          <EuiToolTip @content="Above the layer">
            <button type="button">Anchor</button>
          </EuiToolTip>
        </div>
      </template>
    );
    await triggerEvent('.euiToolTipAnchor', 'mouseover');
    await waitUntil(tooltip);
    await waitUntil(() => zIndexOf(tooltip()) > 10000);

    assert.strictEqual(zIndexOf(tooltip()), 10001);
  });

  test('on the page a tooltip keeps upstream levels.toast', async function (assert) {
    await render(
      <template>
        <EuiToolTip @content="Plain">
          <button type="button">Anchor</button>
        </EuiToolTip>
      </template>
    );
    await triggerEvent('.euiToolTipAnchor', 'mouseover');
    await waitUntil(tooltip);

    assert.strictEqual(zIndexOf(tooltip()), 9000);
  });
});
