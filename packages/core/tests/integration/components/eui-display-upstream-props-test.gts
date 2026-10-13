import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import {
  click,
  render,
  settled,
  triggerEvent,
  triggerKeyEvent,
  waitUntil
} from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';

import EuiCallOut from '#src/components/eui-call-out.gts';
import EuiComment from '#src/components/eui-comment.gts';
import EuiConfirmModal from '#src/components/eui-confirm-modal.gts';
import EuiContextMenu from '#src/components/eui-context-menu.gts';
import EuiContextMenuItem from '#src/components/eui-context-menu-item.gts';
import EuiContextMenuPanel from '#src/components/eui-context-menu-panel.gts';
import EuiEmptyPrompt from '#src/components/eui-empty-prompt.gts';
import EuiExpression from '#src/components/eui-expression.gts';
import EuiGlobalToastList from '#src/components/eui-global-toast-list.gts';
import EuiListGroup from '#src/components/eui-list-group.gts';
import EuiListGroupItem from '#src/components/eui-list-group-item.gts';
import EuiPinnableListGroup from '#src/components/eui-pinnable-list-group.gts';
import EuiSideNav from '#src/components/eui-side-nav.gts';
import EuiSteps from '#src/components/eui-steps.gts';
import EuiStepsHorizontal from '#src/components/eui-steps-horizontal.gts';
import EuiToast from '#src/components/eui-toast.gts';

import type { EuiGlobalToast } from '#src/components/eui-global-toast-list.gts';
import type { EuiToastProps } from '#src/services/eui-toaster.ts';
import type EuiToasterService from '#src/services/eui-toaster.ts';
import type { TOC } from '@ember/component/template-only';

const noop = () => {};

