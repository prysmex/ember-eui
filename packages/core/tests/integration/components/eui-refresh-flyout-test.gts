import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import {
  click,
  fillIn,
  render,
  settled,
  triggerEvent,
  triggerKeyEvent
} from '@ember/test-helpers';

import EuiAutoRefresh from '#src/components/eui-auto-refresh.gts';
import EuiAutoRefreshButton from '#src/components/eui-auto-refresh-button.gts';
import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import EuiFlyout from '#src/components/eui-flyout.gts';
import EuiFlyoutMenu from '#src/components/eui-flyout-menu.gts';
import EuiFlyoutResizable from '#src/components/eui-flyout-resizable.gts';
import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';

const light = resolveBorealisTheme('light').euiTheme;

type Change = {
  isPaused: boolean;
  refreshInterval: number;
  intervalUnits: 's' | 'm' | 'h';
};

class Refresh {
  @tracked isPaused = true;
  @tracked refreshInterval = 5000;
  @tracked intervalUnits?: 's' | 'm' | 'h';
  changes: Change[] = [];

  onChange = (change: Change) => {
    this.changes.push(change);
    this.isPaused = change.isPaused;
    this.refreshInterval = change.refreshInterval;
  };
}

const $ = <T extends HTMLElement = HTMLElement>(selector: string): T => {
  const element = document.querySelector<T>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
};

const TOGGLE = '[data-test-subj="superDatePickerToggleRefreshButton"]';

