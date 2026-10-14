/**
 * Growth measurements for the heaviest components (leak mode only).
 *
 * Each test mounts/unmounts (or opens/closes) a component 100 times after a
 * warm-up, forcing gc() between samples, and records heap and live counters
 * (listeners, observers, timers, portals, CSS rules) after the warm-up, after
 * 50 and after 100 cycles. Results land in the leak report (`growth`).
 * Defined only with `?leaks` (tests/leak-detector.ts), so normal runs skip it.
 */
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render, settled, triggerEvent, triggerKeyEvent, waitUntil } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import EuiButton from '#src/components/eui-button.gts';
import EuiCodeBlock from '#src/components/eui-code-block.gts';
import EuiCollapsibleNav from '#src/components/eui-collapsible-nav.gts';
import EuiComboBox from '#src/components/eui-combo-box.gts';
import EuiDataGrid from '#src/components/eui-data-grid.gts';
import EuiBasicTable from '#src/components/eui-basic-table.gts';
import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import EuiFlyout from '#src/components/eui-flyout.gts';
import EuiFlyoutBody from '#src/components/eui-flyout-body.gts';
import EuiInMemoryTable from '#src/components/eui-in-memory-table.gts';
import EuiMarkdownEditor from '#src/components/eui-markdown-editor.gts';
import EuiModal from '#src/components/eui-modal.gts';
import EuiPopover from '#src/components/eui-popover.gts';
import EuiSelectable from '#src/components/eui-selectable.gts';
import EuiSuperDatePicker from '#src/components/eui-super-date-picker.gts';
import EuiToolTip from '#src/components/eui-tool-tip.gts';
import EuiTourStep from '#src/components/eui-tour-step.gts';
import { LEAKS_ENABLED, forceGc, leakState, liveCounts, usedHeap } from '../../leak-detector.ts';

type Cycle = (i: number) => Promise<void>;

class Toggle {
  @tracked show = false;
  @tracked open = false;
  close = () => (this.open = false);
}

const COLUMNS = [
  { id: 'name', displayAsText: 'Name' },
  { id: 'email', displayAsText: 'Email' },
  { id: 'age', displayAsText: 'Age' }
];
const ITEMS = Array.from({ length: 30 }, (_, i) => ({
  id: i,
  name: `Person ${i}`,
  email: `p${i}@example.com`,
  age: 20 + i
}));
const TABLE_COLUMNS = [
  { field: 'name', name: 'Name', sortable: true },
  { field: 'email', name: 'Email' },
  { field: 'age', name: 'Age', dataType: 'number', sortable: true }
];
const PAGINATION = { initialPageSize: 10, pageSizeOptions: [10, 20] };
const SEARCH = { box: { incremental: true } };
const OPTIONS = Array.from({ length: 40 }, (_, i) => `Option ${i}`);
const SELECTABLE_OPTIONS = Array.from({ length: 40 }, (_, i) => ({ label: `Option ${i}` }));
const noop = () => {};
const NONE: string[] = [];

async function sample(n: number) {
  await settled();
  await forceGc(8);
  return { cycles: n, heap: usedHeap() ?? 0, counts: liveCounts() };
}

const params = new URLSearchParams(location.search);
// `?leaks&growthCycles=400&filter=Leak | growth EuiMarkdownEditor` for a longer run
const CYCLES = Number(params.get('growthCycles')) || 100;

async function measure(assert: Assert, name: string, cycle: Cycle, n = CYCLES) {
  for (let i = 0; i < 5; i++) await cycle(i);
  const samples = [await sample(0)];
  for (let i = 1; i <= n; i++) {
    await cycle(i);
    if (i === Math.floor(n / 2) || i === n) samples.push(await sample(i));
  }
  const [s0, s1, s2] = samples as [any, any, any];
  const delta: Record<string, number> = {};
  for (const k of Object.keys(s0.counts)) delta[k] = s2.counts[k] - s0.counts[k];
  const result = {
    name,
    cycles: n,
    heapStart: s0.heap,
    heapMid: s1.heap,
    heapEnd: s2.heap,
    bytesPerCycle: Math.round((s2.heap - s0.heap) / n),
    bytesPerCycleSecondHalf: Math.round((s2.heap - s1.heap) / (n - Math.floor(n / 2))),
    countsStart: s0.counts,
    countsEnd: s2.counts,
    countDelta: delta
  };
  leakState.growth.push(result);
  assert.ok(true, `${name}: ${result.bytesPerCycle} B/cycle, ${JSON.stringify(delta)}`);
}