function q<T extends Element = HTMLElement>(
  selector: string,
  root: ParentNode = document
): T {
  const element = root.querySelector<T>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

function all<T extends Element = HTMLElement>(
  selector: string,
  root: ParentNode = document
): T[] {
  return [...root.querySelectorAll<T>(selector)];
}

const text = (element: Element) => element.textContent!.replace(/\s+/g, ' ').trim();

module('Integration | Component | display upstream props', function (hooks) {
  setupRenderingTest(hooks);

  module('EuiSteps / EuiStepsHorizontal @steps', function () {
    test('EuiSteps renders one EuiStep per entry, numbered from @firstStepNumber', async function (assert) {
      const steps = [
        { title: 'Install', children: 'Run npm install', status: 'complete' as const },
        { title: 'Configure', children: 'Edit the file', 'data-test-subj': 'second', className: 'my-step' },
        { title: 'Run', headingElement: 'h3' as const, titleSize: 'xs' as const }
      ];
      const copy = JSON.stringify(steps);

      await render(
        <template>
          <EuiSteps @steps={{steps}} @firstStepNumber={{4}} @headingElement="h2" />
        </template>
      );

      const items = all('.euiStep');
      assert.strictEqual(items.length, 3);
      assert.deepEqual(
        items.slice(1).map((item) => text(q('.euiStepNumber__number', item))),
        ['5', '6'],
        'numbers count up from @firstStepNumber'
      );
      assert.dom(q('.euiStepNumber__icon', items[0])).hasAttribute('aria-label', /Step 4.* is complete/, 'status of an entry');
      assert.deepEqual(
        items.map((item) => text(q('.euiStep__title', item))),
        ['Install', 'Configure', 'Run']
      );
      assert.dom(items[0]).containsText('Run npm install', 'children text');
      assert.dom(items[1]).hasAttribute('data-test-subj', 'second').hasClass('my-step');
      assert.dom(q('.euiStep__title', items[0])).hasTagName('h2', 'list heading element');
      assert.dom(q('.euiStep__title', items[2])).hasTagName('h3', 'an entry heading element wins');
      assert.strictEqual(JSON.stringify(steps), copy, 'consumer data untouched');
    });

    test('EuiSteps <:step> renders rich content for each entry', async function (assert) {
      const steps = [{ title: 'One', code: 'npm i' }, { title: 'Two', code: 'npm start' }];

      await render(
        <template>
          <EuiSteps @steps={{steps}}>
            <:step as |step index|><code data-index={{index}}>{{step.code}}</code></:step>
          </EuiSteps>
        </template>
      );

      assert.deepEqual(
        all('.euiStep code').map((code) => [code.dataset['index'], code.textContent]),
        [['0', 'npm i'], ['1', 'npm start']]
      );
    });

    test('EuiSteps without @steps keeps rendering its block', async function (assert) {
      await render(
        <template>
          <EuiSteps><span data-block>Block</span></EuiSteps>
        </template>
      );
      assert.dom('[data-block]').exists();
    });

    test('EuiStepsHorizontal renders buttons from entries, with upstream aria and clicks', async function (assert) {
      const clicks: string[] = [];
      const steps = [
        { title: 'Plan', status: 'complete' as const, onClick: () => clicks.push('plan') },
        { title: 'Build', status: 'current' as const, onClick: () => clicks.push('build'), 'data-test-subj': 'build' },
        { title: 'Ship', disabled: true, onClick: () => clicks.push('ship') },
        { title: 'Done', 'aria-label': 'Custom label', onClick: noop, size: 's' as const }
      ];

      await render(<template><EuiStepsHorizontal @steps={{steps}} @size="xs" /></template>);

      const items = all('ol.euiStepsHorizontal > li');
      assert.strictEqual(items.length, 4);
      assert.dom(items[1]).hasAttribute('aria-current', 'step');
      assert.dom(items[0]).doesNotHaveAttribute('aria-current');
      const buttons = all<HTMLButtonElement>('.euiStepHorizontal');
      assert.dom(buttons[0]).hasAttribute('data-step-status', 'complete');
      assert.dom(buttons[1]).hasAttribute('data-test-subj', 'build');
      assert.dom(buttons[2]).hasAttribute('data-step-status', 'disabled').isDisabled();
      assert.dom(buttons[3]).hasAttribute('aria-label', 'Custom label');
      assert.dom(buttons[0]).hasAttribute('aria-label', /Step 1/, 'generated label kept without an override');
      assert.dom(q('.euiStepNumber__number', buttons[3])).hasText('4', 'numbered by position');

      await click(buttons[0]);
      await click(buttons[1]);
      assert.deepEqual(clicks, ['plan', 'build']);
    });
  });

  module('EuiGlobalToastList @toasts / EuiToast @text', function () {
    test('renders @toasts instead of the service and leaves removal to dismissToast', async function (assert) {
      const toaster = this.owner.lookup('service:eui-toaster') as EuiToasterService;
      toaster.show({ id: 'service', title: 'From the service' });

      class State {
        @tracked toasts: EuiGlobalToast[] = [
          { id: 'a', title: 'Saved', text: 'Your dashboard was saved', color: 'success' },
          { id: 'b', title: 'Warning', color: 'warning' }
        ];
      }
      const state = new State();
      const original = state.toasts;
      const dismissed: string[] = [];
      const dismiss = (toast: EuiToastProps) => {
        dismissed.push(toast.id!);
        state.toasts = state.toasts.filter((t) => t.id !== toast.id);
      };

      // long-lived toasts keep run loop timers pending: pause them (hover)
      const rendered = render(
        <template>
          <EuiGlobalToastList @toasts={{state.toasts}} @dismissToast={{dismiss}} @toastLifeTimeMs={{60000}} />
        </template>
      );
      await waitUntil(() => document.querySelectorAll('.euiToast').length === 2);
      await triggerEvent('.euiGlobalToastList', 'mouseenter');
      await rendered;

      assert.dom('.euiToast').exists({ count: 2 });
      assert.dom('.euiGlobalToastList').doesNotContainText('From the service');
      assert.dom(all('.euiToast')[0]).containsText('Your dashboard was saved', '`text` is the body');

      await click(q('[data-test-subj="toastCloseButton"]', all('.euiToast')[0]));
      await waitUntil(() => dismissed.length === 1);
      await settled();
      assert.deepEqual(dismissed, ['a']);
      assert.dom('.euiToast').exists({ count: 1 });
      assert.strictEqual(original.length, 2, 'the consumer array is not mutated');
      assert.strictEqual(toaster.toasts.length, 1, 'the service is untouched');
      toaster.remove(toaster.toasts[0]!);
    });

    test('dismisses @toasts after toastLifeTimeMs (a toast\'s own lifetime wins)', async function (assert) {
      class State {
        @tracked toasts: EuiGlobalToast[] = [
          { id: 'long', title: 'Long' },
          { id: 'short', title: 'Short', toastLifeTimeMs: 30 }
        ];
      }
      const state = new State();
      const dismissed: string[] = [];
      const dismiss = (toast: EuiToastProps) => {
        dismissed.push(toast.id!);
        state.toasts = state.toasts.filter((t) => t.id !== toast.id);
      };

      await render(
        <template>
          <EuiGlobalToastList @toasts={{state.toasts}} @dismissToast={{dismiss}} @toastLifeTimeMs={{400}} />
        </template>
      );
      await waitUntil(() => dismissed.length === 2, { timeout: 3000 });
      await settled();
      assert.deepEqual(dismissed, ['short', 'long'], 'the toast\'s own lifetime wins');
      assert.dom('.euiToast').doesNotExist();

      state.toasts = [{ id: 'added', title: 'Added', toastLifeTimeMs: 20 }];
      await waitUntil(() => dismissed.length === 3, { timeout: 3000 });
      assert.deepEqual(dismissed, ['short', 'long', 'added'], 'toasts added later are scheduled too');
    });

    test('"Clear all" calls dismissToast for every @toasts entry', async function (assert) {
      const toasts = [
        { id: '1', title: 'One' },
        { id: '2', title: 'Two' },
        { id: '3', title: 'Three' }
      ];
      const dismissed: string[] = [];
      const dismiss = (toast: EuiToastProps) => dismissed.push(toast.id!);

      const rendered = render(
        <template>
          <EuiGlobalToastList @toasts={{toasts}} @dismissToast={{dismiss}} @toastLifeTimeMs={{60000}} />
        </template>
      );
      await waitUntil(() => document.querySelector('[data-test-subj="euiClearAllToastsButton"]'));
      await click('[data-test-subj="euiClearAllToastsButton"]');
      await rendered;
      assert.deepEqual(dismissed, ['1', '2', '3']);
    });

    test('EuiToast @text renders like @body, and @body wins', async function (assert) {
      await render(
        <template>
          <EuiToast @title="A" @text="Text body" data-a />
          <EuiToast @title="B" @text="Text body" @body="Body wins" data-b />
        </template>
      );
      assert.dom('[data-a] [data-test-subj="euiToastText"]').hasText('Text body');
      assert.dom('[data-b] [data-test-subj="euiToastText"]').hasText('Body wins');
    });
  });

  module('Context menu', function () {
    test('EuiContextMenuPanel @items renders a menu of items', async function (assert) {
      const clicks: string[] = [];
      const items = [
        { name: 'Copy', icon: 'copy', onClick: () => clicks.push('copy'), 'data-test-subj': 'copy' },
        { isSeparator: true as const, key: 'sep' },
        { name: 'Docs', href: '#docs' },
        { name: 'Delete', disabled: true, onClick: () => clicks.push('delete') }
      ];

      await render(
        <template>
          <EuiContextMenuPanel @title="Actions" @items={{items}}><span data-block>ignored</span></EuiContextMenuPanel>
        </template>
      );

      const list = q('.euiContextMenuPanel__list');
      assert.dom(list).hasAttribute('role', 'menu');
      assert.dom(list).hasAttribute('aria-labelledby', q('.euiContextMenuPanelTitle__text').id);
      assert.dom('[data-block]').doesNotExist('items win over the block');
      assert.deepEqual(
        all('.euiContextMenuItem').map((item) => item.getAttribute('role')),
        ['menuitem', 'menuitem', 'menuitem']
      );
      assert.dom('hr[role="separator"]').exists();
      assert.dom('a.euiContextMenuItem').hasAttribute('href', '#docs');
      await click('[data-test-subj="copy"]');
      assert.deepEqual(clicks, ['copy']);

      await triggerKeyEvent(q('.euiContextMenuPanel'), 'keydown', 'ArrowDown');
      assert.strictEqual(document.activeElement, q('a.euiContextMenuItem'), 'arrow down moves from the clicked item to the next');
    });

    test('EuiContextMenuPanel without @items keeps its block and no menu role', async function (assert) {
      await render(<template><EuiContextMenuPanel><span data-block>content</span></EuiContextMenuPanel></template>);
      assert.dom('[data-block]').exists();
      assert.dom('.euiContextMenuPanel__list').doesNotHaveAttribute('role');
    });

    test('EuiContextMenu @onPanelChange reports the panel and direction', async function (assert) {
      const changes: unknown[] = [];
      const onPanelChange = (change: unknown) => changes.push(change);
      const panels = [
        { id: 0, title: 'Root', items: [{ name: 'More', panel: 1 }] },
        { id: 1, title: 'More', items: [{ name: 'Leaf' }] }
      ];

      await render(
        <template>
          <EuiContextMenu @panels={{panels}} @initialPanelId={{0}} @onPanelChange={{onPanelChange}} />
        </template>
      );
      await click('.euiContextMenuItem');
      assert.deepEqual(changes, [{ panelId: 1, direction: 'next' }]);
      await click('[data-test-subj="contextMenuPanelTitleButton"]');
      assert.deepEqual(changes, [
        { panelId: 1, direction: 'next' },
        { panelId: 0, direction: 'previous' }
      ]);
    });

    test('EuiContextMenuItem @external and secure rel', async function (assert) {
      await render(
        <template>
          <EuiContextMenuItem @href="https://elastic.co" @target="_blank" data-blank>Blank</EuiContextMenuItem>
          <EuiContextMenuItem @href="https://elastic.co" @external={{true}} data-external>External</EuiContextMenuItem>
          <EuiContextMenuItem @href="https://elastic.co" @target="_blank" @external={{false}} data-off>Off</EuiContextMenuItem>
          <EuiContextMenuItem @href="#local" data-local>Local</EuiContextMenuItem>
          <EuiContextMenuItem @href="https://elastic.co" @external={{true}} @disabled={{true}} data-disabled>Disabled</EuiContextMenuItem>
        </template>
      );

      assert.dom('[data-blank]').hasAttribute('rel', 'noopener noreferrer');
      assert.dom('[data-blank] .euiContextMenuItem__text [role="presentation"]').exists();
      assert.dom('[data-blank] .euiContextMenuItem__text').containsText('(external, opens in a new tab or window)');
      assert.dom('[data-external] .euiContextMenuItem__text').containsText('(external)');
      assert.dom('[data-external] .euiContextMenuItem__text').doesNotContainText('new tab');
      assert.dom('[data-off] .euiContextMenuItem__text [role="presentation"]').doesNotExist();
      assert.dom('[data-local] .euiContextMenuItem__text [role="presentation"]').doesNotExist();
      assert.dom('[data-local]').hasAttribute('rel', 'noreferrer');
      assert.dom('[data-disabled] .euiContextMenuItem__text [role="presentation"]').doesNotExist('no icon on a disabled (button) item');
    });

    test('EuiContextMenuItem @hasAriaDisabled keeps a disabled item focusable', async function (assert) {
      let clicks = 0;
      const onClick = () => clicks++;

      await render(
        <template>
          <EuiContextMenuItem @disabled={{true}} @hasAriaDisabled={{true}} data-aria {{on "click" onClick}}>Aria</EuiContextMenuItem>
          <EuiContextMenuItem @disabled={{true}} data-native>Native</EuiContextMenuItem>
        </template>
      );

      assert.dom('[data-aria]').hasAttribute('aria-disabled', 'true').doesNotHaveAttribute('disabled');
      assert.dom('[data-native]').hasAttribute('disabled').doesNotHaveAttribute('aria-disabled');
      q('[data-aria]').focus();
      assert.strictEqual(document.activeElement, q('[data-aria]'), 'focusable');
      await click('[data-aria]');
      assert.strictEqual(clicks, 0, 'clicks are blocked');
    });
  });

  module('List groups', function () {
    test('EuiListGroup @ariaLabelledby', async function (assert) {
      await render(
        <template>
          <h2 id="list-title">Links</h2>
          <EuiListGroup @ariaLabelledby="list-title" />
        </template>
      );
      assert.dom('ul.euiListGroup').hasAttribute('aria-labelledby', 'list-title');
    });

    test('EuiPinnableListGroup @showToolTips, @ariaLabelledby and item keys', async function (assert) {
      const items = [
        { label: 'Discover', href: '#discover', 'data-test-subj': 'discover' },
        { label: 'Visualize', href: '#visualize', showToolTip: false, pinned: true }
      ];
      await render(
        <template>
          <EuiPinnableListGroup @listItems={{items}} @onPinClick={{noop}} @showToolTips={{true}} @ariaLabelledby="nav" />
        </template>
      );
      assert.dom('ul.euiListGroup').hasAttribute('aria-labelledby', 'nav');
      assert.dom('.euiListGroupItem__tooltip').exists({ count: 1 }, 'the list default, an item can opt out');
      assert.dom('a[data-test-subj="discover"]').exists('other keys become attributes');
      assert.dom('a[data-test-subj="discover"]').doesNotHaveAttribute('label');
    });

    test('EuiListGroupItem @iconProps, @icon and @hasAriaDisabled', async function (assert) {
      const iconProps = { color: 'danger', size: 'l', 'data-icon': 'yes', className: 'my-icon', css: { marginInlineEnd: '7px' } };
      const Custom: TOC<{ Element: HTMLSpanElement }> = <template><span data-custom ...attributes>★</span></template>;
      const customProps = { css: { marginInlineEnd: '9px' } };
      let clicks = 0;
      const onClick = () => clicks++;

      await render(
        <template>
          <ul>
            <EuiListGroupItem @label="Typed" @iconType="bell" @iconProps={{iconProps}} data-typed />
            <EuiListGroupItem @label="Custom" @icon={{Custom}} @iconProps={{customProps}} data-custom-item />
            <EuiListGroupItem @label="Both" @iconType="bell" @icon={{Custom}} data-both />
            <EuiListGroupItem @label="Aria" @onClick={{onClick}} @isDisabled={{true}} @hasAriaDisabled={{true}} data-aria />
            <EuiListGroupItem @label="Native" @onClick={{onClick}} @isDisabled={{true}} data-native />
          </ul>
        </template>
      );

      const typed = q('[data-typed] .euiListGroupItem__icon');
      assert.dom(typed).hasClass('my-icon').hasAttribute('data-icon', 'yes');
      assert.strictEqual(getComputedStyle(typed).marginInlineEnd, '7px', 'iconProps.css');
      const custom = q('[data-custom-item] [data-custom]');
      assert.dom(custom).hasClass('euiListGroupItem__icon');
      assert.strictEqual(getComputedStyle(custom).marginInlineEnd, '9px', 'iconProps.css on a custom icon');
      assert.dom('[data-both] [data-custom]').doesNotExist('@iconType wins');

      assert.dom('[data-aria]').hasAttribute('aria-disabled', 'true').doesNotHaveAttribute('disabled');
      assert.dom('[data-native]').hasAttribute('disabled');
      await click('[data-aria]');
      assert.strictEqual(clicks, 0);
    });

    test('EuiListGroup @listItems pass icon, iconProps and hasAriaDisabled', async function (assert) {
      const Custom: TOC<{ Element: HTMLSpanElement }> = <template><span data-custom ...attributes>★</span></template>;
      const items = [
        { label: 'Custom', icon: Custom },
        { label: 'Aria', onClick: noop, isDisabled: true, hasAriaDisabled: true, iconType: 'bell', iconProps: { 'data-icon': 'x' } }
      ];
      await render(<template><EuiListGroup @listItems={{items}} /></template>);
      assert.dom('[data-custom].euiListGroupItem__icon').exists();
      assert.dom('button.euiListGroupItem__button').hasAttribute('aria-disabled', 'true');
      assert.dom('[data-icon="x"]').exists();
    });
  });

  module('EuiSideNav', function () {
    const items = [
      {
        id: 'root',
        name: 'Root',
        items: [
          { id: 'a', name: 'A very long item name', href: '#a' },
          { id: 'b', name: 'B', href: '#b', truncate: true, items: [{ id: 'c', name: 'C', href: '#c' }] }
        ]
      }
    ];

    test('@truncate reaches every item, an item\'s own truncate wins', async function (assert) {
      const none: never[] = [];
      await render(
        <template>
          <div data-wrap><EuiSideNav @items={{items}} @truncate={{false}} @mobileBreakpoints={{none}} @selectedItem="c" /></div>
          <div data-default><EuiSideNav @items={{items}} @mobileBreakpoints={{none}} /></div>
        </template>
      );
      const labels = (root: string) =>
        Object.fromEntries(
          all(`${root} [class*="euiSideNavItemButton__label"]`).map((label) => [
            text(label),
            label.classList.contains('eui-textTruncate')
          ])
        );
      assert.deepEqual(labels('[data-wrap]'), {
        Root: false,
        'A very long item name': false,
        B: true,
        C: false
      });
      assert.true(Object.values(labels('[data-default]')).every(Boolean), 'truncated by default');
    });

    test('@isOpenOnMobile opens the mobile nav (upstream name)', async function (assert) {
      const sizes = ['xs', 's', 'm', 'l', 'xl'] as const;
      await render(
        <template>
          <EuiSideNav @heading="Docs" @items={{items}} @mobileBreakpoints={{sizes}} @isOpenOnMobile={{true}} />
        </template>
      );
      assert.dom('nav.euiSideNav').hasClass('euiSideNav-isOpenMobile');
      assert.dom('.euiSideNav__mobileToggle').hasAttribute('aria-expanded', 'true');
    });
  });

  module('Misc', function () {
    test('EuiComment @verticalAlign overrides the body-based alignment', async function (assert) {
      await render(
        <template>
          <ol>
            <EuiComment data-default><:username>jane</:username><:event>edited</:event></EuiComment>
            <EuiComment @verticalAlign="top" data-top><:username>jane</:username><:event>edited</:event></EuiComment>
            <EuiComment @verticalAlign="center" data-center><:username>j</:username><:event>commented</:event><:body>Body</:body></EuiComment>
          </ol>
        </template>
      );
      assert.dom('[data-default]').hasClass(/euiTimelineItem-center/);
      assert.dom('[data-top]').hasClass(/euiTimelineItem-top/);
      assert.dom('[data-center]').hasClass(/euiTimelineItem-center/);
    });

    test('EuiExpression @descriptionProps and @valueProps', async function (assert) {
      const descriptionProps = { className: 'my-desc', 'data-desc': 'd', css: { letterSpacing: '3px' }, style: { fontStyle: 'italic' } };
      const valueProps = { className: 'my-value', id: 'value-id', 'aria-label': 'Value' };
      await render(
        <template>
          <EuiExpression @description="when" @value="avg()" @descriptionProps={{descriptionProps}} @valueProps={{valueProps}} @display="columns" @descriptionWidth={{100}} />
        </template>
      );
      const description = q('.euiExpression__description');
      assert.dom(description).hasClass('my-desc').hasAttribute('data-desc', 'd').doesNotHaveAttribute('css');
      assert.strictEqual(getComputedStyle(description).letterSpacing, '3px');
      assert.strictEqual(getComputedStyle(description).fontStyle, 'italic');
      assert.strictEqual(getComputedStyle(description).flexBasis, '100px', 'columns width kept');
      assert.dom('.euiExpression__value').hasClass('my-value').hasAttribute('id', 'value-id').hasAttribute('aria-label', 'Value');
    });

    test('EuiCallOut @dismissButtonProps', async function (assert) {
      const props = { 'data-test-subj': 'closeTip', 'aria-label': 'Hide tip', className: 'my-close', title: 'Hide', isDisabled: false };
      await render(
        <template>
          <EuiCallOut @title="Tip" @onDismiss={{noop}} @dismissButtonProps={{props}} data-custom />
          <EuiCallOut @title="Plain" @onDismiss={{noop}} data-plain />
        </template>
      );
      assert.dom('[data-custom] [data-test-subj="closeTip"]').hasAttribute('aria-label', 'Hide tip').hasClass('my-close').hasAttribute('title', 'Hide');
      assert.dom('[data-plain] [data-test-subj="euiDismissCalloutButton"]').hasAttribute('aria-label', 'Dismiss this callout');
    });

    test('EuiEmptyPrompt @hasShadow', async function (assert) {
      await render(
        <template>
          <EuiEmptyPrompt @title="Shadow" @color="plain" @hasBorder={{false}} @hasShadow={{true}} data-shadow />
          <EuiEmptyPrompt @title="None" @color="plain" @hasBorder={{false}} data-none />
        </template>
      );
      assert.notStrictEqual(getComputedStyle(q('[data-shadow]')).boxShadow, 'none');
      assert.strictEqual(getComputedStyle(q('[data-none]')).boxShadow, 'none');
    });

    test('EuiConfirmModal @outsideClickCloses', async function (assert) {
      class State {
        @tracked outside = false;
      }
      const state = new State();
      let cancels = 0;
      const onCancel = () => cancels++;
      await render(
        <template>
          <EuiConfirmModal @title="Sure?" @onCancel={{onCancel}} @onConfirm={{noop}} @cancelButtonText="No" @confirmButtonText="Yes" @outsideClickCloses={{state.outside}} />
        </template>
      );
      await click(q('.euiOverlayMask'));
      assert.strictEqual(cancels, 0, 'off by default');
      state.outside = true;
      await settled();
      await click(q('.euiOverlayMask'));
      assert.strictEqual(cancels, 1, 'mask click cancels');
    });
  });
});
