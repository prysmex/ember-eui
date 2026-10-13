import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { hash } from '@ember/helper';
import { on } from '@ember/modifier';
import {
  blur,
  click,
  find,
  focus,
  render,
  settled,
  triggerEvent,
  waitUntil
} from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import EuiBetaBadge from '#src/components/eui-beta-badge.gts';
import EuiButton from '#src/components/eui-button.gts';
import EuiCollapsibleNav from '#src/components/eui-collapsible-nav.gts';
import EuiCollapsibleNavGroup from '#src/components/eui-collapsible-nav-group.gts';
import EuiColorPalettePicker from '#src/components/eui-color-palette-picker.gts';
import EuiColorPicker from '#src/components/eui-color-picker.gts';
import EuiComboBox from '#src/components/eui-combo-box.gts';
import EuiComboBoxPill from '#src/components/eui-combo-box-pill.gts';
import EuiCopy from '#src/components/eui-copy.gts';
import EuiDualRange from '#src/components/eui-dual-range.gts';
import EuiFlyout from '#src/components/eui-flyout.gts';
import EuiFlyoutMenu from '#src/components/eui-flyout-menu.gts';
import EuiHeaderLink from '#src/components/eui-header-link.gts';
import EuiHeaderLinks from '#src/components/eui-header-links.gts';
import EuiIconTip from '#src/components/eui-icon-tip.gts';
import EuiKeyPadMenu from '#src/components/eui-key-pad-menu.gts';
import EuiKeyPadMenuItem from '#src/components/eui-key-pad-menu-item.gts';
import EuiRange from '#src/components/eui-range.gts';
import EuiToolTip from '#src/components/eui-tool-tip.gts';
import EuiTourStep from '#src/components/eui-tour-step.gts';

const noop = () => {};
const tooltip = () => document.querySelector<HTMLElement>('.euiToolTip');