module('Integration | Component | Borealis auto refresh', function (hooks) {
  setupRenderingTest(hooks);

  test('EuiAutoRefresh renders a labelled read-only input with a prepend button', async function (assert) {
    const state = new Refresh();

    await render(
      <template>
        <EuiEmotionProvider>
          <EuiAutoRefresh
            @isPaused={{state.isPaused}}
            @refreshInterval={{state.refreshInterval}}
            @onRefreshChange={{state.onChange}}
            data-test-subj="auto"
          />
        </EuiEmotionProvider>
      </template>
    );

    assert.dom('.euiAutoRefresh').exists();
    assert
      .dom('input[data-test-subj="auto"]')
      .hasAttribute('aria-label', 'Auto refresh')
      .hasAttribute('readonly')
      .hasValue('Off');
    assert.dom('button.euiFormPrepend').hasText('Auto refresh');
    assert.dom('button.euiFormPrepend [data-icon-type="refreshTime"]').exists();
    assert.dom('.euiRefreshInterval', document.body).doesNotExist('the popover starts closed');
  });

  test('EuiAutoRefresh edits through the popover and reports interval and units', async function (assert) {
    const state = new Refresh();

    await render(
      <template>
        <EuiEmotionProvider>
          <EuiAutoRefresh
            @isPaused={{state.isPaused}}
            @refreshInterval={{state.refreshInterval}}
            @onRefreshChange={{state.onChange}}
          />
        </EuiEmotionProvider>
      </template>
    );

    await click('button.euiFormPrepend');
    assert.dom('.euiRefreshInterval', document.body).exists('the prepend button opens the popover');
    assert.dom('input[type="number"]', document.body).hasValue('5').isDisabled();

    await click($(TOGGLE));
    assert.deepEqual(state.changes.at(-1), {
      isPaused: false,
      refreshInterval: 5000,
      intervalUnits: 's'
    });
    assert.dom('input[readonly]').hasValue('5 seconds', 'the input follows the arguments');

    await fillIn($('input[type="number"]'), '2');
    assert.deepEqual(state.changes.at(-1), {
      isPaused: false,
      refreshInterval: 2000,
      intervalUnits: 's'
    });
    assert.dom('input[readonly]').hasValue('2 seconds');
  });

  test('EuiAutoRefresh toggles from the input, honors units, min interval and disabling', async function (assert) {
    const state = new Refresh();

    state.isPaused = false;
    state.refreshInterval = 90000;
    state.intervalUnits = 's';

    await render(
      <template>
        <EuiEmotionProvider>
          <EuiAutoRefresh
            @isPaused={{state.isPaused}}
            @refreshInterval={{state.refreshInterval}}
            @intervalUnits={{state.intervalUnits}}
            @minInterval={{10000}}
            @onRefreshChange={{state.onChange}}
          />
        </EuiEmotionProvider>
      </template>
    );

    assert.dom('input[readonly]').hasValue('90 seconds', 'a fixed unit is not rounded up');
    await click('input[readonly]');
    assert.dom('.euiRefreshInterval', document.body).exists('clicking the input opens the popover');
    assert.dom('input[type="number"]', document.body).hasValue('90').hasAttribute('min', '10');

    await fillIn($('input[type="number"]'), '3');
    assert.strictEqual(
      state.changes.at(-1)?.refreshInterval,
      10000,
      'values below the minimum are raised to it'
    );
    await click('input[readonly]');
    assert.dom('.euiRefreshInterval', document.body).doesNotExist('clicking again closes it');

    state.intervalUnits = undefined;
    state.refreshInterval = 90000;
    await settled();
    assert.dom('input[readonly]').hasValue('2 minutes', 'the default unit is rounded up');
  });

  test('EuiAutoRefresh disabled and editable variants', async function (assert) {
    const state = new Refresh();

    await render(
      <template>
        <EuiEmotionProvider>
          <EuiAutoRefresh
            @isDisabled={{true}}
            @readOnly={{false}}
            @onRefreshChange={{state.onChange}}
            data-test-subj="auto"
          />
        </EuiEmotionProvider>
      </template>
    );

    assert.dom('input[data-test-subj="auto"]').isDisabled().doesNotHaveAttribute('readonly');
    assert.dom('button.euiFormPrepend').isDisabled();
  });

  test('EuiAutoRefreshButton shows the state, a tooltip text and the popover', async function (assert) {
    const state = new Refresh();

    await render(
      <template>
        <EuiEmotionProvider>
          <EuiAutoRefreshButton
            @isPaused={{state.isPaused}}
            @refreshInterval={{state.refreshInterval}}
            @onRefreshChange={{state.onChange}}
            data-test-subj="autoButton"
          />
        </EuiEmotionProvider>
      </template>
    );

    assert.dom('button.euiAutoRefreshButton').hasText('Off');
    assert.dom('button.euiAutoRefreshButton [data-icon-type="refreshTime"]').exists();

    await click('button.euiAutoRefreshButton');
    assert.dom('.euiRefreshInterval', document.body).exists();
    assert.dom('.euiPopover__panel', document.body).exists();

    await click($(TOGGLE));
    assert.dom('button.euiAutoRefreshButton').hasText('5 seconds');
    assert.strictEqual(state.changes.at(-1)?.isPaused, false);
  });

  test('EuiAutoRefreshButton shorthand, size, color and disabled', async function (assert) {
    const state = new Refresh();

    state.isPaused = false;
    state.refreshInterval = 120000;

    await render(
      <template>
        <EuiEmotionProvider>
          <EuiAutoRefreshButton
            @isPaused={{state.isPaused}}
            @refreshInterval={{state.refreshInterval}}
            @shortHand={{true}}
            @size="xs"
            @isDisabled={{true}}
            @onRefreshChange={{state.onChange}}
          />
        </EuiEmotionProvider>
      </template>
    );

    assert.dom('button.euiAutoRefreshButton').hasText('2 m').isDisabled();
    assert.dom('button.euiAutoRefreshButton').hasAttribute('disabled');
  });
});

const flyoutEl = () => $('.euiFlyout');
const handle = () => $('.euiFlyout .euiResizableButton');