if (LEAKS_ENABLED) {
  module('Leak | growth', function (hooks) {
    setupRenderingTest(hooks);

    const mountUnmount = (s: Toggle, after?: () => Promise<void>): Cycle => async () => {
      s.show = true;
      await settled();
      if (after) await after();
      s.show = false;
      await settled();
    };

    test('control: plain element', async function (assert) {
      const s = new Toggle();
      await render(<template>{{#if s.show}}<div class="x">x</div>{{/if}}</template>);
      await measure(assert, 'control (plain div)', mountUnmount(s));
    });

    test('EuiDataGrid mount/unmount', async function (assert) {
      const s = new Toggle();
      await render(
        <template>
          <EuiEmotionProvider>
            <div style="width:600px">
              {{#if s.show}}
                <EuiDataGrid aria-label="People" @columns={{COLUMNS}} @rowCount={{20}} />
              {{/if}}
            </div>
          </EuiEmotionProvider>
        </template>
      );
      await measure(assert, 'EuiDataGrid', mountUnmount(s));
    });

    test('EuiBasicTable mount/unmount', async function (assert) {
      const s = new Toggle();
      await render(
        <template>
          <EuiEmotionProvider>
            {{#if s.show}}<EuiBasicTable @items={{ITEMS}} @columns={{TABLE_COLUMNS}} />{{/if}}
          </EuiEmotionProvider>
        </template>
      );
      await measure(assert, 'EuiBasicTable', mountUnmount(s));
    });

    test('EuiInMemoryTable mount/unmount', async function (assert) {
      const s = new Toggle();
      await render(
        <template>
          <EuiEmotionProvider>
            {{#if s.show}}
              <EuiInMemoryTable
                @items={{ITEMS}}
                @columns={{TABLE_COLUMNS}}
                @search={{SEARCH}}
                @sorting={{true}}
                @pagination={{PAGINATION}}
              />
            {{/if}}
          </EuiEmotionProvider>
        </template>
      );
      await measure(assert, 'EuiInMemoryTable', mountUnmount(s));
    });

    test('EuiComboBox mount/open/unmount', async function (assert) {
      const s = new Toggle();
      await render(
        <template>
          <EuiEmotionProvider>
            {{#if s.show}}
              <EuiComboBox @options={{OPTIONS}} @selectedOptions={{NONE}} @onChange={{noop}} as |o|>{{o}}</EuiComboBox>
            {{/if}}
          </EuiEmotionProvider>
        </template>
      );
      await measure(
        assert,
        'EuiComboBox (opened list)',
        mountUnmount(s, async () => {
          await click('.euiComboBox__inputWrap');
          await waitUntil(() => document.querySelector('.euiComboBoxOptionsList'), { timeout: 2000 }).catch(() => {});
          // close first: unmounting while the list is open trips an
          // autotracking assertion (LH-06 in internal/memory-leak-audit/leak-harness.md)
          await triggerKeyEvent('.euiComboBox input', 'keydown', 'Escape');
        })
      );
    });

    test('EuiSelectable mount/unmount', async function (assert) {
      const s = new Toggle();
      await render(
        <template>
          {{#if s.show}}<EuiSelectable @options={{SELECTABLE_OPTIONS}} @onChange={{noop}} aria-label="Food" />{{/if}}
        </template>
      );
      await measure(assert, 'EuiSelectable', mountUnmount(s));
    });

    test('EuiSuperDatePicker mount/quick-menu/unmount', async function (assert) {
      const s = new Toggle();
      await render(
        <template>
          {{#if s.show}}<EuiSuperDatePicker @start="now-15m" @end="now" @onTimeChange={{noop}} />{{/if}}
        </template>
      );
      await measure(
        assert,
        'EuiSuperDatePicker (quick menu opened)',
        mountUnmount(s, async () => {
          await click('.euiQuickSelectPopover__anchor button');
        })
      );
    });

    test('EuiPopover open/close', async function (assert) {
      const s = new Toggle();
      s.show = true;
      const open = () => (s.open = true);
      await render(
        <template>
          <EuiPopover @isOpen={{s.open}} @closePopover={{s.close}}>
            <:button><EuiButton class="trigger" {{on "click" open}}>Open</EuiButton></:button>
            <:content><p>Popover body</p></:content>
          </EuiPopover>
        </template>
      );
      await measure(assert, 'EuiPopover (open/close, stays mounted)', async () => {
        s.open = true;
        await settled();
        s.open = false;
        await settled();
      });
    });

    test('EuiPopover unmount while open', async function (assert) {
      const s = new Toggle();
      s.open = true;
      await render(
        <template>
          {{#if s.show}}
            <EuiPopover @isOpen={{s.open}} @closePopover={{noop}}>
              <:button><EuiButton class="trigger">Open</EuiButton></:button>
              <:content><p>Popover body</p></:content>
            </EuiPopover>
          {{/if}}
        </template>
      );
      await measure(assert, 'EuiPopover (unmounted while open)', mountUnmount(s));
    });

    test('EuiFlyout mount/unmount', async function (assert) {
      const s = new Toggle();
      await render(
        <template>
          {{#if s.show}}
            <EuiFlyout @onClose={{noop}} aria-label="Flyout"><EuiFlyoutBody>Body</EuiFlyoutBody></EuiFlyout>
          {{/if}}
        </template>
      );
      await measure(assert, 'EuiFlyout', mountUnmount(s));
    });

    test('EuiModal mount/unmount', async function (assert) {
      const s = new Toggle();
      await render(
        <template>{{#if s.show}}<EuiModal @onClose={{noop}}><p>Hello</p></EuiModal>{{/if}}</template>
      );
      await measure(assert, 'EuiModal', mountUnmount(s));
    });

    test('EuiToolTip show/hide via hover', async function (assert) {
      const s = new Toggle();
      await render(
        <template>
          {{#if s.show}}
            <EuiToolTip @content="Helpful text" @title="Tip"><button type="button" class="anchor">Hover</button></EuiToolTip>
          {{/if}}
        </template>
      );
      await measure(
        assert,
        'EuiToolTip (hover, unmount)',
        mountUnmount(s, async () => {
          await triggerEvent('.anchor', 'mouseover');
          await waitUntil(() => document.querySelector('.euiToolTipPopover'), { timeout: 2000 }).catch(() => {});
        })
      );
    });

    test('EuiMarkdownEditor mount/unmount', async function (assert) {
      const s = new Toggle();
      const value = '# Title\n\nSome **text** and a [link](https://example.com)';
      await render(
        <template>{{#if s.show}}<EuiMarkdownEditor @value={{value}} @onChange={{noop}} @ariaLabel="Notes" />{{/if}}</template>
      );
      await measure(assert, 'EuiMarkdownEditor', mountUnmount(s));
    });

    test('EuiCodeBlock mount/unmount', async function (assert) {
      const s = new Toggle();
      await render(
        <template>
          {{#if s.show}}
            <EuiCodeBlock @language="js" @isCopyable={{true}} @overflowHeight={{100}}>const a = 1;
function b() { return a + 1; }</EuiCodeBlock>
          {{/if}}
        </template>
      );
      await measure(assert, 'EuiCodeBlock', mountUnmount(s));
    });

    test('EuiTourStep open/close', async function (assert) {
      const s = new Toggle();
      await render(
        <template>
          {{#if s.show}}
            <EuiTourStep @isStepOpen={{true}} @title="Welcome" @content="This is the search." @onFinish={{noop}}>
              <button type="button" class="anchor">Search</button>
            </EuiTourStep>
          {{/if}}
        </template>
      );
      await measure(assert, 'EuiTourStep (mount open, unmount)', mountUnmount(s));
    });

    test('EuiCollapsibleNav open/close', async function (assert) {
      const s = new Toggle();
      await render(
        <template>
          <EuiCollapsibleNav @isOpen={{s.open}} @onClose={{s.close}}>
            <:button as |trigger|><EuiButton class="toggle" {{trigger}}>Menu</EuiButton></:button>
            <:content><p class="nav-content">Nav</p></:content>
          </EuiCollapsibleNav>
        </template>
      );
      await measure(assert, 'EuiCollapsibleNav (open/close)', async () => {
        s.open = true;
        await settled();
        s.open = false;
        await settled();
      });
    });
  });
}
