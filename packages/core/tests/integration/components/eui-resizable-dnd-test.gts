import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import {
  blur,
  click,
  focus,
  render,
  rerender,
  triggerEvent,
  triggerKeyEvent
} from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import EuiDragDropContext from '#src/components/eui-drag-drop-context.gts';
import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import EuiResizableContainer from '#src/components/eui-resizable-container.gts';
import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';

import type { DropResult } from '#src/components/eui-drag-drop-context.gts';
import type { EuiBorealisOverrides } from '#src/utils/eui/theme.ts';

const light = resolveBorealisTheme('light').euiTheme;
const dark = resolveBorealisTheme('dark').euiTheme;
const TRANSPARENT = 'rgba(0, 0, 0, 0)';
const PANEL_RADIUS = (light.border.radius as unknown as Record<string, string>)['panel']!;

/** Normalize any CSS color to the browser's computed `rgb()` form. */
function rgb(color: string) {
  const probe = document.createElement('span');
  probe.style.color = color;
  document.body.appendChild(probe);
  const value = getComputedStyle(probe).color;
  probe.remove();
  return value;
}

function el<T extends Element = HTMLElement>(root: Element, selector: string): T {
  const element = root.querySelector<T>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

function style(root: Element, selector: string, pseudo?: string) {
  return getComputedStyle(el(root, selector), pseudo);
}

/** Layout box in CSS pixels (the ember-qunit container is scaled). */
function box(element: Element) {
  const container = document.querySelector<HTMLElement>('#ember-testing')!;
  const scale = container.getBoundingClientRect().width / container.offsetWidth;
  const rect = element.getBoundingClientRect();
  const round = (value: number) => Math.round((value / scale) * 10) / 10;
  return {
    width: round(rect.width),
    height: round(rect.height),
    left: round(rect.left),
    right: round(rect.right),
    top: round(rect.top),
    bottom: round(rect.bottom)
  };
}

/** Client-rect width/height, the unit the resize engine measures in (unscaled). */
function raw(element: Element, horizontal = true) {
  const rect = element.getBoundingClientRect();
  return horizontal ? rect.width : rect.height;
}

/** A hex token at an alpha, as the browser computes `transparentize`. */
function rgba(hex: string, alpha: number) {
  const [r, g, b] = rgb(hex).match(/\d+/g)!.map(Number);
  return `rgba(${r}, ${g}, ${b}, ${alpha})`;
}

/** Lets the upstream transitions (fast 150ms, slow 350ms) finish. */
const wait = (ms = 450) => new Promise((resolve) => setTimeout(resolve, ms));

module('Integration | Component | eui-resizable-dnd (Borealis)', function (hooks) {
  setupRenderingTest(hooks);

  module('EuiResizableContainer', function () {
    test('horizontal layout: panels side by side, the button overlaps them', async function (assert) {
      await render(
        <template>
          <div style="width: 1000px; height: 200px;">
            <EuiResizableContainer style="height: 200px;" as |c|>
              <c.Panel @id="left" @initialSize={{30}}>Left</c.Panel>
              <c.Button />
              <c.Panel @id="right" @initialSize={{70}}>Right</c.Panel>
            </EuiResizableContainer>
          </div>
        </template>
      );
      const container = el(this.element, '.euiResizableContainer');
      const left = el(this.element, '#left');
      const right = el(this.element, '#right');
      const button = el(this.element, '.euiResizableButton');
      const containerStyle = getComputedStyle(container);

      assert.strictEqual(containerStyle.display, 'flex');
      assert.strictEqual(containerStyle.flexDirection, 'row');
      assert.strictEqual(box(container).width, 1000, 'width 100%');
      assert.strictEqual(box(left).width, 300, '30%');
      assert.strictEqual(box(right).width, 700, '70%');
      assert.strictEqual(box(left).right, box(right).left, 'the button takes no room');
      assert.strictEqual(box(left).top, box(right).top, 'side by side');

      const b = getComputedStyle(button);
      assert.strictEqual(b.cursor, 'col-resize');
      assert.strictEqual(b.width, light.size.base, 'size.base wide');
      assert.strictEqual(b.height, '200px', 'full height');
      assert.strictEqual(b.marginLeft, '-8px', 'half its size over each neighbour');
      assert.strictEqual(b.marginRight, '-8px');
      assert.strictEqual(b.zIndex, '1');
      assert.strictEqual(b.display, 'flex');
      assert.strictEqual(b.justifyContent, 'center');
      assert.strictEqual(b.alignItems, 'center', 'alignIndicator center by default');
      assert.strictEqual(b.backgroundColor, TRANSPARENT, 'no native button face');
      assert.strictEqual(b.borderTopStyle, 'none');
      assert.strictEqual(b.gap, '2px', 'grab handle: two lines, 2 x thin border apart');
      assert.strictEqual(box(button).left - box(container).left, 292, 'centered on the edge');

      for (const pseudo of ['::before', '::after']) {
        const p = getComputedStyle(button, pseudo);
        assert.strictEqual(p.width, '1px', `${pseudo} thin`);
        assert.strictEqual(p.height, light.size.m, `${pseudo} size.m long`);
        assert.strictEqual(p.backgroundColor, rgb(light.colors.darkestShade), `${pseudo} darkestShade`);
      }
      assert
        .dom(button)
        .hasAttribute('type', 'button')
        .hasAttribute('data-test-subj', 'euiResizableButton')
        .hasAria('label', 'Press the left or right arrow keys to adjust panels size');
      assert.dom(left).hasAttribute('data-position', 'first').doesNotHaveAttribute('data-collapsed');
      assert.dom(right).hasAttribute('data-position', 'last');
      assert.strictEqual(getComputedStyle(left).position, 'relative');
    });

    test('vertical layout: panels stacked, row-resize button', async function (assert) {
      await render(
        <template>
          <div style="width: 600px;">
            <EuiResizableContainer @direction="vertical" style="height: 400px;" as |c|>
              <c.Panel @id="top" @initialSize={{25}}>Top</c.Panel>
              <c.Button />
              <c.Panel @id="bottom" @initialSize={{75}}>Bottom</c.Panel>
            </EuiResizableContainer>
          </div>
        </template>
      );
      const top = el(this.element, '#top');
      const bottom = el(this.element, '#bottom');
      const button = el(this.element, '.euiResizableButton');

      assert.strictEqual(style(this.element, '.euiResizableContainer').flexDirection, 'column');
      assert.strictEqual(box(top).height, 100);
      assert.strictEqual(box(bottom).height, 300);
      assert.strictEqual(box(top).width, 600, 'full width');
      assert.strictEqual(box(top).bottom, box(bottom).top, 'stacked, the button takes no room');

      const b = getComputedStyle(button);
      assert.strictEqual(b.cursor, 'row-resize');
      assert.strictEqual(b.flexDirection, 'column');
      assert.strictEqual(b.height, '16px');
      assert.strictEqual(b.width, '600px');
      assert.strictEqual(b.marginTop, '-8px');
      assert.strictEqual(b.marginBottom, '-8px');
      assert.strictEqual(getComputedStyle(button, '::before').height, '1px');
      assert.strictEqual(getComputedStyle(button, '::before').width, '12px');
      assert.dom(button).hasAria('label', 'Press the up or down arrow keys to adjust panels size');

      const start = raw(top, false);
      await triggerKeyEvent(button, 'keydown', 'ArrowDown');
      assert.strictEqual(Math.round(raw(top, false) - start), 10, 'ArrowDown grows the top panel by 10px');
      await triggerKeyEvent(button, 'keydown', 'ArrowRight');
      assert.strictEqual(Math.round(raw(top, false) - start), 10, 'horizontal arrows are ignored');
    });

    test('indicator, alignIndicator and accountForScrollbars', async function (assert) {
      class State {
        @tracked indicator: 'handle' | 'border' = 'border';
        @tracked align: 'center' | 'start' | 'end' = 'start';
        @tracked scrollbars: 'before' | 'after' | 'both' | undefined = 'before';
      }
      const state = new State();

      await render(
        <template>
          <div style="width: 1000px;">
            <EuiResizableContainer style="height: 100px;" as |c|>
              <c.Panel @initialSize={{50}}>A</c.Panel>
              <c.Button
                @indicator={{state.indicator}}
                @alignIndicator={{state.align}}
                @accountForScrollbars={{state.scrollbars}}
              />
              <c.Panel @initialSize={{50}}>B</c.Panel>
            </EuiResizableContainer>
          </div>
        </template>
      );
      const button = el(this.element, '.euiResizableButton');
      let before = getComputedStyle(button, '::before');

      assert.strictEqual(before.width, '1px', 'border: a thin line');
      assert.strictEqual(before.height, '100px', 'along the whole button');
      assert.strictEqual(before.backgroundColor, rgb(light.border.color), 'border color');
      assert.strictEqual(getComputedStyle(button).marginLeft, '0px', 'before: no overlap of the panel before');
      assert.strictEqual(getComputedStyle(button).marginRight, '-8px');

      state.indicator = 'handle';
      state.scrollbars = 'both';
      await rerender();
      assert.strictEqual(el(this.element, '.euiResizableButton'), button, 'same element');
      await wait();
      before = getComputedStyle(button, '::before');
      assert.strictEqual(before.height, '12px');
      assert.strictEqual(getComputedStyle(button).alignItems, 'flex-start');
      assert.strictEqual(getComputedStyle(button).marginLeft, '0px', 'both: no overlap');
      assert.strictEqual(getComputedStyle(button).marginRight, '0px');

      state.align = 'end';
      state.scrollbars = 'after';
      await rerender();
      assert.strictEqual(getComputedStyle(button).alignItems, 'flex-end');
      assert.strictEqual(getComputedStyle(button).marginLeft, '-8px', 'after: no overlap of the panel after');
      assert.strictEqual(getComputedStyle(button).marginRight, '0px');
    });

    test('panel padding, wrapper padding, scrolling, border, shadow and color', async function (assert) {
      class State {
        @tracked padding: 'none' | 's' | 'm' | 'l' | undefined = undefined;
        @tracked wrapper: 'none' | 's' | 'm' | 'l' | undefined = undefined;
        @tracked scrollable: boolean | undefined = undefined;
        @tracked hasBorder = false;
        @tracked hasShadow = false;
        @tracked color: 'plain' | undefined = undefined;
      }
      const state = new State();

      await render(
        <template>
          <div style="width: 1000px;">
            <EuiResizableContainer style="height: 100px;" as |c|>
              <c.Panel
                @id="a"
                @initialSize={{50}}
                @paddingSize={{state.padding}}
                @wrapperPadding={{state.wrapper}}
                @scrollable={{state.scrollable}}
                @hasBorder={{state.hasBorder}}
                @hasShadow={{state.hasShadow}}
                @color={{state.color}}
                data-content
              >
                <div style="height: 500px;">Tall</div>
              </c.Panel>
              <c.Button />
              <c.Panel @initialSize={{50}} @color="subdued" @borderRadius="m" data-subdued>B</c.Panel>
            </EuiResizableContainer>
          </div>
        </template>
      );
      const wrapper = el(this.element, '#a');
      const content = el(this.element, '[data-content]');

      assert.dom(content).hasClass('euiResizablePanel__content').hasAttribute('data-eui-panel');
      assert.strictEqual(content.parentElement, wrapper, 'attributes go to the content panel');
      let c = getComputedStyle(content);
      assert.strictEqual(c.paddingTop, '16px', 'paddingSize m by default');
      assert.strictEqual(c.overflowY, 'auto', 'scrollable by default');
      assert.strictEqual(c.height, '100px', 'full height');
      assert.strictEqual(c.backgroundColor, TRANSPARENT, 'transparent by default');
      assert.strictEqual(c.borderTopLeftRadius, '0px', 'no radius by default');
      assert.strictEqual(getComputedStyle(content, '::after').borderTopWidth, '0px', 'no border by default');
      assert.strictEqual(c.boxShadow, 'none');
      assert.strictEqual(getComputedStyle(wrapper).paddingTop, '0px', 'no wrapper padding by default');
      assert.true(content.scrollHeight > content.clientHeight, 'the content scrolls');

      for (const [size, px] of [['none', '0px'], ['s', '8px'], ['m', '16px'], ['l', '24px']] as const) {
        state.padding = size;
        state.wrapper = size;
        await rerender();
        assert.strictEqual(getComputedStyle(content).paddingTop, px, `paddingSize ${size}`);
        assert.strictEqual(getComputedStyle(wrapper).paddingTop, px, `wrapperPadding ${size}`);
      }

      state.scrollable = false;
      state.hasBorder = true;
      await rerender();
      c = getComputedStyle(content);
      assert.strictEqual(c.overflowY, 'visible', 'not scrollable');
      assert.strictEqual(getComputedStyle(content, '::after').borderTopWidth, '1px', 'hasBorder');

      state.hasBorder = false;
      state.hasShadow = true;
      state.color = 'plain';
      await rerender();
      assert.notStrictEqual(getComputedStyle(content).boxShadow, 'none', 'hasShadow without border');
      assert.strictEqual(el(this.element, '[data-content]'), content, 'same element');
      assert.strictEqual(el(this.element, '#a'), wrapper);

      const subdued = getComputedStyle(el(this.element, '[data-subdued]'));
      assert.strictEqual(subdued.backgroundColor, rgb(light.colors.backgroundBaseSubdued));
      assert.strictEqual(subdued.borderTopLeftRadius, PANEL_RADIUS);
    });

    test('keyboard resizing, focus styles and resize start/end callbacks', async function (assert) {
      const events: string[] = [];
      const sizes: Record<string, number>[] = [];
      const onStart = (trigger: string) => events.push(`start:${trigger}`);
      const onEnd = () => events.push('end');
      const onChange = (s: Record<string, number>) => sizes.push(s);

      await render(
        <template>
          <div style="width: 1000px;">
            <EuiResizableContainer
              style="height: 100px;"
              @onResizeStart={{onStart}}
              @onResizeEnd={{onEnd}}
              @onPanelWidthChange={{onChange}}
              as |c|
            >
              <c.Panel @id="a" @initialSize={{50}} @minSize="40%">A</c.Panel>
              <c.Button />
              <c.Panel @id="b" @initialSize={{50}}>B</c.Panel>
            </EuiResizableContainer>
          </div>
        </template>
      );
      const button = el(this.element, '.euiResizableButton');
      const a = el(this.element, '#a');

      await focus(button);
      await wait();
      assert.strictEqual(
        getComputedStyle(button).backgroundColor,
        rgba(light.colors.primary, 0.1),
        'focus: a 10% primary background'
      );
      const before = getComputedStyle(button, '::before');
      assert.strictEqual(before.backgroundColor, rgb(light.colors.primary), 'focus: primary line');
      assert.strictEqual(before.height, '100px', 'the handle grows into a full line');
      assert.strictEqual(getComputedStyle(button).gap, '0px');

      const start = raw(a);
      await triggerKeyEvent(button, 'keydown', 'ArrowRight');
      assert.strictEqual(Math.round(raw(a) - start), 10, 'ArrowRight: +10px');
      await triggerEvent(button, 'keydown', { key: 'ArrowRight', repeat: true });
      assert.strictEqual(Math.round(raw(a) - start), 20, 'held key keeps resizing');
      await triggerKeyEvent(button, 'keyup', 'ArrowRight');
      assert.deepEqual(events, ['start:key', 'end'], 'one resize per key press');

      await triggerKeyEvent(button, 'keydown', 'ArrowUp');
      assert.strictEqual(Math.round(raw(a) - start), 20, 'vertical arrows are ignored');
      for (let i = 0; i < 15; i++) await triggerKeyEvent(button, 'keydown', 'ArrowLeft');
      assert.strictEqual(Math.round(box(a).width), 400, 'never below @minSize');
      assert.strictEqual(events.at(-1), 'start:key', 'no keyup yet');
      await blur(button);
      assert.strictEqual(events.at(-1), 'end', 'blur ends a key resize');
      assert.strictEqual(
        events.filter((e) => e === 'end').length,
        events.filter((e) => e.startsWith('start')).length,
        'every start ends'
      );
      assert.true(sizes.length > 0);
      assert.true(Math.abs(sizes.at(-1)!['a']! - 40) < 0.5, 'reported in percent');

      const x = button.getBoundingClientRect().left + 2;
      await triggerEvent(button, 'mousedown', { clientX: x, clientY: 10 });
      await triggerEvent('.euiResizableContainer', 'mousemove', { clientX: x + 40, clientY: 10 });
      await triggerEvent('.euiResizableContainer', 'mouseup');
      assert.deepEqual(events.slice(-2), ['start:pointer', 'end'], 'pointer resize');
    });

    test('collapse buttons: visibility, placement, collapsing and disabled resizers', async function (assert) {
      await render(
        <template>
          <div style="width: 1000px;">
            <EuiResizableContainer style="height: 200px;" as |c|>
              <c.Panel @id="nav" @mode="collapsible" @initialSize={{20}}>Nav</c.Panel>
              <c.Button />
              <c.Panel @id="main" @mode="main" @initialSize={{60}}>Main</c.Panel>
              <c.Button />
              <c.Panel @id="side" @mode={{collapsibleAt "top"}} @initialSize={{20}}>Side</c.Panel>
            </EuiResizableContainer>
          </div>
        </template>
      );
      const nav = el(this.element, '#nav');
      const toggle = el(this.element, '#nav .euiResizableCollapseButton');
      const sideToggle = el(this.element, '#side .euiResizableCollapseButton');
      const [first, second] = Array.from(this.element.querySelectorAll<HTMLElement>('.euiResizableButton'));

      assert.strictEqual(nav.lastElementChild, toggle, 'after the first panel');
      assert.strictEqual(el(this.element, '#side').firstElementChild, sideToggle, 'before the last panel');
      assert.dom(toggle).hasTagName('button').hasAria('label', 'Press to toggle this panel');
      assert.strictEqual(getComputedStyle(toggle).position, 'absolute');
      assert.strictEqual(getComputedStyle(toggle).zIndex, '2');
      assert.strictEqual(box(toggle).width, 1, 'hidden (screen reader only) until its resizer has focus');
      assert.strictEqual(
        getComputedStyle(el(this.element, '#nav .euiResizablePanel__content')).minWidth,
        light.size.l,
        'room for the button'
      );

      await focus(first!);
      const t = getComputedStyle(toggle);
      assert.strictEqual(box(toggle).width, 24, 'shown: an xs icon button');
      assert.strictEqual(t.backgroundColor, rgb(light.colors.emptyShade), 'emptyShade surface');
      assert.notStrictEqual(t.boxShadow, 'none', 'with a shadow');
      assert.strictEqual(t.marginRight, '-12px', 'centered on the edge');
      assert.strictEqual(Math.round(box(toggle).right - box(nav).right), 12);
      assert.strictEqual(t.top, '100px', 'middle');
      assert.strictEqual(t.marginTop, '-12px');
      assert.dom('#nav .euiResizableCollapseButton .euiIcon, #nav .euiResizableCollapseButton svg').exists();

      await focus(second!);
      assert.strictEqual(getComputedStyle(sideToggle).top, '0px', 'position top');
      assert.strictEqual(getComputedStyle(sideToggle).marginTop, light.size.base);
      assert.strictEqual(getComputedStyle(sideToggle).marginLeft, '-12px', 'before: on the left edge');

      await click(toggle);
      assert.dom(nav).hasAttribute('data-collapsed', 'true');
      assert.strictEqual(Math.round(raw(nav)), 24, 'collapsed to 24px (measured in client-rect px)');
      assert.dom(first!).isDisabled();
      assert.strictEqual(getComputedStyle(first!).display, 'none', 'disabled resizers are hidden');
      assert.strictEqual(getComputedStyle(nav).overflow, 'hidden');
      const collapsed = getComputedStyle(toggle);
      assert.strictEqual(collapsed.borderTopLeftRadius, '0px', 'the collapsed panel is all button');
      assert.strictEqual(collapsed.top, '0px');
      assert.strictEqual(collapsed.height, '200px');
      assert.strictEqual(box(toggle).width, 24, 'visible while collapsed');
      assert.strictEqual(
        getComputedStyle(el(this.element, '#nav .euiResizablePanel__content')).paddingTop,
        '0px'
      );

      await click(toggle);
      assert.dom(nav).doesNotHaveAttribute('data-collapsed');
      assert.strictEqual(nav.style.width, '20%');
      assert.dom(first!).isNotDisabled();
    });

    test('vertical collapse button sits on the top/bottom edge', async function (assert) {
      await render(
        <template>
          <div style="width: 600px;">
            <EuiResizableContainer @direction="vertical" style="height: 400px;" as |c|>
              <c.Panel @mode="main" @initialSize={{50}}>Top</c.Panel>
              <c.Button />
              <c.Panel @id="bottom" @mode="collapsible" @initialSize={{50}}>Bottom</c.Panel>
            </EuiResizableContainer>
          </div>
        </template>
      );
      await focus('.euiResizableButton');
      const toggle = el(this.element, '#bottom .euiResizableCollapseButton');
      const t = getComputedStyle(toggle);
      assert.strictEqual(t.bottom, '200px', 'bottom: 100% (before the last panel)');
      assert.strictEqual(t.marginBottom, '-12px');
      assert.strictEqual(t.left, '300px', 'middle: left 50%');
      assert.strictEqual(
        getComputedStyle(el(this.element, '#bottom .euiResizablePanel__content')).minHeight,
        '24px'
      );
    });

    test('nearest provider light/dark, sibling isolation and JS-object overrides', async function (assert) {
      class State {
        @tracked mode: 'light' | 'dark' = 'dark';
      }
      const state = new State();
      const overrides: EuiBorealisOverrides = {
        size: { base: '20px' },
        colors: { LIGHT: { darkestShade: '#123456' }, DARK: { darkestShade: '#abcdef' } }
      };

      await render(
        <template>
          <EuiEmotionProvider @colorMode={{state.mode}}>
            <div style="width: 600px;">
              <EuiResizableContainer style="height: 100px;" data-parent as |c|>
                <c.Panel @initialSize={{50}}>A</c.Panel>
                <c.Button />
                <c.Panel @initialSize={{50}}>B</c.Panel>
              </EuiResizableContainer>
            </div>
            <EuiEmotionProvider @borealisOverrides={{overrides}}>
              <div style="width: 600px;">
                <EuiResizableContainer style="height: 100px;" data-override as |c|>
                  <c.Panel @initialSize={{50}}>A</c.Panel>
                  <c.Button />
                  <c.Panel @initialSize={{50}}>B</c.Panel>
                </EuiResizableContainer>
              </div>
            </EuiEmotionProvider>
          </EuiEmotionProvider>
          <EuiEmotionProvider @colorMode="light">
            <div style="width: 600px;">
              <EuiResizableContainer style="height: 100px;" data-sibling as |c|>
                <c.Panel @initialSize={{50}}>A</c.Panel>
                <c.Button />
                <c.Panel @initialSize={{50}}>B</c.Panel>
              </EuiResizableContainer>
            </div>
          </EuiEmotionProvider>
        </template>
      );
      const handle = (selector: string) =>
        getComputedStyle(el(this.element, `${selector} .euiResizableButton`), '::before').backgroundColor;
      const parentButton = el(this.element, '[data-parent] .euiResizableButton');

      assert.strictEqual(handle('[data-parent]'), rgb(dark.colors.darkestShade), 'dark');
      assert.strictEqual(handle('[data-sibling]'), rgb(light.colors.darkestShade), 'sibling stays light');
      assert.strictEqual(handle('[data-override]'), rgb('#abcdef'), 'nested override in dark');
      assert.strictEqual(
        getComputedStyle(el(this.element, '[data-override] .euiResizableButton')).width,
        '20px',
        'size.base override'
      );
      assert.strictEqual(getComputedStyle(parentButton).width, '16px', 'parent unaffected');

      state.mode = 'light';
      await rerender();
      await wait();
      assert.strictEqual(el(this.element, '[data-parent] .euiResizableButton'), parentButton, 'same element');
      assert.strictEqual(handle('[data-parent]'), rgb(light.colors.darkestShade), 'follows the provider');
      assert.strictEqual(handle('[data-override]'), rgb('#123456'), 'mode-specific override');
    });

    test('RTL: panels and the collapse button follow the inline direction', async function (assert) {
      await render(
        <template>
          <div dir="rtl" style="width: 1000px;">
            <EuiResizableContainer style="height: 100px;" as |c|>
              <c.Panel @id="nav" @mode="collapsible" @initialSize={{30}}>Nav</c.Panel>
              <c.Button />
              <c.Panel @id="main" @mode="main" @initialSize={{70}}>Main</c.Panel>
            </EuiResizableContainer>
          </div>
        </template>
      );
      const nav = el(this.element, '#nav');
      const main = el(this.element, '#main');

      assert.true(box(nav).left > box(main).left, 'the first panel starts on the right');
      await focus('.euiResizableButton');
      const toggle = el(this.element, '#nav .euiResizableCollapseButton');
      assert.strictEqual(
        Math.round(box(nav).left - box(toggle).left),
        12,
        'the toggle straddles the inline-end (left) edge'
      );

      const start = raw(nav);
      await triggerKeyEvent('.euiResizableButton', 'keydown', 'ArrowRight');
      assert.strictEqual(Math.round(raw(nav) - start), 10, 'arrows keep their DOM meaning, as upstream');
    });

    test('high contrast: no content borders; thick focus lines', async function (assert) {
      await render(
        <template>
          <EuiEmotionProvider @highContrastMode="preferred">
            <div style="width: 600px;">
              <EuiResizableContainer style="height: 100px;" data-preferred as |c|>
                <c.Panel @initialSize={{50}} @color="subdued" data-content>A</c.Panel>
                <c.Button />
                <c.Panel @initialSize={{50}}>B</c.Panel>
              </EuiResizableContainer>
            </div>
          </EuiEmotionProvider>
          <EuiEmotionProvider @highContrastMode="forced">
            <div style="width: 600px;">
              <EuiResizableContainer style="height: 100px;" data-forced as |c|>
                <c.Panel @initialSize={{50}}>A</c.Panel>
                <c.Button />
                <c.Panel @initialSize={{50}}>B</c.Panel>
              </EuiResizableContainer>
            </div>
          </EuiEmotionProvider>
        </template>
      );
      const preferred = resolveBorealisTheme('light', {}, 'preferred').euiTheme;
      const forced = resolveBorealisTheme('light', {}, 'forced').euiTheme;

      assert.strictEqual(style(this.element, '[data-content]').borderTopStyle, 'none', 'no panel border');
      const button = el(this.element, '[data-preferred] .euiResizableButton');
      await focus(button);
      await wait();
      assert.strictEqual(getComputedStyle(button).backgroundColor, TRANSPARENT, 'no background on focus');
      assert.strictEqual(getComputedStyle(button, '::before').width, preferred.border.width.thick);
      assert.strictEqual(getComputedStyle(button, '::before').backgroundColor, rgb(preferred.colors.primary));

      const forcedButton = el(this.element, '[data-forced] .euiResizableButton');
      await focus(forcedButton);
      await wait();
      assert.strictEqual(getComputedStyle(forcedButton, '::before').backgroundColor, rgb(forced.border.color));
      assert.strictEqual(getComputedStyle(forcedButton).forcedColorAdjust, 'none', 'preventForcedColors');
    });
  });

  module('EuiDragDropContext / EuiDroppable / EuiDraggable', function () {
    class Lists {
      @tracked a = [
        { id: 'a1', label: 'A1' },
        { id: 'a2', label: 'A2' },
        { id: 'a3', label: 'A3' }
      ];
      @tracked spacing: 'none' | 's' | 'm' | 'l' = 's';
      @tracked grow = false;
      @tracked withPanel = false;
      results: DropResult[] = [];
      onDragEnd = (result: DropResult) => this.results.push(result);
    }

    test('spacing, grow and withPanel; reactive without element replacement', async function (assert) {
      const state = new Lists();

      await render(
        <template>
          <div style="display: flex; width: 600px;">
            <EuiDragDropContext @onDragEnd={{state.onDragEnd}} as |dnd|>
              <dnd.Droppable
                @droppableId="a"
                @spacing={{state.spacing}}
                @grow={{state.grow}}
                @withPanel={{state.withPanel}}
                data-list
                as |list|
              >
                {{#each state.a as |item index|}}
                  <list.Draggable
                    @draggableId={{item.id}}
                    @index={{index}}
                    @spacing={{state.spacing}}
                    data-id={{item.id}}
                  >
                    <div>{{item.label}}</div>
                  </list.Draggable>
                {{/each}}
              </dnd.Droppable>
            </EuiDragDropContext>
          </div>
        </template>
      );
      const list = el(this.element, '[data-list]');
      const item = el(this.element, '[data-id="a1"]');

      assert.dom(list).hasClass('euiDroppable').hasAttribute('data-test-subj', 'droppable');
      assert.dom(item).hasClass('euiDraggable').hasAttribute('data-test-subj', 'draggable');
      assert.strictEqual(getComputedStyle(list).flexGrow, '0', 'grow false by default');
      assert.true(box(list).width < 600, 'content width');
      assert.strictEqual(getComputedStyle(list).backgroundColor, TRANSPARENT);

      for (const [size, px] of [['none', '0px'], ['s', '2px'], ['m', '4px'], ['l', '8px']] as const) {
        state.spacing = size;
        await rerender();
        assert.strictEqual(getComputedStyle(list).paddingTop, px, `droppable ${size}`);
        assert.strictEqual(getComputedStyle(item).paddingTop, px, `draggable ${size}`);
      }
      assert.strictEqual(el(this.element, '[data-list]'), list, 'same list element');
      assert.strictEqual(el(this.element, '[data-id="a1"]'), item, 'same item element');

      state.grow = true;
      await rerender();
      assert.strictEqual(getComputedStyle(list).flexGrow, '1');
      assert.strictEqual(box(list).width, 600, 'grows to fill');

      state.withPanel = true;
      await rerender();
      const panel = el(this.element, '[data-list]');
      const p = getComputedStyle(panel);
      assert.dom(panel).hasAttribute('data-eui-panel').hasClass('euiDroppable');
      assert.strictEqual(p.backgroundColor, rgb(light.colors.backgroundBasePlain), 'plain panel');
      assert.notStrictEqual(p.boxShadow, 'none', 'with a shadow');
      assert.strictEqual(getComputedStyle(panel, '::after').borderTopWidth, '0px', 'and no border');
      assert.strictEqual(p.paddingTop, '8px', 'spacing beats the panel padding');
      assert.strictEqual(p.flexGrow, '1');
      assert.strictEqual(p.borderTopLeftRadius, PANEL_RADIUS);
      assert.dom('[data-list] > .euiDraggable').exists({ count: 3 }, 'items inside the panel');
    });

    test('dragging and dropping state styles during a keyboard drag', async function (assert) {
      const state = new Lists();

      await render(
        <template>
          <EuiDragDropContext @onDragEnd={{state.onDragEnd}} as |dnd|>
            <dnd.Droppable @droppableId="a" data-list-a as |list|>
              {{#each state.a key="id" as |item index|}}
                <list.Draggable @draggableId={{item.id}} @index={{index}} data-id={{item.id}}>
                  <div style="height: 30px;">{{item.label}}</div>
                </list.Draggable>
              {{/each}}
            </dnd.Droppable>
            <dnd.Droppable @droppableId="b" data-list-b as |list|>
              <list.Draggable @draggableId="b1" @index={{0}} @isDragDisabled={{true}} data-id="b1">
                <div>B1</div>
              </list.Draggable>
            </dnd.Droppable>
            <dnd.Droppable @droppableId="c" @type="OTHER" data-list-c as |list|>
              <list.Draggable @draggableId="c1" @index={{0}}><div>C1</div></list.Draggable>
            </dnd.Droppable>
            <dnd.Droppable @droppableId="d" @isDropDisabled={{true}} data-list-d as |list|>
              <list.Draggable @draggableId="d1" @index={{0}} @isRemovable={{true}} data-id="d1">
                <div>D1</div>
              </list.Draggable>
            </dnd.Droppable>
          </EuiDragDropContext>
        </template>
      );
      const bg = (selector: string) => style(this.element, selector).backgroundColor;
      const item = el(this.element, '[data-id="a1"]');

      assert.dom('[data-list-d]').hasClass('euiDroppable-isDisabled');
      assert.dom('[data-list-a]').doesNotHaveClass('euiDroppable-isDisabled');
      assert.strictEqual(style(this.element, '[data-list-a]').transitionProperty, 'background-color');
      assert.strictEqual(style(this.element, '[data-list-a]').transitionDuration, '0.35s', 'animation.slow');
      assert.strictEqual(getComputedStyle(item.firstElementChild!).boxShadow, 'none');
      assert.strictEqual(style(this.element, '[data-id="d1"]').transitionDuration, '0.001s', 'isRemovable');
      assert.dom('[data-id="b1"] .euiDraggable__item').hasClass('euiDraggable__item-isDisabled');
      assert.strictEqual(style(this.element, '[data-id="b1"] .euiDraggable__item').cursor, 'not-allowed');

      await triggerKeyEvent(item, 'keydown', ' ');
      await wait(500);
      assert.dom(item).hasAria('pressed', 'true');
      assert.strictEqual(bg('[data-list-a]'), rgb(light.components.dragDropDraggingOverBackground), 'over');
      assert.strictEqual(bg('[data-list-b]'), rgb(light.components.dragDropDraggingBackground), 'same type');
      assert.strictEqual(bg('[data-list-c]'), TRANSPARENT, 'other type');
      assert.strictEqual(bg('[data-list-d]'), TRANSPARENT, 'drop disabled');
      assert.strictEqual(getComputedStyle(item).zIndex, String(light.levels.toast), 'lifted above');
      assert.notStrictEqual(getComputedStyle(item.firstElementChild!).boxShadow, 'none', 'shadow m');

      await triggerKeyEvent(item, 'keydown', 'ArrowDown');
      await triggerKeyEvent(item, 'keydown', 'Escape');
      await wait(500);
      assert.dom(item).hasAria('pressed', 'false');
      assert.strictEqual(bg('[data-list-a]'), TRANSPARENT, 'states cleared');
      assert.strictEqual(bg('[data-list-b]'), TRANSPARENT);
      assert.strictEqual(state.results.at(-1)!.reason, 'CANCEL');
    });

    test('focus, roles, interactive children and fully custom handles', async function (assert) {
      const state = new Lists();

      await render(
        <template>
          <EuiDragDropContext @onDragEnd={{state.onDragEnd}} as |dnd|>
            <dnd.Droppable @droppableId="a" as |list|>
              <list.Draggable @draggableId="plain" @index={{0}} data-id="plain">
                <div>Plain</div>
              </list.Draggable>
              <list.Draggable
                @draggableId="group"
                @index={{1}}
                @hasInteractiveChildren={{true}}
                @customDragHandle={{true}}
                data-id="group"
                as |d|
              >
                <div><span {{d.dragHandle}} tabindex="0" data-handle>Grab</span><input data-input /></div>
              </list.Draggable>
              <list.Draggable
                @draggableId="custom"
                @index={{2}}
                @customDragHandle="custom"
                data-id="custom"
                as |d|
              >
                <div><span {{d.dragHandle}} data-custom-handle>Grab</span></div>
              </list.Draggable>
            </dnd.Droppable>
          </EuiDragDropContext>
        </template>
      );
      assert
        .dom('[data-id="plain"]')
        .hasAttribute('role', 'button')
        .hasAttribute('tabindex', '0')
        .hasAria('pressed', 'false')
        .hasAria('roledescription', 'Draggable item');
      await focus('[data-id="plain"]');
      assert.strictEqual(style(this.element, '[data-id="plain"]').outlineStyle, 'none', 'no outline on the wrapper');
      assert.notStrictEqual(
        style(this.element, '[data-id="plain"] > .euiDraggable__item').outlineStyle,
        'none',
        'the item shows the focus'
      );

      assert
        .dom('[data-id="group"]')
        .hasAttribute('role', 'group')
        .doesNotHaveAttribute('tabindex')
        .doesNotHaveAria('pressed');
      await triggerKeyEvent('[data-input]', 'keydown', ' ');
      assert.dom('[data-id="group"]').doesNotHaveAria('pressed');
      assert.strictEqual(state.results.length, 0);
      assert.dom('.euiDraggable[aria-pressed="true"]').doesNotExist('typing in a control does not lift the item');
      await triggerKeyEvent('[data-handle]', 'keydown', ' ');
      await triggerKeyEvent('[data-handle]', 'keydown', 'Escape');
      assert.strictEqual(state.results.at(-1)?.draggableId, 'group', 'the handle lifts it');

      assert
        .dom('[data-id="custom"]')
        .doesNotHaveAttribute('role')
        .doesNotHaveAttribute('tabindex')
        .doesNotHaveAria('pressed');
      assert.dom('[data-custom-handle]').hasAttribute('role', 'button').hasAttribute('tabindex', '0');
      await triggerKeyEvent('[data-custom-handle]', 'keydown', ' ');
      await triggerKeyEvent('[data-custom-handle]', 'keydown', ' ');
      assert.strictEqual(state.results.at(-1)?.draggableId, 'custom');
      assert.strictEqual(state.results.at(-1)?.reason, 'DROP');
    });

    test('dark provider, sibling isolation and JS-object overrides', async function (assert) {
      const state = new Lists();
      const overrides: EuiBorealisOverrides = { size: { xs: '6px' } };

      await render(
        <template>
          <EuiEmotionProvider @colorMode="dark">
            <EuiDragDropContext @onDragEnd={{state.onDragEnd}} as |dnd|>
              <dnd.Droppable @droppableId="a" data-dark as |list|>
                <list.Draggable @draggableId="x" @index={{0}} data-id="x"><div>X</div></list.Draggable>
              </dnd.Droppable>
            </EuiDragDropContext>
            <EuiEmotionProvider @borealisOverrides={{overrides}}>
              <EuiDragDropContext @onDragEnd={{state.onDragEnd}} as |dnd|>
                <dnd.Droppable @droppableId="o" @spacing="m" data-override as |list|>
                  <list.Draggable @draggableId="o1" @index={{0}} @spacing="m"><div>O</div></list.Draggable>
                </dnd.Droppable>
              </EuiDragDropContext>
            </EuiEmotionProvider>
          </EuiEmotionProvider>
          <EuiEmotionProvider @colorMode="light">
            <EuiDragDropContext @onDragEnd={{state.onDragEnd}} as |dnd|>
              <dnd.Droppable @droppableId="s" data-sibling as |list|>
                <list.Draggable @draggableId="s1" @index={{0}} data-id="s1"><div>S</div></list.Draggable>
              </dnd.Droppable>
            </EuiDragDropContext>
          </EuiEmotionProvider>
        </template>
      );
      await triggerKeyEvent('[data-id="x"]', 'keydown', ' ');
      await triggerKeyEvent('[data-id="s1"]', 'keydown', ' ');
      await wait(500);
      assert.strictEqual(
        style(this.element, '[data-dark]').backgroundColor,
        rgb(dark.components.dragDropDraggingOverBackground),
        'dark tokens'
      );
      assert.strictEqual(
        style(this.element, '[data-sibling]').backgroundColor,
        rgb(light.components.dragDropDraggingOverBackground),
        'sibling stays light'
      );
      assert.strictEqual(style(this.element, '[data-override]').paddingTop, '6px', 'size.xs override');
      assert.strictEqual(style(this.element, '[data-override] .euiDraggable').paddingTop, '6px');
    });
  });
});

function collapsibleAt(
  position: 'top' | 'middle' | 'bottom' | 'left' | 'right'
): ['collapsible', { position: typeof position }] {
  return ['collapsible', { position }];
}