function q<T extends Element = HTMLElement>(
  selector: string,
  root: ParentNode = document
): T {
  const element = root.querySelector<T>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

/** ember-qunit scales the test container to 50%, which skews positions. */
function unzoom(hooks: NestedHooks) {
  hooks.beforeEach(function () {
    const container = document.getElementById('ember-testing');
    if (container) container.style.transform = 'none';
  });
  hooks.afterEach(function () {
    const container = document.getElementById('ember-testing');
    if (container) container.style.transform = '';
  });
}

const wait = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

module('Integration | Component | popover and flyout props', function (hooks) {
  setupRenderingTest(hooks);

  test('EuiToolTip @anchorProps: class, css, style, attributes and listeners', async function (assert) {
    const entered: string[] = [];
    const anchorProps = {
      className: 'my-anchor',
      css: { outlineOffset: '7px' },
      style: { marginLeft: 3 },
      'data-test-subj': 'anchor',
      onMouseEnter: () => entered.push('enter')
    };

    await render(
      <template>
        <EuiToolTip @content="Tip" @anchorClassName="own" @anchorProps={{anchorProps}}>
          <button type="button">Hover</button>
        </EuiToolTip>
      </template>
    );

    const anchor = q('.euiToolTipAnchor');
    assert.dom(anchor).hasClass('own').hasClass('my-anchor');
    assert.dom(anchor).hasAttribute('data-test-subj', 'anchor');
    assert.dom(anchor).hasStyle({ outlineOffset: '7px', marginLeft: '3px' });
    assert.dom(anchor).doesNotHaveAttribute('classname');

    await triggerEvent(anchor, 'mouseenter');
    assert.deepEqual(entered, ['enter'], 'onMouseEnter runs');
    await triggerEvent(anchor, 'mouseover');
    await waitUntil(tooltip);
    assert.dom(tooltip()).hasText('Tip', 'the tooltip still shows');
  });

  test('EuiIconTip @anchorProps, @offset, @disableScreenReaderOutput', async function (assert) {
    const anchorProps = { 'data-test-subj': 'icon-anchor' };

    await render(
      <template>
        <div style="padding: 100px">
          <EuiIconTip
            @content="Info"
            @position="bottom"
            @offset={{40}}
            @repositionOnScroll={{true}}
            @disableScreenReaderOutput={{true}}
            @anchorProps={{anchorProps}}
          />
        </div>
      </template>
    );

    const anchor = q('.euiToolTipAnchor');
    assert.dom(anchor).hasAttribute('data-test-subj', 'icon-anchor');
    assert.dom(anchor).doesNotHaveAttribute('id', 'no wrapper id when visual only');

    await triggerEvent(anchor, 'mouseover');
    await waitUntil(tooltip);
    await settled();

    const gap =
      tooltip()!.getBoundingClientRect().top -
      anchor.getBoundingClientRect().bottom;
    assert.true(Math.abs(gap - 40) < 2, `offset 40 (gap ${gap})`);
    assert
      .dom('.euiToolTipAnchor .euiIcon')
      .doesNotHaveAttribute('aria-describedby', 'not described');
  });

  test('EuiBetaBadge @anchorProps on the wrapper span or the tooltip anchor', async function (assert) {
    const plain = { 'data-test-subj': 'plain-wrapper', className: 'wrap' };
    const tipped = { 'data-test-subj': 'tip-wrapper' };

    await render(
      <template>
        <EuiBetaBadge @label="Beta" @anchorProps={{plain}} data-b="plain" />
        <EuiBetaBadge @label="Lab" @tooltipContent="Experimental" @anchorProps={{tipped}} data-b="tip" />
        <EuiBetaBadge @label="Plain" data-b="none" />
      </template>
    );

    assert.dom('[data-b="plain"]').hasClass('euiBetaBadge');
    assert
      .dom(q('[data-b="plain"]').parentElement)
      .hasTagName('span')
      .hasClass('wrap')
      .hasAttribute('data-test-subj', 'plain-wrapper');
    assert
      .dom(q('[data-b="tip"]').parentElement)
      .hasClass('euiToolTipAnchor')
      .hasAttribute('data-test-subj', 'tip-wrapper');
    assert
      .dom(q('[data-b="none"]').parentElement)
      .hasTagName('span', 'upstream always wraps the badge in a span');
  });

  test('EuiCopy @tooltipProps', async function (assert) {
    const blurs: string[] = [];
    const tooltipProps = {
      position: 'bottom',
      anchorProps: { 'data-test-subj': 'copy-anchor' },
      className: 'copy-tip',
      onBlur: () => blurs.push('blur')
    };

    await render(
      <template>
        <EuiCopy @textToCopy="hello" @beforeMessage="Click to copy" @tooltipProps={{tooltipProps}} as |copy|>
          <button type="button" class="copy" {{on "click" copy}}>Copy</button>
        </EuiCopy>
      </template>
    );

    assert.dom('.euiToolTipAnchor').hasAttribute('data-test-subj', 'copy-anchor');
    await triggerEvent('.euiToolTipAnchor', 'mouseover');
    await waitUntil(tooltip);
    assert.dom(tooltip()).hasClass('copy-tip').hasText('Click to copy');
    assert.dom(tooltip()).hasClass(/euiToolTip/);
    await focus('.copy');
    await blur('.copy');
    assert.deepEqual(blurs, ['blur'], 'tooltipProps.onBlur is called');
  });

  test('EuiKeyPadMenu legendProps and EuiKeyPadMenuItem @betaBadgeTooltipProps', async function (assert) {
    const checkable = {
      legend: 'Pick one',
      legendProps: { className: 'my-legend', 'data-test-subj': 'legend' }
    };
    const tooltipProps = {
      position: 'bottom',
      anchorProps: { 'data-test-subj': 'item-anchor' }
    };

    await render(
      <template>
        <EuiKeyPadMenu @checkable={{checkable}}>
          <EuiKeyPadMenuItem @checkable="single" @name="k" @label="One" />
        </EuiKeyPadMenu>
        <EuiKeyPadMenu as |Key|>
          <Key>
            <EuiKeyPadMenuItem
              @label="Docs"
              @betaBadgeLabel="Beta"
              @betaBadgeTooltipContent="Not GA yet"
              @betaBadgeTooltipProps={{tooltipProps}}
              data-k="beta"
            />
          </Key>
        </EuiKeyPadMenu>
      </template>
    );

    assert
      .dom('legend.my-legend')
      .hasAttribute('data-test-subj', 'legend')
      .hasText('Pick one');

    const item = q('[data-k="beta"]');
    assert
      .dom(item.parentElement)
      .hasClass('euiToolTipAnchor', 'the tooltip wraps the whole item')
      .hasAttribute('data-test-subj', 'item-anchor');
    assert
      .dom('[data-k="beta"] .euiKeyPadMenuItem__betaBadge')
      .hasAttribute('aria-hidden', 'true')
      .hasText('B');

    await triggerEvent(q('[data-test-subj="item-anchor"]'), 'mouseover');
    await waitUntil(tooltip);
    assert.dom(tooltip()).containsText('Beta').containsText('Not GA yet');
  });

  test('EuiColorPalettePicker @isOpen, @itemClassName, @popoverProps', async function (assert) {
    const palettes = [
      { value: 'a', title: 'Alpha', type: 'fixed' as const, palette: ['#000', '#fff'] },
      { value: 'b', title: 'Beta', type: 'text' as const }
    ];
    const popoverProps = { panelClassName: 'palette-panel' };

    await render(
      <template>
        <EuiColorPalettePicker
          @palettes={{palettes}}
          @valueOfSelected="a"
          @onChange={{noop}}
          @isOpen={{true}}
          @itemClassName="palette-item"
          @popoverProps={{popoverProps}}
        />
      </template>
    );

    await waitUntil(() => document.querySelector('.palette-panel'));
    assert.dom('.palette-panel', document.body).exists('popoverProps reach the list popover');
    assert.strictEqual(
      document.querySelectorAll('.palette-item').length,
      2,
      'itemClassName on each option'
    );
  });

  test('EuiColorPicker @popoverZIndex', async function (assert) {
    await render(
      <template>
        <EuiColorPicker @color="#ff0000" @onChange={{noop}} @popoverZIndex={{4321}} />
      </template>
    );

    await click('input.euiFieldText');
    await waitUntil(() => document.querySelector('.euiColorPicker__popoverPanel'));
    const panel = q('.euiColorPicker__popoverPanel');
    assert.strictEqual(getComputedStyle(panel).zIndex, '4321');
  });

  test('EuiHeaderLinks @popoverProps and @popoverButtonProps', async function (assert) {
    const clicks: string[] = [];
    const popoverButtonProps = {
      iconType: 'menu',
      'data-test-subj': 'links-button',
      'aria-label': 'Links',
      onClick: () => clicks.push('click')
    };
    const popoverProps = {
      panelClassName: 'links-panel',
      panelPaddingSize: 'l',
      anchorPosition: 'downLeft',
      className: 'links-popover'
    };

    await render(
      <template>
        <EuiHeaderLinks
          @popoverBreakpoints="all"
          @popoverProps={{popoverProps}}
          @popoverButtonProps={{popoverButtonProps}}
        >
          <EuiHeaderLink>Docs</EuiHeaderLink>
        </EuiHeaderLinks>
      </template>
    );

    const button = q('[data-test-subj="links-button"]');
    assert.dom(button).hasAttribute('aria-label', 'Links');
    assert.dom('[data-test-subj="links-button"] [data-icon-type="menu"], [data-test-subj="links-button"] .euiIcon').exists();
    assert.dom('.euiPopover.links-popover').exists('className on the popover root');

    await click(button);
    assert.deepEqual(clicks, ['click'], 'onClick runs before toggling');
    await waitUntil(() => document.querySelector('.links-panel'));
    assert.dom('.links-panel', document.body).hasStyle({ paddingTop: '24px' });
  });

  test('EuiRange and EuiDualRange @inputPopoverProps', async function (assert) {
    const one = { className: 'range-pop', panelClassName: 'range-panel' };
    const two = { className: 'dual-pop', panelClassName: 'dual-panel' };

    await render(
      <template>
        <EuiRange @showInput="inputWithPopover" @value={{3}} @onChange={{noop}} @inputPopoverProps={{one}} data-r="one" />
        <EuiDualRange @showInput="inputWithPopover" @value={{array 1 5}} @onChange={{noop}} @inputPopoverProps={{two}} data-r="two" />
      </template>
    );

    assert.dom('.euiRange__popover.range-pop').exists();
    assert.dom('.euiDualRange__popover.dual-pop').exists();
    await focus('input.euiRangeInput[data-r="one"]');
    await waitUntil(() => document.querySelector('.range-panel'));
    assert.dom('.range-panel', document.body).exists();
  });

  test('EuiTourStep passes the popover props on', async function (assert) {
    const panelProps = { 'data-test-subj': 'tour-panel' };
    const positions: string[] = [];
    const onPositionChange = (position: string) => positions.push(position);

    await render(
      <template>
        <EuiTourStep
          @isStepOpen={{true}}
          @title="Step"
          @content="Text"
          @onFinish={{noop}}
          @panelClassName="my-tour"
          @panelProps={{panelProps}}
          @panelPaddingSize="l"
          @onPositionChange={{onPositionChange}}
          @repositionOnScroll={{true}}
        >
          <button type="button">Anchor</button>
        </EuiTourStep>
        <EuiTourStep
          @isStepOpen={{true}}
          @title="Arrowless"
          @content="Text"
          @onFinish={{noop}}
          @hasArrow={{false}}
          @panelClassName="arrowless"
        >
          <button type="button">Other</button>
        </EuiTourStep>
        <EuiTourStep
          @isStepOpen={{false}}
          @isOpen={{true}}
          @title="Forced"
          @content="Text"
          @onFinish={{noop}}
          @panelClassName="forced"
        >
          <:default><button type="button">Forced</button></:default>
          <:arrowChildren><span class="custom-arrow-child"></span></:arrowChildren>
        </EuiTourStep>
      </template>
    );

    await waitUntil(() => document.querySelector('.my-tour'));
    await settled();
    const panel = q('.my-tour');
    assert.dom(panel).hasClass('euiTour').hasAttribute('data-test-subj', 'tour-panel');
    assert.dom(panel).hasStyle({ paddingTop: '24px' });
    assert.true(positions.length > 0, 'onPositionChange is called');
    assert.dom('.my-tour .euiTour__beacon', document.body).exists('beacon by default');
    assert.dom('.arrowless .euiPopover__arrow', document.body).doesNotExist('hasArrow=false');
    assert.dom('.forced', document.body).exists('isOpen wins over isStepOpen');
    assert.dom('.forced .custom-arrow-child', document.body).exists('the arrowChildren block');
    assert.dom('.forced .euiTour__beacon', document.body).doesNotExist();
  });

  test('EuiFlyout @includeSelectorInFocusTrap and fixed headers', async function (assert) {
    await render(
      <template>
        <button type="button" class="outside-shard" data-shard>Shard</button>
        <button type="button" class="outside">Outside</button>
        <EuiFlyout @onClose={{noop}} @includeSelectorInFocusTrap="[data-shard]" @pushAnimation={{true}} aria-label="F">
          <button type="button" class="inside">Inside</button>
        </EuiFlyout>
      </template>
    );

    
    assert
      .dom('.euiFlyout [id$="-description"], .euiFlyout p', document.body)
      .exists();
    assert.true(
      document.body.textContent!.includes(
        'You can still continue tabbing through other global page landmarks.'
      ),
      'the screen reader description mentions the shards'
    );

    q<HTMLButtonElement>('.outside-shard').focus();
    await wait(50);
    assert.strictEqual(
      document.activeElement,
      find('.outside-shard'),
      'a shard keeps focus'
    );
  });

  test('EuiFlyout without shards keeps the plain description', async function (assert) {
    await render(
      <template>
        <EuiFlyout @onClose={{noop}} @includeFixedHeadersInFocusTrap={{false}} aria-label="F">
          <button type="button">Inside</button>
        </EuiFlyout>
      </template>
    );

    
    assert.false(
      document.body.textContent!.includes('You can still continue tabbing'),
      'no shard sentence'
    );
  });

  test('EuiFlyoutMenu accepts @iconType', async function (assert) {
    await render(
      <template>
        <EuiFlyoutMenu @title="Menu" @iconType="gear" @hideCloseButton={{true}} />
      </template>
    );

    assert.dom('.euiFlyoutMenu').exists();
  });

  test('EuiCollapsibleNav passes the flyout props on', async function (assert) {
    class State {
      @tracked isOpen = false;
      toggle = () => (this.isOpen = !this.isOpen);
      close = () => (this.isOpen = false);
    }
    const state = new State();
    const closeButtonProps = { className: 'nav-close' };

    await render(
      <template>
        <EuiCollapsibleNav
          @isOpen={{state.isOpen}}
          @onClose={{state.close}}
          @closeButtonProps={{closeButtonProps}}
          @resizable={{true}}
          @minWidth={{200}}
          @hasAnimation={{false}}
        >
          <:button as |trigger|>
            <EuiButton class="toggle" {{trigger}} {{on "click" state.toggle}}>Menu</EuiButton>
          </:button>
          <:content><p>Nav</p></:content>
        </EuiCollapsibleNav>
      </template>
    );

    await click('.toggle');
    

    assert.dom('.euiCollapsibleNav', document.body).exists();
    assert
      .dom('.euiCollapsibleNav', document.body)
      .doesNotHaveAttribute('data-managed-flyout', 'session defaults to never');
    assert.dom('.nav-close', document.body).exists('closeButtonProps');
    assert.dom('.euiCollapsibleNav .euiResizableButton', document.body).exists('resizable');

    q<HTMLElement>('.toggle').focus();
    await wait(50);
    assert.strictEqual(
      document.activeElement,
      find('.toggle'),
      'the toggle button is part of the focus trap'
    );
  });

  test('EuiCollapsibleNavGroup passes the accordion props on', async function (assert) {
    const buttonProps = { 'data-test-subj': 'group-button' };
    const arrowProps = { className: 'group-arrow' };
    const iconProps = { color: 'danger', 'data-test-subj': 'group-icon', className: 'icon-class' };

    await render(
      <template>
        <EuiCollapsibleNavGroup
          @isCollapsible={{true}}
          @iconType="gear"
          @iconProps={{iconProps}}
          @buttonProps={{buttonProps}}
          @arrowProps={{arrowProps}}
          @forceState="closed"
          @isLoading={{true}}
          @borders="all"
          @buttonContentClassName="content-class"
          data-g="one"
        >
          <:title>Settings</:title>
          <:content><p>Links</p></:content>
        </EuiCollapsibleNavGroup>
        <EuiCollapsibleNavGroup
          @isCollapsible={{true}}
          @isDisabled={{true}}
          @buttonClassName="custom-heading"
          @buttonContent="Plain text"
          data-g="two"
        >
          <:title>Ignored</:title>
          <:content><p>Links</p></:content>
        </EuiCollapsibleNavGroup>
      </template>
    );

    assert.dom('[data-g="one"] .euiAccordion__button').hasAttribute('aria-expanded', 'false');
    assert.dom('[data-g="one"] .group-arrow').exists('arrowProps');
    assert.dom('[data-g="one"] .content-class').exists('buttonContentClassName');
    assert.dom('[data-g="one"] [data-test-subj="group-icon"]').hasClass('icon-class');
    assert.dom('[data-g="one"] .euiLoadingSpinner, [data-g="one"] [role="progressbar"]').exists('isLoading');
    assert.dom('[data-g="one"] .euiCollapsibleNavGroup__heading').exists();

    assert.dom('[data-g="two"] .custom-heading').exists('buttonClassName replaces the heading class');
    assert.dom('[data-g="two"] .euiCollapsibleNavGroup__heading').doesNotExist();
    assert.dom('[data-g="two"] .euiAccordion__button').containsText('Plain text');
    assert.dom('[data-g="two"] .euiCollapsibleNavGroup__title').doesNotExist();
    assert.dom('[data-g="two"] .euiAccordion__button').isDisabled();
  });

  module('positions', function (hooks) {
  unzoom(hooks);

  test('EuiComboBox inputPopoverProps: root attributes, offset and onPanelResize', async function (assert) {
    const widths: number[] = [];
    const props = {
      className: 'root-class',
      'data-test-subj': 'combo-root',
      offset: 30,
      panelMinWidth: 400,
      onPanelResize: (width: number) => widths.push(width)
    };
    const options = [{ label: 'Titan' }, { label: 'Io' }];
    const input = (c: string) =>
      `[data-c="${c}"] input.euiComboBox__input:not(.fake-input-for-html-form-validity)`;
    const listTop = () =>
      parseFloat(q('.ember-basic-dropdown-content').style.top);

    await render(
      <template>
        <div style="display: flex; gap: 20px; align-items: flex-start">
          <div style="width: 300px">
            <EuiComboBox @options={{options}} @onChange={{noop}} @inputPopoverProps={{props}} data-c="offset" />
          </div>
          <div style="width: 300px">
            <EuiComboBox @options={{options}} @onChange={{noop}} data-c="plain" />
          </div>
        </div>
      </template>
    );

    assert
      .dom('[data-c="offset"]')
      .hasClass('root-class')
      .hasAttribute('data-test-subj', 'combo-root');
    await waitUntil(() => widths.length > 0);
    assert.strictEqual(widths[widths.length - 1], 400, 'panelMinWidth wins over the input width');

    await click(input('plain'));
    await waitUntil(() => document.querySelector('.ember-basic-dropdown-content'));
    await settled();
    const plainTop = listTop();
    await click(input('offset'));
    await waitUntil(() => q('[data-c="offset"]').classList.contains('euiComboBox-isOpen'));
    await settled();
    assert.strictEqual(listTop() - plainTop, 30, 'offset moves the list 30px down');
  });

  test('EuiComboBox closes on scroll by default, not with closeOnScroll=false', async function (assert) {
    const options = [{ label: 'Titan' }, { label: 'Io' }];
    const keepOpen = { closeOnScroll: false };
    const scroller = (selector: string) => q(`${selector}`);

    await render(
      <template>
        <div class="scroll-a" style="height: 100px; overflow: auto">
          <div style="height: 400px">
            <EuiComboBox @options={{options}} @onChange={{noop}} data-c="a" />
          </div>
        </div>
        <div class="scroll-b" style="height: 100px; overflow: auto">
          <div style="height: 400px">
            <EuiComboBox @options={{options}} @onChange={{noop}} @inputPopoverProps={{keepOpen}} data-c="b" />
          </div>
        </div>
      </template>
    );

    const isOpen = (c: string) => q(`[data-c="${c}"]`).classList.contains('euiComboBox-isOpen');

    await click('[data-c="a"] input.euiComboBox__input:not(.fake-input-for-html-form-validity)');
    await waitUntil(() => isOpen('a'));
    await wait(600);
    scroller('.scroll-a').scrollTop = 20;
    await triggerEvent(scroller('.scroll-a'), 'scroll');
    await waitUntil(() => !isOpen('a'));
    assert.false(isOpen('a'), 'closed when its scroll container scrolls');

    await click('[data-c="b"] input.euiComboBox__input:not(.fake-input-for-html-form-validity)');
    await waitUntil(() => isOpen('b'));
    await wait(600);
    scroller('.scroll-b').scrollTop = 20;
    await triggerEvent(scroller('.scroll-b'), 'scroll');
    
    assert.true(isOpen('b'), 'stays open with closeOnScroll=false');
  });

  test('EuiComboBox inputPopoverProps.container keeps the list within it', async function (assert) {
    const options = [{ label: 'Titan' }];

    class State {
      @tracked container?: HTMLElement;
    }
    const state = new State();

    await render(
      <template>
        <div class="bounds" style="position: relative; margin-left: 200px; width: 300px">
          <div style="margin-left: 150px; width: 100px">
            <EuiComboBox
              @options={{options}}
              @onChange={{noop}}
              @inputPopoverProps={{hash container=state.container buffer=0 panelMinWidth=250}}
            />
          </div>
        </div>
      </template>
    );

    state.container = q('.bounds');
    await settled();
    await click('input.euiComboBox__input:not(.fake-input-for-html-form-validity)');
    await waitUntil(() => document.querySelector('.ember-basic-dropdown-content'));
    await settled();

    const bounds = q('.bounds').getBoundingClientRect();
    const panel = q('.ember-basic-dropdown-content').getBoundingClientRect();
    assert.true(
      panel.right <= bounds.right + 1,
      `right edge ${panel.right} within ${bounds.right}`
    );
  });

  });

  test('EuiComboBoxPill @onClickAriaLabel', async function (assert) {
    const option = { label: 'Kiwi', onClick: noop };

    await render(
      <template>
        <EuiComboBoxPill @option={{option}} @onClickAriaLabel="Edit kiwi" data-p="custom">Kiwi</EuiComboBoxPill>
        <EuiComboBoxPill @option={{option}} data-p="default">Kiwi</EuiComboBoxPill>
      </template>
    );

    assert.dom('[data-p="custom"] [aria-label="Edit kiwi"], [data-p="custom"][aria-label="Edit kiwi"]').exists();
    assert.dom('[data-p="default"] [aria-label="Change"], [data-p="default"][aria-label="Change"]').exists();
  });
});

function array<T>(...items: T[]): T[] {
  return items;
}