module('Integration | Component | Borealis resizable flyout', function (hooks) {
  setupRenderingTest(hooks);

  test('a plain flyout has no handle; the resizable one has a labelled separator button', async function (assert) {
    const noop = () => {};

    await render(
      <template>
        <EuiEmotionProvider>
          <EuiFlyout @onClose={{noop}}>plain</EuiFlyout>
        </EuiEmotionProvider>
      </template>
    );
    assert.dom('.euiResizableButton').doesNotExist();
  });

  test('EuiFlyoutResizable renders the handle at the inner edge with upstream styles', async function (assert) {
    const noop = () => {};

    await render(
      <template>
        <EuiEmotionProvider>
          <EuiFlyoutResizable @onClose={{noop}} @size={{400}} aria-label="Resizable">
            content
          </EuiFlyoutResizable>
        </EuiEmotionProvider>
      </template>
    );
    

    for (const animation of flyoutEl().getAnimations()) animation.finish();
    assert.dom(flyoutEl()).hasAttribute('role', 'dialog');
    assert
      .dom(handle())
      .hasAttribute('type', 'button')
      .hasAttribute('aria-label', 'Press the left or right arrow keys to adjust panels size');
    const style = getComputedStyle(handle());
    const flyoutRect = flyoutEl().getBoundingClientRect();

    assert.strictEqual(style.position, 'absolute');
    assert.strictEqual(style.cursor, 'col-resize');
    assert.strictEqual(style.height, getComputedStyle(flyoutEl()).height, 'full height');
    // overlay flyout on the right: the handle straddles the inline start edge
    const handleRect = handle().getBoundingClientRect();

    assert.true(
      handleRect.left <= flyoutRect.left + 1 && handleRect.right > flyoutRect.left,
      `straddles the inline start edge (${handleRect.left}-${handleRect.right} vs ${flyoutRect.left})`
    );
    assert.true(Math.abs(flyoutRect.width - 400) <= 1, `starts at the size (${flyoutRect.width})`);
  });

  test('arrow keys resize by 10px, report the width and clamp to the min and max widths', async function (assert) {
    const widths: number[] = [];
    const onResize = (width: number) => widths.push(width);
    const noop = () => {};

    await render(
      <template>
        <EuiEmotionProvider>
          <EuiFlyoutResizable
            @onClose={{noop}}
            @size={{400}}
            @minWidth={{380}}
            @maxWidth={{420}}
            @onResize={{onResize}}
          >content</EuiFlyoutResizable>
        </EuiEmotionProvider>
      </template>
    );
    

    handle().focus();
    // the flyout is on the right: ArrowLeft grows it towards the page
    await triggerKeyEvent(handle(), 'keydown', 'ArrowLeft');
    assert.strictEqual(Math.round(flyoutEl().getBoundingClientRect().width), 410);
    await triggerKeyEvent(handle(), 'keydown', 'ArrowLeft');
    await triggerKeyEvent(handle(), 'keydown', 'ArrowLeft');
    assert.strictEqual(Math.round(flyoutEl().getBoundingClientRect().width), 420, 'max width');
    assert.deepEqual(widths.map(Math.round), [410, 420], 'onResize reports each change');

    for (let i = 0; i < 6; i++) await triggerKeyEvent(handle(), 'keydown', 'ArrowRight');
    assert.strictEqual(Math.round(flyoutEl().getBoundingClientRect().width), 380, 'min width');

    await triggerKeyEvent(handle(), 'keydown', 'ArrowUp');
    assert.strictEqual(Math.round(flyoutEl().getBoundingClientRect().width), 380, 'other keys do nothing');
  });

  test('dragging the handle resizes on the window and reports once at the end', async function (assert) {
    const widths: number[] = [];
    const onResize = (width: number) => widths.push(width);
    const noop = () => {};

    await render(
      <template>
        <EuiEmotionProvider>
          <EuiFlyoutResizable @onClose={{noop}} @size={{400}} @onResize={{onResize}}>content</EuiFlyoutResizable>
        </EuiEmotionProvider>
      </template>
    );
    

    await triggerEvent(handle(), 'mousedown', { clientX: 500 });
    await triggerEvent(window, 'mousemove', { clientX: 450 });
    assert.strictEqual(Math.round(flyoutEl().getBoundingClientRect().width), 450, 'moving left grows a right flyout');
    await triggerEvent(window, 'mousemove', { clientX: 540 });
    assert.strictEqual(Math.round(flyoutEl().getBoundingClientRect().width), 360);
    assert.deepEqual(widths, [], 'not reported while dragging');

    await triggerEvent(window, 'mouseup', {});
    assert.deepEqual(widths.map(Math.round), [360], 'reported on mouse up');
    await triggerEvent(window, 'mousemove', { clientX: 100 });
    assert.strictEqual(Math.round(flyoutEl().getBoundingClientRect().width), 360, 'listeners are removed');
  });

  test('a left flyout grows with ArrowRight and a new size resets the width', async function (assert) {
    const state = new (class {
      @tracked size: number | string = 400;
    })();
    const noop = () => {};

    await render(
      <template>
        <EuiEmotionProvider>
          <EuiFlyoutResizable @onClose={{noop}} @side="left" @size={{state.size}}>content</EuiFlyoutResizable>
        </EuiEmotionProvider>
      </template>
    );
    

    await triggerKeyEvent(handle(), 'keydown', 'ArrowRight');
    assert.strictEqual(Math.round(flyoutEl().getBoundingClientRect().width), 410);

    state.size = 500;
    await settled();
    assert.strictEqual(Math.round(flyoutEl().getBoundingClientRect().width), 500, 'numeric size replaces the user width');

    state.size = 's';
    await settled();
    await triggerKeyEvent(handle(), 'keydown', 'ArrowRight');
    const named = flyoutEl().getBoundingClientRect().width;
    assert.true(named > 300 && named < 500, `a named size is measured, then resized (${named})`);
  });

  test('the width follows the window and the handle is an accessible keyboard target', async function (assert) {
    const noop = () => {};

    await render(
      <template>
        <EuiEmotionProvider>
          <EuiFlyoutResizable @onClose={{noop}} @size={{400}}>content</EuiFlyoutResizable>
        </EuiEmotionProvider>
      </template>
    );
    

    handle().focus();
    assert.strictEqual(document.activeElement, handle(), 'focusable');
    assert.dom(handle()).hasTagName('button');
    // The size is a percentage of the window, so it keeps its share when the window resizes.
    assert.true(
      /\d%/.test(flyoutEl().getAttribute('style') ?? ''),
      'stored as a share of the window'
    );
  });
});

