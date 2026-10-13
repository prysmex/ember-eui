import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { click, focus, render, settled } from '@ember/test-helpers';
import { setupRenderingTest } from 'ember-qunit';
import { module, test } from 'qunit';

import EuiDescriptionList from '#src/components/eui-description-list.gts';
import EuiDescriptionListDescription from '#src/components/eui-description-list-description.gts';
import EuiDescriptionListTitle from '#src/components/eui-description-list-title.gts';
import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import EuiIcon from '#src/components/eui-icon.gts';
import EuiKeyPadMenu from '#src/components/eui-key-pad-menu.gts';
import EuiKeyPadMenuItem from '#src/components/eui-key-pad-menu-item.gts';
import EuiListGroup from '#src/components/eui-list-group.gts';
import EuiListGroupItem from '#src/components/eui-list-group-item.gts';
import EuiPinnableListGroup from '#src/components/eui-pinnable-list-group.gts';
import EuiSideNav from '#src/components/eui-side-nav.gts';
import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';

import type { EuiPinnableListGroupItem } from '#src/components/eui-pinnable-list-group.gts';
import type { Item } from '#src/components/eui-side-nav.gts';
import type {
  EuiBorealisHighContrastMode,
  EuiBorealisOverrides
} from '#src/utils/eui/theme.ts';

const light = resolveBorealisTheme('light').euiTheme;
const dark = resolveBorealisTheme('dark').euiTheme;
const TRANSPARENT = 'rgba(0, 0, 0, 0)';
const noop = () => {};
/** No mobile breakpoints: the desktop side nav always renders. */
const array: never[] = [];

