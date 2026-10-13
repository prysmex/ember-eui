import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render, triggerEvent, triggerKeyEvent, waitUntil } from '@ember/test-helpers';

import EuiComboBox from '#src/components/eui-combo-box.gts';
import EuiToolTip from '#src/components/eui-tool-tip.gts';
import EuiModal from '#src/components/eui-modal.gts';
import EuiFlyout from '#src/components/eui-flyout.gts';
import EuiPopover from '#src/components/eui-popover.gts';

const OPTIONS = [{ label: 'Apple' }, { label: 'Banana' }];
const TIP_OPTIONS = [
  { label: 'Titan', toolTipContent: 'The largest moon' },
  { label: 'Pandora' }
];
const noop = () => {};
const NONE: unknown[] = [];
const INPUT =
  'input.euiComboBox__input:not(.fake-input-for-html-form-validity)';

const zIndexOf = (element: Element | null) =>
  Number(getComputedStyle(element!).zIndex);
const list = () => document.querySelector('.ember-basic-dropdown-content');
const tooltip = () => document.querySelector('.euiToolTip');


/** What the browser paints on top at the center of `element`. */
function isOnTop(element: Element | null) {
  if (!(element instanceof HTMLElement)) return false;
  // hit testing skips `pointer-events: none` (tooltips), so enable it briefly
  const pointerEvents = element.style.pointerEvents;
  element.style.pointerEvents = 'auto';
  const rect = element.getBoundingClientRect();
  const top = document.elementFromPoint(
    rect.left + rect.width / 2,
    rect.top + rect.height / 2
  );
  element.style.pointerEvents = pointerEvents;
  return Boolean(top && element.contains(top));
}

/** Opens the list, highlights the option with a tooltip, checks layering. */
async function assertListAndTooltipOnTop(assert: Assert, container: Element | null) {
  // modals, flyouts and popovers render outside the test root
  await waitUntil(() => document.querySelector(INPUT));
  const input = document.querySelector<HTMLElement>(INPUT)!;
  await click(input);
  await waitUntil(list, { timeoutMessage: 'the list opens' });
  assert.strictEqual(document.activeElement, input, 'focus stays in the combo box');
  await triggerKeyEvent(input, 'keydown', 'ArrowDown');
  await waitUntil(tooltip, { timeout: 2000, timeoutMessage: 'the option tooltip shows' });
  await waitUntil(() => isOnTop(tooltip()), { timeout: 2000 }).catch(() => {});

  const options = list()!.querySelector('.euiComboBoxOptionsList');
  assert.true(isOnTop(options), 'the list is painted above its container');
  assert.true(isOnTop(tooltip()), 'the option tooltip is painted above the list');
  assert.true(
    zIndexOf(list()) > zIndexOf(container),
    `list ${zIndexOf(list())} above container ${zIndexOf(container)}`
  );
}

module('Integration | stacking (combo box list, tooltips)', function (hooks) {
  setupRenderingTest(hooks);

  // Make the test page stack like an app: ember-basic-dropdown's portal is a
  // child of <body> (in tests it lives in the test container), and neither
  // the container (z-index) nor #ember-testing (transform) creates a layer.
  const saved = new Map<HTMLElement, string>();
  let wormholeHome: { parent: Node; next: Node | null } | undefined;
  hooks.beforeEach(function () {
    const container = document.getElementById('ember-testing-container');
    const testing = document.getElementById('ember-testing');
    for (const element of [container, testing]) {
      if (element) saved.set(element, element.getAttribute('style') ?? '');
    }
    container?.style.setProperty('z-index', 'auto');
    testing?.style.setProperty('transform', 'none');

    const wormhole = document.getElementById('ember-basic-dropdown-wormhole');
    if (wormhole?.parentNode && wormhole.parentNode !== document.body) {
      wormholeHome = { parent: wormhole.parentNode, next: wormhole.nextSibling };
      document.body.appendChild(wormhole);
    }
  });
  hooks.afterEach(function () {
    for (const [element, style] of saved) element.setAttribute('style', style);
    saved.clear();
    const wormhole = document.getElementById('ember-basic-dropdown-wormhole');
    if (wormhole && wormholeHome) {
      wormholeHome.parent.insertBefore(wormhole, wormholeHome.next);
      wormholeHome = undefined;
    }
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

  test('combo box in a modal: list above the modal, option tooltip above the list', async function (assert) {
    await render(
      <template>
        <EuiModal @onClose={{noop}}>
          <EuiComboBox @options={{TIP_OPTIONS}} @selectedOptions={{NONE}} @onChange={{noop}} @searchField="label" />
        </EuiModal>
      </template>
    );
    await assertListAndTooltipOnTop(assert, document.querySelector('.euiOverlayMask'));
  });

  test('combo box in a flyout: list above the flyout, option tooltip above the list', async function (assert) {
    await render(
      <template>
        <EuiFlyout @onClose={{noop}}>
          <EuiComboBox @options={{TIP_OPTIONS}} @selectedOptions={{NONE}} @onChange={{noop}} @searchField="label" />
        </EuiFlyout>
      </template>
    );
    await assertListAndTooltipOnTop(assert, document.querySelector('.euiFlyout'));
  });

  test('combo box in a popover: list above the popover, option tooltip above the list', async function (assert) {
    await render(
      <template>
        <EuiPopover @isOpen={{true}} @closePopover={{noop}} @ownFocus={{false}}>
          <:button><button type="button">Open</button></:button>
          <:content>
            <EuiComboBox @options={{TIP_OPTIONS}} @selectedOptions={{NONE}} @onChange={{noop}} @searchField="label" />
          </:content>
        </EuiPopover>
      </template>
    );
    await waitUntil(() => document.querySelector('.euiPopover__panel'));
    await assertListAndTooltipOnTop(assert, document.querySelector('.euiPopover__panel'));
  });

  test('combo box in a popover in a modal: everything stacks in order', async function (assert) {
    await render(
      <template>
        <EuiModal @onClose={{noop}}>
          <EuiPopover @isOpen={{true}} @closePopover={{noop}} @ownFocus={{false}}>
            <:button><button type="button">Open</button></:button>
            <:content>
              <EuiComboBox @options={{TIP_OPTIONS}} @selectedOptions={{NONE}} @onChange={{noop}} @searchField="label" />
            </:content>
          </EuiPopover>
        </EuiModal>
      </template>
    );
    await waitUntil(() => document.querySelector('.euiPopover__panel'));
    await assertListAndTooltipOnTop(assert, document.querySelector('.euiPopover__panel'));
  });

  test('a tooltip on content inside a modal stays above the modal', async function (assert) {
    await render(
      <template>
        <EuiModal @onClose={{noop}}>
          <EuiToolTip @content="Inside the modal">
            <button type="button">Anchor</button>
          </EuiToolTip>
        </EuiModal>
      </template>
    );
    await waitUntil(() => document.querySelector('.euiModal .euiToolTipAnchor'));
    await triggerEvent(document.querySelector('.euiModal .euiToolTipAnchor')!, 'mouseover');
    await waitUntil(tooltip);
    await waitUntil(() => isOnTop(tooltip()), { timeout: 2000 }).catch(() => {});

    assert.true(isOnTop(tooltip()), 'painted above the modal');
  });
});