module('Integration | Component | Borealis flyout menu', function (hooks) {
  setupRenderingTest(hooks);

  test('renders the upstream container, a hidden title and the close button', async function (assert) {
    let closed = 0;
    const onClose = () => closed++;

    await render(
      <template>
        <EuiEmotionProvider>
          <EuiFlyoutMenu @title="Menu title" @titleId="menu-title" @onClose={{onClose}} />
        </EuiEmotionProvider>
      </template>
    );

    const menu = $('.euiFlyoutMenu');
    const style = getComputedStyle(menu);

    assert.dom(menu).hasAttribute('data-test-subj', 'euiFlyoutMenu');
    // upstream: 3 * base + 2 * thin border
    assert.strictEqual(style.blockSize, `${parseFloat(light.size.base) * 3 + 2}px`);
    assert.strictEqual(style.borderBlockEndWidth, light.border.width.thin);
    assert.strictEqual(style.paddingBlockStart, light.size.s);
    assert.dom('#menu-title').hasText('Menu title').hasTagName('h3');
    assert.strictEqual(
      getComputedStyle($('#menu-title')).position,
      'absolute',
      'the title is visually hidden by default'
    );
    assert.strictEqual(getComputedStyle($('#menu-title')).overflow, 'hidden');
    assert.dom('[data-test-subj="euiFlyoutCloseButton"]').hasAttribute('aria-label', 'Close this dialog');
    await click('[data-test-subj="euiFlyoutCloseButton"]');
    assert.strictEqual(closed, 1);
  });

  test('hideTitle=false shows the title and hideCloseButton removes the button', async function (assert) {
    await render(
      <template>
        <EuiEmotionProvider>
          <EuiFlyoutMenu @title="Visible" @titleId="visible-title" @hideTitle={{false}} @hideCloseButton={{true}} />
        </EuiEmotionProvider>
      </template>
    );

    assert.true($('#visible-title').getBoundingClientRect().width > 10);
    assert.dom('[data-test-subj="euiFlyoutCloseButton"]').doesNotExist();
  });

  test('back button, history popover and dividers', async function (assert) {
    const calls: string[] = [];
    const items = [
      { title: 'Previous page', iconType: 'document', onClick: () => calls.push('previous') },
      { title: 'Older page', onClick: () => calls.push('older') }
    ];
    const back = { onClick: () => calls.push('back') };

    await render(
      <template>
        <EuiEmotionProvider>
          <EuiFlyoutMenu
            @showBackButton={{true}}
            @backButtonProps={{back}}
            @historyItems={{items}}
          />
        </EuiEmotionProvider>
      </template>
    );

    assert.dom('[data-test-subj="euiFlyoutMenuBackButton"]').hasText('Back');
    assert.dom('.euiFlyoutMenu__divider').exists({ count: 1 }, 'between back and history');
    assert.dom('.euiFlyoutMenu__divider').hasAttribute('aria-hidden', 'true');
    await click('[data-test-subj="euiFlyoutMenuBackButton"]');
    assert.deepEqual(calls, ['back']);

    await click('[data-test-subj="euiFlyoutMenuHistoryButton"]');
    assert.dom('[data-test-subj="euiFlyoutMenuHistoryItem-0"]', document.body).hasText('Previous page');
    assert.dom('[data-test-subj="euiFlyoutMenuHistoryItem-1"]', document.body).hasText('Older page');
    await click($('[data-test-subj="euiFlyoutMenuHistoryItem-1"]'));
    assert.deepEqual(calls, ['back', 'older']);
    await settled();
    assert.dom('[data-test-subj="euiFlyoutMenuHistoryItem-0"]', document.body).doesNotExist('choosing closes it');
  });

  test('a single history item shows no history and pagination replaces back/history', async function (assert) {
    const calls: string[] = [];
    const items = [{ title: 'Only', onClick: () => {} }];
    const pagination = {
      currentIndex: 0,
      total: 3,
      onPrevious: () => calls.push('previous'),
      onNext: () => calls.push('next'),
      onFirst: () => calls.push('first'),
      onLast: () => calls.push('last')
    };

    await render(
      <template>
        <EuiEmotionProvider>
          <EuiFlyoutMenu @showBackButton={{true}} @historyItems={{items}} @pagination={{pagination}} />
        </EuiEmotionProvider>
      </template>
    );

    assert.dom('[data-test-subj="euiFlyoutMenuHistoryButton"]').doesNotExist();
    assert.dom('[data-test-subj="euiFlyoutMenuBackButton"]').doesNotExist('pagination replaces the back button');
    assert.dom('.euiText[aria-hidden="true"]').hasText('1 of 3');
    assert.dom('[role="status"]').hasText('1 of 3');
    assert.dom('[data-test-subj="euiFlyoutMenuPaginationFirst"]').isDisabled();
    assert.dom('[data-test-subj="euiFlyoutMenuPaginationPrev"]').isDisabled();
    assert.dom('[data-test-subj="euiFlyoutMenuPaginationPrev"] [data-icon-type="chevronSingleLeft"]').exists('jump controls make the chevrons horizontal');

    await click('[data-test-subj="euiFlyoutMenuPaginationNext"]');
    await click('[data-test-subj="euiFlyoutMenuPaginationLast"]');
    assert.deepEqual(calls, ['next', 'last']);
  });

  test('leading and trailing actions, tooltips, deprecated custom actions and the close divider', async function (assert) {
    const calls: string[] = [];
    const leading = [
      { iconType: 'gear', ariaLabel: 'Settings', onClick: () => calls.push('settings'), dataTestSubj: 'settings' }
    ];
    const trailing = [
      { iconType: 'share', ariaLabel: 'Share', toolTipContent: 'Share it', onClick: () => calls.push('share'), dataTestSubj: 'share' },
      { iconType: 'trash', ariaLabel: 'Delete', isDisabled: true, dataTestSubj: 'delete' }
    ];
    const custom = [{ iconType: 'pin', ariaLabel: 'Pin', onClick: () => calls.push('pin'), dataTestSubj: 'pin' }];

    await render(
      <template>
        <EuiEmotionProvider>
          <EuiFlyoutMenu @leadingActions={{leading}} @trailingActions={{trailing}} @customActions={{custom}} />
        </EuiEmotionProvider>
      </template>
    );

    assert.dom('[data-test-subj="settings"]').hasAttribute('aria-label', 'Settings');
    assert.dom('[data-test-subj="share"]').hasAttribute('aria-label', 'Share');
    assert.dom('[data-test-subj="delete"]').isDisabled();
    assert.dom('[data-test-subj="pin"]').doesNotExist('trailingActions takes precedence over customActions');
    assert.dom('.euiFlyoutMenu__divider').exists({ count: 1 }, 'divider before the close button');
    await click('[data-test-subj="settings"]');
    await click('[data-test-subj="share"]');
    assert.deepEqual(calls, ['settings', 'share']);
  });

  test('uses the nearest theme and honors token overrides', async function (assert) {
    const overrides = { colors: { LIGHT: { borderBaseSubdued: '#123456' }, DARK: { borderBaseSubdued: '#123456' } } };

    await render(
      <template>
        <EuiEmotionProvider @borealisOverrides={{overrides}}>
          <EuiFlyoutMenu @title="T" />
        </EuiEmotionProvider>
      </template>
    );

    const probe = document.createElement('div');
    probe.style.color = '#123456';
    document.body.appendChild(probe);
    const expected = getComputedStyle(probe).color;
    probe.remove();

    assert.strictEqual(getComputedStyle($('.euiFlyoutMenu')).borderBlockEndColor, expected);
  });
});