function el(root: Element | Document, selector: string) {
  const element = root.querySelector<HTMLElement>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

function style(root: Element, selector: string, pseudo?: string) {
  return getComputedStyle(el(root, selector), pseudo);
}

/** Normalize any CSS color to the browser's computed `rgb()` form. */
function rgb(color: string) {
  const probe = document.createElement('span');
  probe.style.color = color;
  document.body.appendChild(probe);
  const value = getComputedStyle(probe).color;
  probe.remove();
  return value;
}

/** Upstream font sizes are rem based; EUI apps set a 14px root (`s`). */
function remPx(px: number) {
  return (px / 14) * parseFloat(getComputedStyle(document.documentElement).fontSize);
}

function close(assert: Assert, actual: number, expected: number, label: string) {
  assert.true(Math.abs(actual - expected) < 0.5, `${label}: ${actual} ≈ ${expected}`);
}

function finishTransitions() {
  document.getAnimations().forEach((animation) => animation.finish());
}

/**
 * Renders a copy of the given markup (with every inserted rule) into an
 * iframe of the given width, so media queries are evaluated against a real
 * narrow viewport (see eui-flex-family-test).
 */
function inViewport(width: number, html: string) {
  const iframe = document.createElement('iframe');
  iframe.style.cssText = `position:fixed;top:0;left:0;width:${width}px;height:800px;border:0;visibility:hidden`;
  document.body.appendChild(iframe);
  const css = Array.from(document.styleSheets)
    .map((sheet) => {
      try {
        return Array.from(sheet.cssRules)
          .map((rule) => rule.cssText)
          .join('\n');
      } catch {
        return '';
      }
    })
    .join('\n');
  const doc = iframe.contentDocument!;
  doc.open();
  doc.write(
    `<!doctype html><html><head><style>${css}</style></head><body style="margin:0">${html}</body></html>`
  );
  doc.close();
  const win = iframe.contentWindow!;
  return {
    style: (selector: string) => win.getComputedStyle(el(doc, selector)),
    remove: () => iframe.remove()
  };
}

const PIN_ITEMS: EuiPinnableListGroupItem[] = [
  { label: 'Discover', href: '#discover', pinned: true },
  { label: 'Dashboards', href: '#dashboards' },
  { label: 'Settings', href: '#settings', pinnable: false },
  {
    label: 'Own action',
    href: '#own',
    extraAction: { iconType: 'gear', 'aria-label': 'Configure', alwaysShow: true }
  }
];

const DL_ITEMS = [
  { title: 'Name', description: 'Jane' },
  { title: 'Role', description: 'Admin' }
];

function sideNavItems(onClick = noop): Item[] {
  return [
    {
      id: 'root',
      name: 'Root',
      icon: 'logoElasticsearch',
      items: [
        { id: 'trunk-a', name: 'Trunk A', onClick },
        {
          id: 'section',
          name: 'Section',
          items: [
            { id: 'branch-a', name: 'Branch A', onClick },
            { id: 'branch-b', name: 'Branch B', href: '#b', target: '_blank' }
          ]
        },
        { id: 'emph', name: 'Emphasized', onClick, emphasize: true },
        { id: 'off', name: 'Disabled', onClick, disabled: true },
        {
          id: 'long',
          name: 'A very long item name that should be truncated in the side nav',
          onClick
        },
        { id: 'wrap', name: 'Wrapped', onClick, truncate: false }
      ]
    },
    { id: 'plain', name: 'Plain root' }
  ];
}

module('Integration | Component | Borealis lists, key pad and side nav', function (hooks) {
  setupRenderingTest(hooks);

  test('EuiListGroup: reset flex column, border and max width from the upstream factory', async function (assert) {
    class State {
      @tracked bordered = false;
      @tracked maxWidth: boolean | string | number | undefined = undefined;
    }
    const state = new State();
    await render(
      <template>
        <div style="width: 900px">
          <EuiListGroup @bordered={{state.bordered}} @maxWidth={{state.maxWidth}} data-test="group">
            <EuiListGroupItem @label="One" />
          </EuiListGroup>
          <EuiListGroup @maxWidth={{false}} @flush={{true}} @gutterSize="m" data-test="none">
            <EuiListGroupItem @label="One" />
          </EuiListGroup>
        </div>
      </template>
    );
    const root = this.element;
    const ul = el(root, '[data-test="group"]');
    let s = style(root, '[data-test="group"]');
    assert.strictEqual(ul.tagName, 'UL');
    assert.strictEqual(s.display, 'flex');
    assert.strictEqual(s.flexDirection, 'column');
    assert.strictEqual(s.listStyleType, 'none');
    assert.strictEqual(s.paddingLeft, '0px');
    assert.strictEqual(s.marginTop, '0px');
    assert.strictEqual(s.maxWidth, '400px', 'default max width is the 400px form width');
    assert.strictEqual(s.borderTopStyle, 'none');
    assert.strictEqual(style(root, '[data-test="none"]').maxWidth, 'none', '@maxWidth={{false}}');
    assert.strictEqual(style(root, '[data-test="none"]').paddingTop, '0px', 'flush/gutter are no-ops');

    state.bordered = true;
    state.maxWidth = '250px';
    await settled();
    s = style(root, '[data-test="group"]');
    assert.strictEqual(el(root, '[data-test="group"]'), ul, 'element kept');
    assert.strictEqual(s.borderTopWidth, '1px');
    assert.strictEqual(s.borderTopStyle, 'solid');
    assert.strictEqual(s.borderTopColor, rgb(light.border.color));
    assert.strictEqual(s.borderTopLeftRadius, light.border.radius.panel);
    assert.strictEqual(s.maxWidth, '250px');

    state.maxWidth = 300;
    await settled();
    assert.strictEqual(style(root, '[data-test="group"]').maxWidth, '300px', 'numbers are pixels');
  });

  test('EuiListGroupItem: li/a/button semantics, aria-current, disabled and clicks', async function (assert) {
    let clicks = 0;
    const onClick = () => clicks++;
    await render(
      <template>
        <EuiListGroup>
          <EuiListGroupItem @label="Text" data-test="text" />
          <EuiListGroupItem @label="Active text" @isActive={{true}} data-test="text-active" />
          <EuiListGroupItem @label="Disabled text" @isDisabled={{true}} data-test="text-disabled" />
          <EuiListGroupItem @label="Link" @href="#link" @onClick={{onClick}} data-test="link" />
          <EuiListGroupItem @label="Active link" @href="#active" @isActive={{true}} data-test="link-active" />
          <EuiListGroupItem @label="Button" @onClick={{onClick}} data-test="button" />
          <EuiListGroupItem @label="Disabled link" @href="#off" @isDisabled={{true}} @onClick={{onClick}} data-test="link-disabled" />
          {{! template-lint-disable no-invalid-link-text }}
          <EuiListGroupItem @label="JS" @href="javascript:alert(1)" data-test="js" />
          <EuiListGroupItem @iconType="bell" data-test="block">
            <strong>Block</strong>
          </EuiListGroupItem>
        </EuiListGroup>
      </template>
    );
    const root = this.element;

    const text = el(root, '[data-test="text"]');
    assert.strictEqual(text.tagName, 'LI', 'text items are the li itself');
    assert.strictEqual(text.parentElement!.tagName, 'UL');
    assert.true(text.classList.contains('euiListGroupItem'));
    assert.true(text.classList.contains('euiListGroupItem__text'));
    assert.dom(text).doesNotHaveAttribute('aria-current');
    assert.dom('[data-test="text-active"]').hasAttribute('aria-current', 'true');
    assert.dom('[data-test="text-disabled"]').hasAttribute('aria-disabled', 'true');

    const link = el(root, '[data-test="link"]');
    assert.strictEqual(link.tagName, 'A');
    assert.true(link.classList.contains('euiListGroupItem__button'));
    assert.strictEqual(link.parentElement!.tagName, 'LI', 'links sit in a wrapper li');
    assert.true(link.parentElement!.classList.contains('euiListItemLayout__wrapper'));
    assert.dom(link).hasAttribute('href', '#link').hasAttribute('rel', 'noreferrer').doesNotHaveAttribute('aria-current');
    assert.dom('[data-test="link-active"]').hasAttribute('aria-current', 'true');

    const button = el(root, '[data-test="button"]');
    assert.strictEqual(button.tagName, 'BUTTON');
    assert.dom(button).hasAttribute('type', 'button').isNotDisabled();
    assert.strictEqual(button.parentElement!.tagName, 'LI');

    assert.dom('[data-test="link-disabled"]').hasTagName('button').isDisabled().doesNotHaveAttribute('href');
    assert.dom('[data-test="js"]').hasTagName('button').isDisabled();

    assert.dom('[data-test="block"] strong').hasText('Block');
    assert.dom('[data-test="block"] .euiListItemLayout__prepend .euiListGroupItem__icon').exists();
    assert.dom('[data-test="text"] .euiListGroupItem__label').hasText('Text').hasAttribute('title', 'Text');
    assert.strictEqual(root.querySelectorAll('li li').length, 0, 'no nested list items');

    link.addEventListener('click', (event) => event.preventDefault());
    await click(link);
    await click(button);
    el(root, '[data-test="link-disabled"]').click();
    assert.strictEqual(clicks, 2, 'link and button fire, disabled does not');

    await focus(button);
    assert.strictEqual(document.activeElement, button, 'buttons are focusable');
  });

  test('EuiListGroupItem: measured layout, colors, active and disabled states', async function (assert) {
    await render(
      <template>
        <EuiEmotionProvider>
          <EuiListGroup @color="primary" data-test="group">
            <EuiListGroupItem @label="Inherited" data-test="inherited" />
            <EuiListGroupItem @label="Text" @color="text" data-test="text" />
            <EuiListGroupItem @label="Subdued" @color="subdued" data-test="subdued" />
            <EuiListGroupItem @label="Ghost" @color="ghost" data-test="ghost" />
            <EuiListGroupItem @label="Active" @href="#a" @isActive={{true}} data-test="active" />
            <EuiListGroupItem @label="Disabled" @onClick={{noop}} @isDisabled={{true}} data-test="disabled" />
            <EuiListGroupItem @label="Link" @href="#l" data-test="link" />
          </EuiListGroup>
          <div style="color: rgb(1, 2, 3)">
            <EuiListGroup>
              <EuiListGroupItem @label="Inherit" @color="inherit" data-test="inherit" />
            </EuiListGroup>
          </div>
        </EuiEmotionProvider>
      </template>
    );
    const root = this.element;
    const itemStyle = (name: string) => style(root, `[data-test="${name}"]`);
    const wrapperStyle = (name: string) => getComputedStyle(el(root, `[data-test="${name}"]`).parentElement!);

    assert.strictEqual(itemStyle('inherited').color, rgb(light.colors.textPrimary), 'group @color reaches block items');
    assert.strictEqual(itemStyle('text').color, rgb(light.colors.textParagraph), 'item @color wins');
    assert.strictEqual(itemStyle('subdued').color, rgb(light.colors.textSubdued));
    assert.strictEqual(itemStyle('ghost').color, rgb(light.colors.textParagraph), 'ghost renders as text');
    assert.strictEqual(itemStyle('inherit').color, 'rgb(1, 2, 3)');

    const text = itemStyle('text');
    assert.strictEqual(text.display, 'flex');
    assert.strictEqual(text.paddingLeft, light.size.s);
    assert.strictEqual(text.paddingRight, light.size.s);
    assert.strictEqual(text.borderTopLeftRadius, light.border.radius.control);
    close(assert, parseFloat(text.fontSize), remPx(14), 'font size s');
    assert.strictEqual(text.cursor, 'auto', 'text items are not interactive');
    const label = style(root, '[data-test="text"] .euiListGroupItem__label');
    assert.strictEqual(label.paddingTop, '6px', 'text padding is xs + xxs');
    assert.strictEqual(label.whiteSpace, 'nowrap');
    assert.strictEqual(label.textOverflow, 'ellipsis');

    // Links: the wrapper li owns color, hover/selected backgrounds; the anchor inherits.
    assert.strictEqual(wrapperStyle('link').color, rgb(light.colors.textPrimary));
    assert.strictEqual(itemStyle('link').color, rgb(light.colors.textPrimary));
    assert.strictEqual(wrapperStyle('link').cursor, 'pointer');
    assert.strictEqual(itemStyle('link').textDecorationLine, 'none');
    assert.strictEqual(wrapperStyle('link').listStyleType, 'none');

    assert.strictEqual(wrapperStyle('active').color, rgb(light.colors.textPrimary), 'active color');
    assert.strictEqual(wrapperStyle('active').backgroundColor, rgb(light.colors.backgroundBaseInteractiveSelect));
    assert.strictEqual(wrapperStyle('link').backgroundColor, TRANSPARENT);

    assert.strictEqual(wrapperStyle('disabled').color, rgb(light.colors.textDisabled));
    assert.strictEqual(itemStyle('disabled').color, rgb(light.colors.textDisabled));
    assert.strictEqual(itemStyle('disabled').cursor, 'not-allowed');
    assert.strictEqual(wrapperStyle('disabled').backgroundColor, TRANSPARENT);
    const height = el(root, '[data-test="text"]').getBoundingClientRect().height;
    assert.true(height > 0 && el(root, '[data-test="link"]').getBoundingClientRect().height === height, 'text and link items share the upstream height');
  });

  test('EuiListGroupItem: wrapText, reactive args keep the element', async function (assert) {
    class State {
      @tracked color = 'text';
      @tracked active = false;
      @tracked wrap = false;
    }
    const state = new State();
    await render(
      <template>
        <EuiListGroup @maxWidth="120px">
          <EuiListGroupItem
            @label="A long label that will not fit in the list width"
            @href="#x"
            @wrapText={{state.wrap}}
            @color={{state.color}}
            @isActive={{state.active}}
            data-test="item"
          />
        </EuiListGroup>
      </template>
    );
    const root = this.element;
    const item = el(root, '[data-test="item"]');
    const wrapper = item.parentElement!;
    assert.dom('[data-test="item"] .euiListGroupItem__label').hasAttribute('title', 'A long label that will not fit in the list width');
    const truncatedHeight = item.getBoundingClientRect().height;

    state.color = 'subdued';
    await settled();
    assert.strictEqual(getComputedStyle(wrapper).color, rgb(light.colors.textSubdued));
    state.active = true;
    await settled();
    assert.strictEqual(getComputedStyle(wrapper).color, rgb(light.colors.textPrimary));
    assert.dom(item).hasAttribute('aria-current', 'true');
    state.wrap = true;
    await settled();
    assert.strictEqual(style(root, '[data-test="item"] .euiListGroupItem__label').whiteSpace, 'normal');
    assert.dom('[data-test="item"] .euiListGroupItem__label').doesNotHaveAttribute('title');
    assert.true(item.getBoundingClientRect().height > truncatedHeight, 'wrapped text grows the item');
    assert.strictEqual(el(root, '[data-test="item"]'), item, 'element kept');
    assert.strictEqual(item.parentElement, wrapper, 'wrapper kept');
  });

  test('EuiListGroupItem: extra actions and external links', async function (assert) {
    let actions = 0;
    const favorite = { iconType: 'starEmpty', 'aria-label': 'Favorite', onClick: () => actions++ };
    const always = { iconType: 'starFilled', 'aria-label': 'Unfavorite', alwaysShow: true };
    const Custom = <template><button type="button" class="custom-action">Custom</button></template>;
    await render(
      <template>
        <EuiListGroup>
          <EuiListGroupItem @label="Hover" @href="#h" @extraAction={{favorite}} data-test="hover" />
          <EuiListGroupItem @label="Always" @onClick={{noop}} @extraAction={{always}} data-test="always" />
          <EuiListGroupItem @label="Text" @extraAction={{favorite}} data-test="text" />
          <EuiListGroupItem @label="Off" @href="#o" @isDisabled={{true}} @extraAction={{favorite}} data-test="off" />
          <EuiListGroupItem @label="Custom" @href="#c" @extraAction={{Custom}} data-test="custom" />
          <EuiListGroupItem @label="External" @href="https://elastic.co" @target="_blank" data-test="external" />
          <EuiListGroupItem @label="Ext" @href="/x" @external={{true}} data-test="ext" />
        </EuiListGroup>
      </template>
    );
    finishTransitions();
    const root = this.element;
    const wrapper = el(root, '[data-test="hover"]').parentElement!;
    const hoverAction = wrapper.querySelector<HTMLButtonElement>('.euiListGroupItemExtraAction')!;
    assert.strictEqual(hoverAction.tagName, 'BUTTON');
    assert.strictEqual(hoverAction.previousElementSibling, el(root, '[data-test="hover"]'), 'action is a sibling of the link');
    assert.dom(hoverAction).hasAria('label', 'Favorite').isNotDisabled();
    assert.strictEqual(getComputedStyle(hoverAction).opacity, '0', 'hidden until hover/focus');
    assert.strictEqual(getComputedStyle(hoverAction).flexShrink, '0');
    assert.strictEqual(getComputedStyle(wrapper).paddingRight, light.size.s, 'wrapper pads the action');
    await focus(hoverAction);
    finishTransitions();
    assert.strictEqual(getComputedStyle(hoverAction).opacity, '1', 'focus shows the action');
    await click(hoverAction);
    assert.strictEqual(actions, 1);

    assert.strictEqual(style(root, '[data-test="always"] + .euiListGroupItemExtraAction').opacity, '1', 'alwaysShow');
    assert.dom('[data-test="text"] .euiListItemLayout__content .euiListGroupItemExtraAction').exists('text items keep the action inside');
    assert.dom(el(root, '[data-test="off"]').parentElement!.querySelector('.euiListGroupItemExtraAction')!).isDisabled('a disabled item disables its action');
    assert.dom('[data-test="custom"] + .custom-action').exists('component extra actions render as-is');

    assert.dom('[data-test="external"]').hasAttribute('rel', 'noopener noreferrer').hasAttribute('target', '_blank');
    assert.dom('[data-test="external"] .euiListGroupItem__externalIcon').hasAttribute('role', 'presentation');
    assert.strictEqual(style(root, '[data-test="external"] .euiListGroupItem__externalIcon').color, rgb(light.colors.textDisabled));
    assert.dom('[data-test="external"] .euiListGroupItem__screenReaderOnly').hasText('(external, opens in a new tab or window)');
    assert.strictEqual(style(root, '[data-test="external"] .euiListGroupItem__screenReaderOnly').position, 'absolute');
    assert.dom('[data-test="ext"] .euiListGroupItem__screenReaderOnly').hasText('(external)');
    assert.dom('[data-test="hover"] .euiListGroupItem__externalIcon').doesNotExist();
  });

  test('EuiPinnableListGroup: pins, own actions, pinned color and rotation', async function (assert) {
    const pinned: string[] = [];
    const onPinClick = (item: EuiPinnableListGroupItem) => pinned.push(item.label);
    await render(
      <template>
        <EuiPinnableListGroup @listItems={{PIN_ITEMS}} @onPinClick={{onPinClick}} data-test="pins" />
      </template>
    );
    finishTransitions();
    const root = this.element;
    const items = [...root.querySelectorAll<HTMLElement>('.euiPinnableListGroup__item')];
    assert.strictEqual(items.length, 4);
    const pinOf = (i: number) => items[i]!.parentElement!.querySelector<HTMLElement>('.euiPinnableListGroup__itemExtraAction');
    assert.ok(pinOf(0) && pinOf(1), 'pinnable items get pins');
    assert.strictEqual(pinOf(2), null, 'pinnable: false');
    assert.strictEqual(pinOf(3), null, 'an own extraAction replaces the pin');
    assert.dom(items[3]!.parentElement!.querySelector('.euiListGroupItemExtraAction')!).hasAria('label', 'Configure');

    assert.dom(pinOf(0)!).hasAria('label', 'Unpin item').hasAttribute('title', 'Unpin item');
    assert.strictEqual(getComputedStyle(pinOf(0)!).opacity, '1', 'pinned pins always show');
    assert.strictEqual(getComputedStyle(pinOf(1)!).opacity, '0');
    assert.notStrictEqual(getComputedStyle(pinOf(0)!).color, getComputedStyle(pinOf(1)!).color, 'pinned pins use the light-shade contrast color');
    const svg = pinOf(1)!.querySelector('svg');
    if (svg) assert.notStrictEqual(getComputedStyle(svg).transform, 'none', 'pin icon rotated 45deg');
    assert.strictEqual(style(root, '[data-test="pins"]').maxWidth, '400px');

    await click(pinOf(1)!);
    assert.deepEqual(pinned, ['Dashboards']);
  });

  test('EuiKeyPadMenu/Item: measured grid, button/link semantics and states', async function (assert) {
    class State {
      @tracked selected: boolean | undefined = undefined;
    }
    const state = new State();
    let clicks = 0;
    const onClick = () => clicks++;
    await render(
      <template>
        <EuiEmotionProvider>
          <EuiKeyPadMenu data-test="menu" as |Key|>
            <Key>
              <EuiKeyPadMenuItem @label="Button" @isSelected={{state.selected}} data-test="button" {{on "click" onClick}}>
                <EuiIcon @type="dashboardApp" @size="l" />
              </EuiKeyPadMenuItem>
            </Key>
            <Key>
              <EuiKeyPadMenuItem @label="Link" @href="#docs" @isSelected={{true}} @betaBadgeLabel="Beta" data-test="link" />
            </Key>
            <Key><EuiKeyPadMenuItem @label="Off" @isDisabled={{true}} data-test="off" /></Key>
            <Key><EuiKeyPadMenuItem @label="Off selected" @isDisabled={{true}} @isSelected={{true}} data-test="off-selected" /></Key>
          </EuiKeyPadMenu>
        </EuiEmotionProvider>
      </template>
    );
    const root = this.element;
    const menu = style(root, '[data-test="menu"]');
    const keySize = parseFloat(light.size.base) * 6;
    assert.dom('[data-test="menu"]').hasTagName('ul');
    assert.strictEqual(menu.display, 'flex');
    assert.strictEqual(menu.flexWrap, 'wrap');
    assert.strictEqual(menu.columnGap, light.size.xs);
    assert.strictEqual(menu.width, `${keySize * 3 + 4 * 3}px`, 'three keys and gaps wide');
    assert.strictEqual(menu.listStyleType, 'none');
    assert.strictEqual(menu.paddingLeft, '0px');

    const button = el(root, '[data-test="button"]');
    const b = getComputedStyle(button);
    assert.strictEqual(b.width, `${keySize}px`);
    assert.strictEqual(b.height, `${keySize}px`);
    assert.strictEqual(b.paddingTop, light.size.xs);
    assert.strictEqual(b.borderTopLeftRadius, light.border.radius.control);
    assert.strictEqual(b.color, rgb(light.colors.textParagraph));
    assert.strictEqual(b.backgroundColor, TRANSPARENT);
    assert.strictEqual(b.borderTopStyle, 'none');
    assert.dom(button).hasAttribute('type', 'button').doesNotHaveAttribute('aria-pressed');
    const labelStyle = style(root, '[data-test="button"] .euiKeyPadMenuItem__label');
    close(assert, parseFloat(labelStyle.fontSize), remPx(12), 'label xs');
    assert.strictEqual(labelStyle.fontWeight, String(light.font.weight.semiBold));
    assert.strictEqual(labelStyle.textAlign, 'center');
    assert.strictEqual(style(root, '[data-test="button"] .euiKeyPadMenuItem__inner').flexDirection, 'column');
    assert.dom('[data-test="button"] .euiKeyPadMenuItem__icon svg').exists();

    state.selected = false;
    await settled();
    assert.dom(button).hasAttribute('aria-pressed', 'false');
    state.selected = true;
    await settled();
    assert.strictEqual(el(root, '[data-test="button"]'), button, 'element kept');
    assert.dom(button).hasAttribute('aria-pressed', 'true');
    void getComputedStyle(button).backgroundColor; // start the background transition
    finishTransitions();
    assert.strictEqual(getComputedStyle(button).color, rgb(light.colors.textPrimary));
    assert.strictEqual(getComputedStyle(button).backgroundColor, rgb(light.colors.backgroundBaseInteractiveSelect));
    await click(button);
    assert.strictEqual(clicks, 1);

    assert.dom('[data-test="link"]').hasTagName('a').hasAttribute('aria-current', 'true').hasAttribute('rel', 'noreferrer').doesNotHaveAttribute('aria-pressed');
    const badge = style(root, '[data-test="link"] .euiKeyPadMenuItem__betaBadge');
    assert.strictEqual(badge.position, 'absolute');
    assert.strictEqual(badge.top, light.size.xs);
    assert.strictEqual(badge.right, light.size.xs);
    assert.dom('[data-test="link"] .euiKeyPadMenuItem__betaBadge').hasText('B');

    finishTransitions();
    const off = style(root, '[data-test="off"]');
    assert.dom('[data-test="off"]').isDisabled();
    assert.strictEqual(off.color, rgb(light.colors.textDisabled));
    assert.strictEqual(off.cursor, 'not-allowed');
    assert.strictEqual(style(root, '[data-test="off-selected"]').backgroundColor, rgb(light.colors.backgroundBaseDisabled));
  });

  test('EuiKeyPadMenu checkable: fieldset, legend, radios and checkboxes', async function (assert) {
    const changes: unknown[][] = [];
    const onChange = (...args: unknown[]) => changes.push(args.slice(0, 2));
    const legend = { legend: 'Pick one' };
    const ariaLegend = { ariaLegend: 'Pick many' };
    await render(
      <template>
        <EuiKeyPadMenu @checkable={{legend}} data-test="radios">
          <EuiKeyPadMenuItem @checkable="single" @label="A" @name="pick" @value="a" @id="ra" @isSelected={{true}} @onChange={{onChange}} />
          <EuiKeyPadMenuItem @checkable="single" @label="B" @name="pick" @value="b" @id="rb" @onChange={{onChange}} />
          <EuiKeyPadMenuItem @checkable="single" @label="C" @name="pick" @value="c" @id="rc" @isDisabled={{true}} @onChange={{onChange}} />
        </EuiKeyPadMenu>
        <EuiKeyPadMenu @checkable={{ariaLegend}} data-test="checkboxes">
          <EuiKeyPadMenuItem @checkable="multi" @label="X" @id="cx" @onChange={{onChange}} />
        </EuiKeyPadMenu>
        <EuiKeyPadMenu @checkable={{true}} data-test="plain">
          <EuiKeyPadMenuItem @checkable="label" @label="Y" @id="cy" @onChange={{onChange}} />
        </EuiKeyPadMenu>
      </template>
    );
    const root = this.element;
    assert.dom('[data-test="radios"]').hasTagName('fieldset').doesNotHaveAttribute('aria-label');
    const fieldset = style(root, '[data-test="radios"]');
    assert.strictEqual(fieldset.borderTopStyle, 'none');
    assert.strictEqual(fieldset.paddingTop, '0px');
    assert.strictEqual(fieldset.display, 'flex');
    assert.dom('[data-test="radios"] legend').hasText('Pick one');
    assert.strictEqual(style(root, '[data-test="radios"] legend').marginBottom, light.size.s);
    assert.dom('[data-test="checkboxes"]').hasTagName('fieldset').hasAria('label', 'Pick many');
    assert.dom('[data-test="checkboxes"] legend').doesNotExist();
    assert.dom('[data-test="plain"]').hasTagName('fieldset');

    assert.dom('label[for="ra"].euiKeyPadMenuItem').exists();
    assert.dom('#ra').hasAttribute('type', 'radio').isChecked();
    assert.dom('#rb').isNotChecked();
    assert.dom('#rc').isDisabled();
    assert.dom('#cx').hasAttribute('type', 'checkbox');
    assert.dom('#cy').hasAttribute('type', 'checkbox', 'legacy "label" is a checkbox');

    const inputOf = (id: string) => getComputedStyle(el(root, `#${id}`).closest('.euiKeyPadMenuItem__checkableInput')!);
    assert.strictEqual(inputOf('ra').position, 'absolute');
    assert.strictEqual(inputOf('ra').transform, 'matrix(0.75, 0, 0, 0.75, 0, 0)', 'selected input shows, scaled');
    assert.strictEqual(inputOf('rb').width, '1px', 'unselected input is screen-reader only until hover/focus');
    assert.strictEqual(inputOf('rc').width, '1px', 'disabled unselected input is hidden');

    await click('#rb');
    await click('#cx');
    assert.deepEqual(changes, [['rb', 'b'], ['cx', changes[1]![1]]]);
    assert.strictEqual(changes[1]![0], 'cx');
  });

  test('EuiDescriptionList: row, reverse, compressed, inline and gutters', async function (assert) {
    class State {
      @tracked type: 'row' | 'column' | 'inline' = 'row';
      @tracked textStyle: 'normal' | 'reverse' = 'normal';
      @tracked compressed = false;
      @tracked gutter: 's' | 'm' = 's';
    }
    const state = new State();
    const titleProps = { className: 'my-title' };
    await render(
      <template>
        <EuiEmotionProvider>
          <EuiDescriptionList
            @type={{state.type}}
            @textStyle={{state.textStyle}}
            @compressed={{state.compressed}}
            @rowGutterSize={{state.gutter}}
            @listItems={{DL_ITEMS}}
            @titleProps={{titleProps}}
            data-test="dl"
          />
        </EuiEmotionProvider>
      </template>
    );
    const root = this.element;
    const dl = el(root, '[data-test="dl"]');
    const dt = () => [...dl.querySelectorAll<HTMLElement>('dt')].map((e) => getComputedStyle(e));
    const dd = () => getComputedStyle(dl.querySelector('dd')!);
    assert.dom('[data-test="dl"] dt.my-title').exists({ count: 2 });
    assert.strictEqual(getComputedStyle(dl).marginTop, '0px');
    assert.strictEqual(dd().marginLeft, '0px', 'dd reset');

    // normal: title is an xs title, description s text
    const normalTitle = dt()[0]!;
    close(assert, parseFloat(normalTitle.fontSize), remPx(16), 'title xs is 16px');
    assert.strictEqual(normalTitle.fontWeight, String(light.font.weight.bold));
    assert.strictEqual(normalTitle.color, rgb(light.colors.textHeading));
    close(assert, parseFloat(dd().fontSize), remPx(14), 'description s');
    assert.strictEqual(normalTitle.marginTop, '0px', 'first title has no gutter');
    assert.strictEqual(dt()[1]!.marginTop, light.size.s, 'row gutter s');
    assert.strictEqual(normalTitle.overflowWrap, 'break-word');

    state.gutter = 'm';
    await settled();
    assert.strictEqual(dt()[1]!.marginTop, light.size.base, 'row gutter m');

    state.textStyle = 'reverse';
    await settled();
    close(assert, parseFloat(dt()[0]!.fontSize), remPx(14), 'reverse: title is s text');
    close(assert, parseFloat(dd().fontSize), remPx(16), 'reverse: description is an xs title');

    state.compressed = true;
    await settled();
    close(assert, parseFloat(dt()[0]!.fontSize), remPx(12), 'compressed reverse title xs text');
    close(assert, parseFloat(dd().fontSize), remPx(14), 'compressed reverse description xxs title');
    state.textStyle = 'normal';
    await settled();
    close(assert, parseFloat(dt()[0]!.fontSize), remPx(14), 'compressed title xxs');
    close(assert, parseFloat(dd().fontSize), remPx(12), 'compressed description xs');

    state.compressed = false;
    state.type = 'inline';
    await settled();
    assert.strictEqual(el(root, '[data-test="dl"]'), dl, 'element kept');
    assert.dom(dl).hasAttribute('data-type', 'inline');
    const inlineTitle = dt();
    assert.strictEqual(inlineTitle[0]!.display, 'inline');
    assert.strictEqual(dd().display, 'inline');
    assert.strictEqual(inlineTitle[0]!.backgroundColor, rgb(light.colors.lightestShade));
    assert.strictEqual(inlineTitle[0]!.marginLeft, '0px', 'first inline title');
    assert.strictEqual(inlineTitle[1]!.marginLeft, light.size.xs);
    assert.strictEqual(inlineTitle[0]!.paddingLeft, light.size.xs);
    assert.strictEqual(inlineTitle[0]!.paddingTop, '1px');
    assert.strictEqual(inlineTitle[0]!.fontWeight, String(light.font.weight.medium));
  });

  test('EuiDescriptionList: column grid, gaps, widths and center alignment', async function (assert) {
    class State {
      @tracked align: 'left' | 'center' = 'left';
      @tracked widths: [number | string, number | string] | undefined = undefined;
    }
    const state = new State();
    await render(
      <template>
        <div style="width: 800px">
          <EuiDescriptionList @type="column" @align={{state.align}} @columnWidths={{state.widths}} data-test="s">
            <EuiDescriptionListTitle>Name</EuiDescriptionListTitle>
            <EuiDescriptionListDescription>Jane</EuiDescriptionListDescription>
            <EuiDescriptionListTitle>Role</EuiDescriptionListTitle>
            <EuiDescriptionListDescription>Admin</EuiDescriptionListDescription>
          </EuiDescriptionList>
          <EuiDescriptionList @type="column" @rowGutterSize="m" @columnGutterSize="m" @listItems={{DL_ITEMS}} data-test="m" />
        </div>
      </template>
    );
    const root = this.element;
    const s = style(root, '[data-test="s"]');
    assert.strictEqual(s.display, 'grid');
    assert.strictEqual(s.alignItems, 'baseline');
    assert.strictEqual(s.columnGap, light.size.s);
    assert.strictEqual(s.rowGap, light.size.s);
    assert.strictEqual(style(root, '[data-test="m"]').columnGap, light.size.xl);
    assert.strictEqual(style(root, '[data-test="m"]').rowGap, light.size.m);
    const dt = el(root, '[data-test="s"] dt').getBoundingClientRect();
    const dd = el(root, '[data-test="s"] dd').getBoundingClientRect();
    assert.true(dd.left >= dt.right && dd.top < dt.bottom, 'title and description share a row');
    assert.strictEqual(style(root, '[data-test="s"] dt:nth-of-type(2)').marginTop, '0px', 'column titles have no row margin');

    state.align = 'center';
    await settled();
    assert.strictEqual(style(root, '[data-test="s"]').textAlign, 'center');
    // Upstream logical alignment: right/left serialize to end/start.
    assert.strictEqual(style(root, '[data-test="s"] dt').textAlign, 'end');
    assert.strictEqual(style(root, '[data-test="s"] dd').textAlign, 'start');

    state.widths = [1, 3];
    await settled();
    const [titleCol, descCol] = style(root, '[data-test="s"]').gridTemplateColumns.split(' ').map(parseFloat);
    close(assert, descCol! / titleCol!, 3, 'numbers are fr units');
    state.widths = ['100px', 'auto'];
    await settled();
    assert.true(style(root, '[data-test="s"]').gridTemplateColumns.startsWith('100px'), 'strings are tracks');
  });

  test('EuiDescriptionList responsiveColumn: row below m, column from m (iframe viewport)', async function (assert) {
    await render(
      <template>
        <EuiDescriptionList @type="responsiveColumn" @align="center" @listItems={{DL_ITEMS}} data-test="dl" />
      </template>
    );
    const root = this.element;
    assert.dom('[data-test="dl"]').hasAttribute('data-type', 'responsiveColumn');
    const html = el(root, '[data-test="dl"]').outerHTML;
    const m = light.breakpoint.m;
    const narrow = inViewport(m - 1, html);
    const wide = inViewport(m, html);
    try {
      assert.notStrictEqual(narrow.style('dl').display, 'grid', 'narrow: row');
      assert.strictEqual(narrow.style('dt:nth-of-type(2)').marginTop, light.size.s, 'narrow: row gutter');
      assert.strictEqual(narrow.style('dt').textAlign, 'center', 'narrow: centered row titles');
      assert.strictEqual(wide.style('dl').display, 'grid', 'wide: column');
      assert.strictEqual(wide.style('dl').columnGap, light.size.s);
      assert.strictEqual(wide.style('dt:nth-of-type(2)').marginTop, '0px');
      assert.strictEqual(wide.style('dt').textAlign, 'end');
      assert.strictEqual(wide.style('dd').textAlign, 'start');
      assert.strictEqual(wide.style('dt').fontWeight, narrow.style('dt').fontWeight, 'fonts do not depend on width');
    } finally {
      narrow.remove();
      wide.remove();
    }
  });

  test('EuiSideNav: depth indentation, selected, emphasized, truncation and links', async function (assert) {
    class State {
      @tracked selected = 'branch-a';
    }
    const state = new State();
    let clicks = 0;
    const items = sideNavItems(() => clicks++);
    await render(
      <template>
        <EuiEmotionProvider>
          <div style="width: 300px">
            <EuiSideNav @heading="Docs" @items={{items}} @selectedItem={{state.selected}} @mobileBreakpoints={{array}} />
          </div>
        </EuiEmotionProvider>
      </template>
    );
    const root = this.element;
    const rootItem = el(root, '.euiSideNavItem--root');
    assert.strictEqual(getComputedStyle(rootItem).paddingBottom, light.size.s);
    assert.strictEqual(style(root, '.euiSideNavItem--root + .euiSideNavItem--root').marginTop, light.size.s, 'root siblings are separated');
    const rootItems = rootItem.querySelector<HTMLElement>(':scope > .euiSideNavItem__items')!;
    assert.strictEqual(getComputedStyle(rootItems).marginLeft, light.size.l, 'root with icon indents by l');
    const trunkItems = el(root, '.euiSideNavItem--trunk > .euiSideNavItem__items');
    assert.strictEqual(getComputedStyle(trunkItems).marginLeft, light.size.s, 'trunk children indent by s');
    const branch = el(root, '.euiSideNavItem--branch');
    assert.strictEqual(getComputedStyle(branch).color, rgb(light.colors.textSubdued));
    assert.strictEqual(getComputedStyle(branch, '::after').borderLeftWidth, '1px', 'branch tree line');
    assert.strictEqual(style(root, '.euiSideNavItem--trunk').color, rgb(light.colors.textHeading));

    const rootLabel = style(root, '.euiSideNavItem--root > .euiSideNavItemButton .euiSideNavItemButton__label');
    assert.strictEqual(rootLabel.fontWeight, String(light.font.weight.bold), 'root labels are xxs titles');
    const selected = el(root, '.euiSideNavItemButton-isSelected');
    assert.dom(selected).hasText('Branch A');
    assert.strictEqual(getComputedStyle(selected).color, rgb(light.colors.textPrimary));
    assert.strictEqual(getComputedStyle(selected).fontWeight, String(light.font.weight.bold));
    assert.strictEqual(style(root, '.euiSideNavItemButton-isSelected .euiSideNavItemButton__label').textDecorationLine, 'underline');

    const emph = el(root, '.euiSideNavItem--emphasized');
    assert.strictEqual(getComputedStyle(emph).backgroundColor, rgb(light.components.sideNavItemEmphasizedBackground));
    assert.strictEqual(getComputedStyle(emph).color, rgb(light.colors.textHeading));

    assert.dom('button.euiSideNavItemButton[disabled]').hasText('Disabled');
    assert.strictEqual(style(root, 'button.euiSideNavItemButton[disabled]').color, rgb(light.colors.textDisabled));
    assert.strictEqual(style(root, 'button.euiSideNavItemButton[disabled]').cursor, 'not-allowed');

    const long = [...root.querySelectorAll<HTMLElement>('.euiSideNavItemButton__label')].find((e) => e.textContent!.includes('very long'))!;
    assert.strictEqual(getComputedStyle(long).whiteSpace, 'nowrap');
    assert.strictEqual(getComputedStyle(long).textOverflow, 'ellipsis');
    assert.true(long.classList.contains('eui-textTruncate'));
    await settled();
    assert.dom(long).hasAttribute('title');
    const wrap = [...root.querySelectorAll<HTMLElement>('.euiSideNavItemButton__label')].find((e) => e.textContent!.trim() === 'Wrapped')!;
    assert.notStrictEqual(getComputedStyle(wrap).whiteSpace, 'nowrap', 'truncate: false');

    const link = el(root, 'a.euiSideNavItemButton');
    assert.dom(link).hasAttribute('href', '#b').hasAttribute('rel', 'noopener noreferrer');
    assert.true(
      [...root.querySelectorAll('div.euiSideNavItemButton')].some((e) => e.textContent!.trim() === 'Plain root'),
      'items without actions are plain divs'
    );

    const trunkButton = [...root.querySelectorAll<HTMLButtonElement>('button.euiSideNavItemButton')].find((e) => e.textContent!.includes('Trunk A'))!;
    await click(trunkButton);
    assert.strictEqual(clicks, 1);
    state.selected = 'trunk-a';
    await settled();
    assert.dom('.euiSideNavItemButton-isSelected').hasText('Trunk A');
    assert.strictEqual(el(root, '.euiSideNavItemButton-isSelected'), trunkButton, 'button kept when selection moves');
  });

  test('EuiSideNav: section accordions toggle and reset with the selection', async function (assert) {
    class State {
      @tracked selected = 'trunk-a';
    }
    const state = new State();
    const items = sideNavItems();
    await render(
      <template>
        <EuiSideNav @items={{items}} @selectedItem={{state.selected}} @mobileBreakpoints={{array}} />
      </template>
    );
    const root = this.element;
    const section = [...root.querySelectorAll<HTMLElement>('.euiSideNavItemButton')].find((e) => e.textContent!.trim() === 'Section')!;
    assert.strictEqual(section.tagName, 'BUTTON', 'section items are toggle buttons');
    assert.dom(section).hasAttribute('aria-expanded', 'false').doesNotHaveClass('euiSideNavItemButton-isSelected');
    assert.dom(section.querySelector('.euiSideNavItemButton__caret')!).exists();
    assert.dom('.euiSideNavItem--branch').doesNotExist('closed by default');

    await click(section);
    assert.dom(section).hasAttribute('aria-expanded', 'true');
    assert.dom('.euiSideNavItem--branch').exists({ count: 2 });
    assert.true(section.classList.contains('euiSideNavItemButton-isOpen'));
    await click(section);
    assert.dom('.euiSideNavItem--branch').doesNotExist('toggles closed');

    state.selected = 'branch-b';
    await settled();
    assert.dom('.euiSideNavItem--branch').exists({ count: 2 }, 'selecting a child opens the section');
    assert.dom('.euiSideNavItemButton-isSelected').hasText('Branch B');
  });

  test('EuiSideNav: mobile toggle, heading semantics and content visibility', async function (assert) {
    class State {
      @tracked open = false;
    }
    const state = new State();
    const toggles: boolean[] = [];
    const toggle = (value: boolean) => {
      toggles.push(value);
      state.open = value;
    };
    const items = sideNavItems();
    const sizes = ['xs', 's', 'm', 'l', 'xl'] as const;
    const srOnly = { screenReaderOnly: true, id: 'nav-heading', element: 'h3' as const };
    await render(
      <template>
        <div data-test="mobile">
          <EuiSideNav @heading="Docs" @items={{items}} @mobileBreakpoints={{sizes}} @isOpenMobile={{state.open}} @toggleOpenOnMobile={{toggle}} />
        </div>
        <div data-test="sr">
          <EuiSideNav @heading="Hidden" @headingProps={{srOnly}} @items={{items}} @mobileBreakpoints={{sizes}} />
        </div>
        <div data-test="desktop">
          <EuiSideNav @heading="Desktop" @items={{items}} @mobileBreakpoints={{array}} />
        </div>
      </template>
    );
    const root = el(this.element, '[data-test="mobile"]');
    const nav = el(root, 'nav.euiSideNav');
    const heading = el(root, '.euiSideNav__heading');
    assert.strictEqual(nav.getAttribute('aria-labelledby'), heading.id);
    assert.strictEqual(heading.tagName, 'H2');
    assert.strictEqual(getComputedStyle(heading).marginBottom, '0px', 'mobile heading has no margin');
    const button = el(root, '.euiSideNav__mobileToggle');
    const content = el(root, '.euiSideNav__content');
    assert.dom(button).hasText('Docs').hasAttribute('aria-expanded', 'false').hasAttribute('aria-controls', content.id).doesNotHaveAttribute('aria-label');
    const b = getComputedStyle(button);
    assert.strictEqual(button.offsetWidth, nav.offsetWidth, 'full width toggle');
    assert.strictEqual(b.borderBottomWidth, '1px');
    assert.strictEqual(b.borderTopLeftRadius, '0px');
    assert.strictEqual(b.textAlign, 'start');
    finishTransitions();
    assert.strictEqual(getComputedStyle(content).visibility, 'hidden');
    assert.strictEqual(getComputedStyle(content).maxHeight, '0px');

    await click(button);
    finishTransitions();
    assert.deepEqual(toggles, [true]);
    assert.dom(button).hasAttribute('aria-expanded', 'true');
    assert.true(nav.classList.contains('euiSideNav-isOpenMobile'));
    assert.strictEqual(getComputedStyle(content).visibility, 'visible');
    assert.strictEqual(getComputedStyle(content).paddingTop, light.size.l);
    assert.strictEqual(el(root, '.euiSideNav__mobileToggle'), button, 'button kept');

    const sr = el(this.element, '[data-test="sr"]');
    assert.dom(sr.querySelector('.euiSideNav__mobileToggle')!).hasAria('label', 'Toggle navigation').hasText('');
    assert.dom(sr.querySelector('#nav-heading')!).hasTagName('h3');

    const desktop = el(this.element, '[data-test="desktop"]');
    const desktopHeading = el(desktop, '.euiSideNav__heading');
    assert.strictEqual(el(desktop, 'nav').getAttribute('aria-labelledby'), desktopHeading.id, 'heading labels the nav');
    assert.strictEqual(getComputedStyle(desktopHeading).marginBottom, light.size.l);
    assert.dom(desktop.querySelector('.euiSideNav__mobileToggle')!).doesNotExist();
  });

  test('light/dark follow the nearest provider with sibling isolation', async function (assert) {
    class State {
      @tracked mode: 'light' | 'dark' = 'dark';
    }
    const state = new State();
    const items = sideNavItems();
    await render(
      <template>
        <EuiEmotionProvider @colorMode={{state.mode}}>
          <EuiListGroup>
            <EuiListGroupItem @label="Active" @href="#a" @isActive={{true}} data-test="dark-active" />
            <EuiListGroupItem @label="Text" data-test="dark-text" />
          </EuiListGroup>
          <EuiKeyPadMenu as |Key|>
            <Key><EuiKeyPadMenuItem @label="K" @isSelected={{true}} data-test="dark-key" /></Key>
          </EuiKeyPadMenu>
          <EuiDescriptionList @type="inline" @listItems={{DL_ITEMS}} data-test="dark-dl" />
          <EuiSideNav @items={{items}} @selectedItem="trunk-a" @mobileBreakpoints={{array}} data-test="dark-nav" />
          <EuiEmotionProvider @colorMode="light">
            <EuiListGroup>
              <EuiListGroupItem @label="Text" data-test="nested-text" />
            </EuiListGroup>
          </EuiEmotionProvider>
        </EuiEmotionProvider>
        <EuiEmotionProvider @colorMode="light">
          <EuiListGroup>
            <EuiListGroupItem @label="Active" @href="#a" @isActive={{true}} data-test="sibling-active" />
          </EuiListGroup>
        </EuiEmotionProvider>
      </template>
    );
    const root = this.element;
    const wrapper = (name: string) => getComputedStyle(el(root, `[data-test="${name}"]`).parentElement!);
    assert.strictEqual(wrapper('dark-active').backgroundColor, rgb(dark.colors.backgroundBaseInteractiveSelect));
    assert.strictEqual(wrapper('dark-active').color, rgb(dark.colors.textPrimary));
    assert.strictEqual(style(root, '[data-test="dark-text"]').color, rgb(dark.colors.textParagraph));
    assert.strictEqual(style(root, '[data-test="dark-key"]').color, rgb(dark.colors.textPrimary));
    assert.strictEqual(style(root, '[data-test="dark-dl"] dt').backgroundColor, rgb(dark.colors.lightShade), 'dark inline titles use lightShade');
    assert.strictEqual(style(root, '[data-test="dark-dl"] dt').color, rgb(dark.colors.textHeading));
    assert.strictEqual(style(root, '.euiSideNavItemButton-isSelected').color, rgb(dark.colors.textPrimary));
    assert.strictEqual(style(root, '[data-test="nested-text"]').color, rgb(light.colors.textParagraph), 'nested light');
    assert.strictEqual(wrapper('sibling-active').backgroundColor, rgb(light.colors.backgroundBaseInteractiveSelect), 'sibling light');
    assert.notStrictEqual(rgb(dark.colors.textPrimary), rgb(light.colors.textPrimary));

    state.mode = 'light';
    await settled();
    assert.strictEqual(wrapper('dark-active').color, rgb(light.colors.textPrimary), 'switched to light');
    assert.strictEqual(style(root, '[data-test="dark-dl"] dt').backgroundColor, rgb(light.colors.lightestShade));
  });

  test('native token overrides (JS objects) and high contrast', async function (assert) {
    class State {
      @tracked overrides: EuiBorealisOverrides = {};
      @tracked contrast: EuiBorealisHighContrastMode = false;
    }
    const state = new State();
    const items = sideNavItems();
    await render(
      <template>
        <EuiEmotionProvider @borealisOverrides={{state.overrides}} @highContrastMode={{state.contrast}}>
          <EuiListGroup>
            <EuiListGroupItem @label="Primary" @color="primary" data-test="primary" />
            <EuiListGroupItem @label="Text" @href="#t" data-test="link" />
          </EuiListGroup>
          <EuiKeyPadMenu data-test="menu" as |Key|>
            <Key><EuiKeyPadMenuItem @label="K" @isSelected={{true}} data-test="key" /></Key>
          </EuiKeyPadMenu>
          <EuiSideNav @items={{items}} @selectedItem="trunk-a" @mobileBreakpoints={{array}} />
        </EuiEmotionProvider>
        <EuiListGroup>
          <EuiListGroupItem @label="Outside" @color="primary" data-test="outside" />
        </EuiListGroup>
      </template>
    );
    const root = this.element;
    state.overrides = {
      colors: { LIGHT: { primary: '#663399', textPrimary: '#663399' } },
      size: { xs: '6px' }
    };
    await settled();
    const overridden = resolveBorealisTheme('light', state.overrides).euiTheme;
    assert.strictEqual(style(root, '[data-test="primary"]').color, rgb(overridden.colors.textPrimary), 'primary override');
    assert.notStrictEqual(rgb(overridden.colors.textPrimary), rgb(light.colors.textPrimary));
    assert.strictEqual(style(root, '[data-test="menu"]').columnGap, '6px', 'size override');
    assert.strictEqual(style(root, '[data-test="key"]').paddingTop, '6px');
    assert.strictEqual(style(root, '.euiSideNavItemButton-isSelected').color, rgb(overridden.colors.textPrimary));
    assert.strictEqual(style(root, '[data-test="outside"]').color, rgb(light.colors.textPrimary), 'outside is isolated');

    state.overrides = {};
    state.contrast = 'preferred';
    await settled();
    const hc = resolveBorealisTheme('light', {}, 'preferred').euiTheme;
    const key = style(root, '[data-test="key"]');
    assert.strictEqual(key.outlineStyle, 'solid', 'high contrast selected key outline');
    assert.strictEqual(key.outlineColor, rgb(hc.colors.primary));
    assert.strictEqual(key.outlineWidth, hc.border.width.thick);
  });

  test('RTL: indentation, extra action padding, badges and inline titles are logical', async function (assert) {
    const items = sideNavItems();
    const favorite = { iconType: 'starEmpty', 'aria-label': 'Favorite' };
    await render(
      <template>
        <div dir="rtl">
          <EuiListGroup>
            <EuiListGroupItem @label="פריט" @href="#a" @extraAction={{favorite}} data-test="item" />
          </EuiListGroup>
          <EuiKeyPadMenu as |Key|>
            <Key><EuiKeyPadMenuItem @label="K" @betaBadgeLabel="Beta" data-test="key" /></Key>
          </EuiKeyPadMenu>
          <EuiDescriptionList @type="inline" @listItems={{DL_ITEMS}} data-test="dl" />
          <EuiSideNav @items={{items}} @selectedItem="branch-a" @mobileBreakpoints={{array}} />
        </div>
      </template>
    );
    const root = this.element;
    const wrapper = getComputedStyle(el(root, '[data-test="item"]').parentElement!);
    assert.strictEqual(wrapper.paddingLeft, light.size.s, 'extra action padding is inline-end');
    assert.strictEqual(wrapper.paddingRight, '0px');
    const badge = style(root, '[data-test="key"] .euiKeyPadMenuItem__betaBadge');
    assert.strictEqual(badge.left, light.size.xs, 'beta badge at the inline end');
    const titles = [...root.querySelectorAll<HTMLElement>('[data-test="dl"] dt')].map((e) => getComputedStyle(e));
    assert.strictEqual(titles[0]!.marginRight, '0px', 'first inline title has no start margin');
    assert.strictEqual(titles[1]!.marginRight, light.size.xs);
    assert.strictEqual(style(root, '.euiSideNavItem--trunk > .euiSideNavItem__items').marginRight, light.size.s, 'trunk indentation flips');
    assert.strictEqual(style(root, '.euiSideNavItem--root > .euiSideNavItem__items').marginRight, light.size.l);
  });
});

