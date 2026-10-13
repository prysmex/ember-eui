import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import { array } from '@ember/helper';
import { on } from '@ember/modifier';
import { htmlSafe } from '@ember/template';
import {
  click,
  render,
  rerender,
  settled,
  triggerEvent,
  triggerKeyEvent,
  waitUntil
} from '@ember/test-helpers';

import EuiButton from '#src/components/eui-button.gts';
import EuiContextMenu from '#src/components/eui-context-menu.gts';
import EuiContextMenuItem from '#src/components/eui-context-menu-item.gts';
import EuiContextMenuPanel from '#src/components/eui-context-menu-panel.gts';
import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import EuiIconTip from '#src/components/eui-icon-tip.gts';
import EuiInputPopover from '#src/components/eui-input-popover.gts';
import EuiPopover from '#src/components/eui-popover.gts';
import EuiPopoverFooter from '#src/components/eui-popover-footer.gts';
import EuiPopoverTitle from '#src/components/eui-popover-title.gts';
import EuiToolTip from '#src/components/eui-tool-tip.gts';
import {
  euiContextMenuPanelStyles,
  euiPaddingSize,
  euiPopoverPanelStyles,
  euiToolTipStyles
} from '#src/utils/eui/styles.generated.ts';
import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';

import type { EuiBorealisHighContrastMode, EuiBorealisOverrides } from '#src/utils/eui/theme.ts';
import type { EuiColorMode } from '#src/utils/emotion/theme.ts';

const lightContext = resolveBorealisTheme('light');
const light = lightContext.euiTheme;
const dark = resolveBorealisTheme('dark').euiTheme;

function el(selector: string, root: ParentNode = document): HTMLElement {
  const element = root.querySelector<HTMLElement>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

function css(selector: string | Element, pseudo?: string) {
  return getComputedStyle(typeof selector === 'string' ? el(selector) : selector, pseudo);
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

/** Rotation (deg) of a computed `matrix(...)` transform. */
function rotation(transform: string): number {
  const [a, b] = transform.slice(7, -1).split(',').map(Number);
  return Math.round((Math.atan2(b!, a!) * 180) / Math.PI);
}

const rootFontSize = () => parseFloat(getComputedStyle(document.documentElement).fontSize);
const canAnimate = () => matchMedia('(prefers-reduced-motion: no-preference)').matches;

/** The panel of a popover whose content has `data-<name>`. */
function panelOf(name: string): HTMLElement {
  const content = el(`[data-${name}]`);
  const panel = content.closest<HTMLElement>('.euiPopover__panel');
  if (!panel) throw new Error(`No panel for ${name}`);
  return panel;
}

const opened = (name: string) =>
  waitUntil(() => {
    const content = document.querySelector(`[data-${name}]`);
    const panel = content?.closest<HTMLElement>('.euiPopover__panel');
    return panel && panel.dataset['popoverOpen'] === 'true' && getComputedStyle(panel).opacity === '1';
  }, { timeout: 3000 });

const ARROW_ROTATION = { top: -45, bottom: 135, left: -135, right: 45 } as const;

class State {
  @tracked isOpen = true;
  @tracked padding: 'none' | 's' | 'm' | 'l' = 'm';
  @tracked mode: EuiColorMode = 'dark';
  @tracked contrast: EuiBorealisHighContrastMode = false;
  @tracked overrides: EuiBorealisOverrides = {};
  @tracked color = 'text';
  @tracked disabled = false;
  closes = 0;
  open = () => (this.isOpen = true);
  close = () => {
    this.closes++;
    this.isOpen = false;
  };
  noop = () => {};
}

module('Integration | Component | Borealis overlays', function (hooks) {
  setupRenderingTest(hooks);

  test('EuiPopover panel: surface, radius, padding sizes, shadow, open state and root', async function (assert) {
    const state = new State();

    await render(
      <template>
        {{#each (array "none" "s" "m" "l") as |size|}}
          <EuiPopover @isOpen={{true}} @ownFocus={{false}} @closePopover={{state.noop}} @panelPaddingSize={{size}}>
            <:button><button type="button">{{size}}</button></:button>
            <:content><span data-pad={{size}}>Content</span></:content>
          </EuiPopover>
        {{/each}}
      </template>
    );

    await opened('pad="m"');
    const panel = panelOf('pad="m"');
    const style = css(panel);

    assert.dom(panel).hasClass('euiPopover__panel').hasClass('euiPanel').hasAttribute('data-popover-panel');
    assert.strictEqual(style.backgroundColor, rgb(light.components.popoverPanelBackground), 'popover panel background token');
    assert.strictEqual(style.color, rgb(light.colors.textParagraph), 'theme text color, even portaled');
    assert.strictEqual(style.borderTopLeftRadius, light.border.radius.panel, 'panel radius');
    assert.strictEqual(style.position, 'absolute');
    assert.strictEqual(style.minWidth, `${light.base * 7}px`, 'upstream min width');
    assert.strictEqual(style.pointerEvents, 'auto', 'open panels take pointer events');
    assert.true(style.filter.includes('drop-shadow'), 'medium shadow through `filter` (covers the arrow)');
    assert.strictEqual(css(panel, '::after').borderTopColor, rgb(light.colors.borderBaseFloating), 'floating border pseudo');
    assert.strictEqual(style.getPropertyValue('--euiPopoverBackgroundColor').trim().toLowerCase(), light.components.popoverPanelBackground.toLowerCase());

    for (const size of ['none', 's', 'm', 'l'] as const) {
      const expected = euiPaddingSize(lightContext, size) ?? '0px';
      assert.strictEqual(css(panelOf(`pad="${size}"`)).paddingTop, expected, `padding ${size}`);
    }

    // root: upstream euiPopoverStyles
    const root = css(el('.euiPopover'));
    assert.strictEqual(root.display, 'inline-block');
    assert.strictEqual(root.position, 'relative');
    assert.strictEqual(root.verticalAlign, 'middle');
    assert.strictEqual(root.maxWidth, '100%');

    // animation guard: the transition lives behind prefers-reduced-motion
    const styles = euiPopoverPanelStyles(lightContext);
    assert.true(styles.euiPopover__panel.styles.includes('prefers-reduced-motion: no-preference'));
    assert.strictEqual(
      style.transitionProperty.includes('opacity'),
      canAnimate(),
      'transitions only when motion is allowed'
    );
    assert.strictEqual(state.closes, 0);
  });

  test('EuiPopover arrow: placement per position, offsets and RTL logical margins', async function (assert) {
    const state = new State();
    const anchors = [
      ['rightCenter', htmlSafe('position: absolute; left: 0; top: 100px')],
      ['leftCenter', htmlSafe('position: absolute; right: 0; top: 100px')],
      ['downCenter', htmlSafe('position: absolute; left: 180px; top: 0')],
      ['upCenter', htmlSafe('position: absolute; left: 180px; bottom: 0')]
    ] as const;

    await render(
      <template>
        <div style="position: relative; width: 420px; height: 240px">
          {{#each anchors as |anchor|}}
            <div style={{anchor.[1]}}>
              <EuiPopover
                @isOpen={{true}}
                @ownFocus={{false}}
                @hasArrow={{true}}
                @anchorPosition={{anchor.[0]}}
                @closePopover={{state.noop}}
              >
                <:button><button type="button">{{anchor.[0]}}</button></:button>
                <:content><span data-arrow={{anchor.[0]}}>x</span></:content>
              </EuiPopover>
            </div>
          {{/each}}
          <EuiPopover @isOpen={{true}} @ownFocus={{false}} @closePopover={{state.noop}}>
            <:button><button type="button">default</button></:button>
            <:content><span data-noarrow>x</span></:content>
          </EuiPopover>
        </div>
      </template>
    );

    for (const [anchor] of anchors) await opened(`arrow="${anchor}"`);

    const seen = new Set<string>();
    for (const [anchor] of anchors) {
      const panel = panelOf(`arrow="${anchor}"`);
      const arrow = el('.euiPopover__arrow', panel);
      const position = arrow.dataset['popoverArrow'] as keyof typeof ARROW_ROTATION;
      seen.add(position);
      const wrapper = css(el('.euiPopover__arrowWrapper', panel));
      assert.strictEqual(wrapper.width, light.size.base, `${anchor}: 16px arrow wrapper`);
      assert.strictEqual(wrapper.zIndex, '1');
      const arrowStyle = css(arrow);
      assert.strictEqual(rotation(arrowStyle.transform), ARROW_ROTATION[position], `${anchor}: rotated for ${position}`);
      assert.strictEqual(arrowStyle.clipPath, 'polygon(0px 0px, 100% 100%, 0px 100%)', 'clipped to a triangle');
      assert.strictEqual(arrowStyle.backgroundColor, rgb(light.components.popoverPanelBackground), 'arrow shares the panel color');
    }
    assert.true(seen.size >= 3, `arrows point in several directions (${[...seen].join(', ')})`);

    assert.dom('.euiPopover__arrow', panelOf('noarrow')).doesNotExist('no arrow by default (upstream)');

    // RTL: logical margins of side arrows flip
    document.body.dir = 'rtl';
    try {
      await rerender();
      for (const [anchor] of anchors) {
        const arrow = el('.euiPopover__arrow', panelOf(`arrow="${anchor}"`));
        const position = arrow.dataset['popoverArrow'];
        const arrowStyle = css(arrow);
        if (position === 'left') {
          assert.strictEqual(arrowStyle.marginRight, '-9px', 'left arrow: margin-inline-start is the right side in RTL');
          assert.strictEqual(arrowStyle.marginLeft, '0px');
        } else if (position === 'top') {
          assert.strictEqual(arrowStyle.marginTop, '-9px', 'block margins do not flip');
        }
      }
    } finally {
      document.body.dir = '';
    }
  });

  test('EuiPopover z-index inherits from the anchor stacking context (+2000), @zIndex overrides', async function (assert) {
    const state = new State();

    await render(
      <template>
        <EuiPopover @isOpen={{true}} @ownFocus={{false}} @closePopover={{state.noop}}>
          <:button><button type="button">page</button></:button>
          <:content><span data-z-page>x</span></:content>
        </EuiPopover>
        <div style="position: relative; z-index: 1000">
          <EuiPopover @isOpen={{true}} @ownFocus={{false}} @closePopover={{state.noop}}>
            <:button><button type="button">flyout</button></:button>
            <:content><span data-z-flyout>x</span></:content>
          </EuiPopover>
        </div>
        <EuiPopover @isOpen={{true}} @ownFocus={{false}} @zIndex={{4242}} @closePopover={{state.noop}}>
          <:button><button type="button">fixed</button></:button>
          <:content><span data-z-fixed>x</span></:content>
        </EuiPopover>
      </template>
    );

    await opened('z-page');
    // the harness container may carry its own z-index; on a bare page this is levels.menu
    assert.true(Number(css(panelOf('z-page')).zIndex) >= light.levels.menu, 'at least the menu level');
    // the outermost positioned ancestor with a z-index wins (here the
    // harness container), as upstream `getElementZIndex`
    assert.strictEqual(css(panelOf('z-flyout')).zIndex, css(panelOf('z-page')).zIndex, 'same stacking context');
    assert.strictEqual(css(panelOf('z-fixed')).zIndex, '4242');
  });

  test('EuiPopover a11y: dialog, trigger aria-expanded/controls, screen reader text, Escape', async function (assert) {
    const state = new State();
    state.isOpen = false;

    await render(
      <template>
        <EuiPopover @isOpen={{state.isOpen}} @closePopover={{state.close}} @ariaLabel="Settings">
          <:button><EuiButton class="trigger" {{on "click" state.open}}>Open</EuiButton></:button>
          <:content><button type="button" data-inside>inside</button></:content>
        </EuiPopover>
        <EuiPopover
          @isOpen={{true}}
          @ownFocus={{false}}
          @popoverScreenReaderText="Extra help"
          @closePopover={{state.noop}}
        >
          <:button><input aria-label="field" data-input /></:button>
          <:content><span data-sr-only-text>x</span></:content>
        </EuiPopover>
      </template>
    );

    assert.dom('.trigger').hasAttribute('aria-expanded', 'false').doesNotHaveAttribute('aria-controls');
    assert.dom('[data-input]').doesNotHaveAttribute('aria-expanded', 'inputs are left alone');

    await click('.trigger');
    await opened('inside');
    const panel = panelOf('inside');
    assert.dom(panel).hasAttribute('role', 'dialog').hasAttribute('aria-modal', 'true').hasAttribute('aria-label', 'Settings');
    assert.dom('.trigger').hasAttribute('aria-expanded', 'true').hasAttribute('aria-controls', panel.id);
    const description = el(`#${panel.getAttribute('aria-describedby')}`);
    assert.dom(description).hasText('You are in a dialog. Press Escape, or tap/click outside the dialog to close.');
    assert.strictEqual(css(description).clipPath, 'inset(50%)', 'visually hidden');

    const other = panelOf('sr-only-text');
    assert.dom(other).hasAttribute('aria-live', 'assertive');
    assert.dom(el(`#${other.getAttribute('aria-describedby')}`)).hasText('Extra help', 'custom text without ownFocus');

    await waitUntil(() => panel.contains(document.activeElement));
    await triggerKeyEvent(panel, 'keydown', 'Escape');
    assert.strictEqual(state.closes, 1);
    await settled();
    assert.dom('.trigger').hasAttribute('aria-expanded', 'false').doesNotHaveAttribute('aria-controls');
    await waitUntil(() => !document.querySelector('[data-inside]'));
  });

  test('EuiPopover reactive args and title/footer inheriting the panel padding', async function (assert) {
    const state = new State();

    await render(
      <template>
        <EuiPopover @isOpen={{true}} @ownFocus={{false}} @closePopover={{state.noop}} @panelPaddingSize={{state.padding}}>
          <:button><button type="button">anchor</button></:button>
          <:content>
            <EuiPopoverTitle data-title>Title</EuiPopoverTitle>
            <span data-reactive>Body</span>
            <EuiPopoverFooter data-footer>Footer</EuiPopoverFooter>
            <EuiPopoverFooter @paddingSize="s" data-footer-s>Small</EuiPopoverFooter>
          </:content>
        </EuiPopover>
      </template>
    );

    await opened('reactive');
    const panel = panelOf('reactive');
    const m = euiPaddingSize(lightContext, 'm');
    assert.strictEqual(css(panel).paddingTop, m);
    assert.strictEqual(css('[data-title]').marginTop, `-${m}`, 'title covers the panel padding');
    assert.strictEqual(css('[data-title]').marginBottom, m);
    assert.strictEqual(css('[data-title]').paddingTop, m, 'title padding follows the panel');
    assert.strictEqual(css('[data-title]').borderBottomColor, rgb(light.border.color));
    assert.strictEqual(css('[data-title]').borderTopLeftRadius, light.border.radius.panel);
    assert.strictEqual(css('[data-footer]').marginBottom, `-${m}`, 'footer covers the panel padding');
    assert.strictEqual(css('[data-footer]').borderTopColor, rgb(light.components.popoverFooterBorderColor));
    assert.strictEqual(css('[data-footer-s]').paddingTop, euiPaddingSize(lightContext, 's'), 'own @paddingSize wins');

    state.padding = 'l';
    await settled();
    const l = euiPaddingSize(lightContext, 'l');
    assert.strictEqual(panelOf('reactive'), panel, 'same panel element');
    assert.strictEqual(css(panel).paddingTop, l);
    assert.strictEqual(css('[data-title]').marginTop, `-${l}`);
    assert.strictEqual(css('[data-footer]').paddingTop, l);
  });

  test('EuiPopover light/dark: nearest provider, sibling isolation, portaled content, JS overrides', async function (assert) {
    const state = new State();

    await render(
      <template>
        <EuiEmotionProvider @colorMode={{state.mode}} @borealisOverrides={{state.overrides}}>
          <EuiPopover @isOpen={{true}} @ownFocus={{false}} @hasArrow={{true}} @closePopover={{state.noop}}>
            <:button><button type="button">dark</button></:button>
            <:content><span data-themed>dark</span></:content>
          </EuiPopover>
        </EuiEmotionProvider>
        <EuiEmotionProvider @colorMode="light">
          <EuiPopover @isOpen={{true}} @ownFocus={{false}} @closePopover={{state.noop}}>
            <:button><button type="button">light</button></:button>
            <:content><span data-sibling>light</span></:content>
          </EuiPopover>
        </EuiEmotionProvider>
      </template>
    );

    await opened('themed');
    await opened('sibling');
    const panel = panelOf('themed');
    assert.false(el('.euiThemeProvider').contains(panel), 'the panel is portaled out of the provider');
    assert.strictEqual(css(panel).backgroundColor, rgb(dark.components.popoverPanelBackground), 'dark panel');
    assert.strictEqual(css(panel).color, rgb(dark.colors.textParagraph), 'dark text in the portal');
    assert.strictEqual(css(panel, '::after').borderTopColor, rgb(dark.colors.borderBaseFloating), 'dark floating border');
    assert.strictEqual(css(el('.euiPopover__arrow', panel)).borderTopStyle, 'solid', 'dark arrows get a border');
    assert.strictEqual(css(panelOf('sibling')).backgroundColor, rgb(light.components.popoverPanelBackground), 'sibling stays light');

    state.overrides = {
      border: { radius: { panel: '20px' } },
      components: {
        LIGHT: { popoverPanelBackground: '#ffee00' },
        DARK: { popoverPanelBackground: '#665500' }
      }
    };
    await settled();
    assert.strictEqual(panelOf('themed'), panel, 'same element after override change');
    assert.strictEqual(css(panel).backgroundColor, 'rgb(102, 85, 0)', 'mode-specific component token override');
    assert.strictEqual(css(panel).borderTopLeftRadius, '20px', 'radius override');

    state.mode = 'light';
    await settled();
    assert.strictEqual(css(panel).backgroundColor, 'rgb(255, 238, 0)', 'light override');
    assert.strictEqual(css(el('.euiPopover__arrow', panel)).borderTopStyle, 'none', 'light arrows have no border');
    assert.strictEqual(css(panelOf('sibling')).backgroundColor, rgb(light.components.popoverPanelBackground), 'sibling unaffected');
  });

  test('EuiPopover and EuiToolTip in high contrast: borders replace shadows', async function (assert) {
    const state = new State();
    state.contrast = 'preferred';

    await render(
      <template>
        <EuiEmotionProvider @highContrastMode={{state.contrast}}>
          <EuiPopover @isOpen={{true}} @ownFocus={{false}} @closePopover={{state.noop}}>
            <:button><button type="button">hc</button></:button>
            <:content><span data-hc>x</span></:content>
          </EuiPopover>
          <EuiToolTip @content="Contrast" @isShown={{true}}>
            <button type="button">tip</button>
          </EuiToolTip>
        </EuiEmotionProvider>
      </template>
    );

    await opened('hc');
    const hc = resolveBorealisTheme('light', {}, 'preferred').euiTheme;
    const panel = panelOf('hc');
    assert.strictEqual(css(panel).filter, 'none', 'no shadow');
    assert.strictEqual(css(panel).borderTopWidth, hc.border.width.thin);
    assert.strictEqual(css(panel).borderTopStyle, 'solid');

    await waitUntil(() => document.querySelector('.euiToolTip'));
    const tip = css('.euiToolTip');
    assert.strictEqual(tip.boxShadow, 'none', 'tooltip has no shadow');
    assert.strictEqual(tip.borderTopStyle, 'solid', 'tooltip border');

    state.contrast = false;
    await settled();
    assert.true(css(panel).filter.includes('drop-shadow'), 'shadow back without contrast mode');
    assert.notStrictEqual(css('.euiToolTip').boxShadow, 'none');
  });

  test('EuiInputPopover: attached, input width, min width and form max width', async function (assert) {
    const state = new State();

    await render(
      <template>
        <div style="width: 600px">
          <EuiInputPopover @isOpen={{true}} @closePopover={{state.noop}} data-default>
            <:input><input style="width: 200px; box-sizing: border-box" data-default-input /></:input>
            <:content><span data-input-content>Options</span></:content>
          </EuiInputPopover>
          <EuiInputPopover @isOpen={{true}} @fullWidth={{true}} @panelMinWidth={{300}} @closePopover={{state.noop}} data-full>
            <:input><input style="width: 100px; box-sizing: border-box" /></:input>
            <:content><span data-min-content>Options</span></:content>
          </EuiInputPopover>
        </div>
      </template>
    );

    await opened('input-content');
    const panel = panelOf('input-content');
    assert.strictEqual(css('[data-default]').maxWidth, light.components.forms.maxWidth, 'form max width');
    assert.strictEqual(css('[data-default]').display, 'block');
    assert.strictEqual(css('[data-full]').maxWidth, '100%', 'full width');
    assert.dom('.euiPopover__arrow', panel).doesNotExist();
    assert.strictEqual(css(panel).transform, 'none', 'attached panels do not slide');
    assert.strictEqual(css(panel).paddingTop, euiPaddingSize(lightContext, 's'), 'padding s by default');
    assert.strictEqual(panel.style.inlineSize, '200px', 'as wide as the input');
    await opened('min-content');
    assert.strictEqual(panelOf('min-content').style.inlineSize, '300px', '@panelMinWidth');

    const inputBox = el('[data-default-input]').getBoundingClientRect();
    const box = panel.getBoundingClientRect();
    assert.true(box.top >= inputBox.bottom, 'below the input');
    assert.true(Math.abs(box.left - inputBox.left) < 1, 'aligned with the input');
  });

  test('EuiToolTip: Borealis styles, arrow, title, z-index and anchor display', async function (assert) {
    await render(
      <template>
        <EuiToolTip @title="Title" @content="Tip text" @position="bottom" @isShown={{true}} @display="block">
          <button type="button" data-tip-anchor>anchor</button>
        </EuiToolTip>
      </template>
    );

    await waitUntil(() => document.querySelector('.euiToolTip'));
    const tip = el('.euiToolTip');
    const style = css(tip);
    assert.dom(tip).hasClass('euiToolTipPopover').hasAttribute('role', 'tooltip');
    assert.strictEqual(style.backgroundColor, rgb(light.components.tooltipBackground));
    assert.strictEqual(style.color, rgb(light.colors.textGhost));
    assert.strictEqual(style.borderTopLeftRadius, light.border.radius.control);
    assert.strictEqual(style.paddingTop, light.size.s);
    assert.strictEqual(style.maxWidth, '256px');
    assert.strictEqual(style.zIndex, String(light.levels.toast), 'z-index from theme levels');
    assert.strictEqual(style.position, 'absolute');
    assert.strictEqual(style.pointerEvents, 'none');
    assert.true(Math.abs(parseFloat(style.fontSize) - rootFontSize() * 0.8571) < 0.1, 'xs font size');

    const title = css(el('.euiToolTip__title', tip));
    assert.strictEqual(title.fontWeight, String(light.font.weight.bold));
    assert.strictEqual(title.borderBottomColor, rgb(light.components.tooltipBorder));

    const position = tip.dataset['position'] as keyof typeof ARROW_ROTATION;
    assert.ok(position, 'data-position');
    const arrow = css(el('.euiToolTip__arrow', tip));
    assert.strictEqual(arrow.width, light.size.m, '12px arrow');
    assert.strictEqual(rotation(arrow.transform), ARROW_ROTATION[position], `arrow rotated for ${position}`);

    const tipBox = tip.getBoundingClientRect();
    const anchorBox = el('[data-tip-anchor]').getBoundingClientRect();
    if (position === 'bottom') assert.true(tipBox.top > anchorBox.bottom, 'below the anchor');

    assert.dom('.euiToolTipAnchor').hasStyle({ display: 'block' }).doesNotHaveAttribute('role', 'the anchor is not a tooltip');

    const guard = euiToolTipStyles(lightContext).euiToolTip.styles;
    assert.true(guard.includes('prefers-reduced-motion: no-preference'), 'fade in only when motion is allowed');
    assert.strictEqual(style.animationName !== 'none', canAnimate());
  });

  test('EuiToolTip behavior: show/hide, aria-describedby, Escape, one at a time', async function (assert) {
    await render(
      <template>
        <EuiToolTip @content="First" class="first-tip">
          <button type="button" aria-describedby="existing" data-first>first</button>
        </EuiToolTip>
        <EuiToolTip @content="Second" class="second-tip">
          <button type="button" data-second>second</button>
        </EuiToolTip>
        <EuiToolTip @content="Visual" @disableScreenReaderOutput={{true}} class="visual-tip">
          <button type="button" data-visual>visual</button>
        </EuiToolTip>
        <span id="existing">existing description</span>
      </template>
    );

    assert.dom('[data-first]').hasAttribute('aria-describedby', 'existing');
    await triggerEvent(el('[data-first]').parentElement!, 'mouseover');
    await waitUntil(() => document.querySelector('.first-tip'));
    const id = el('.first-tip').id;
    assert.dom('[data-first]').hasAttribute('aria-describedby', `${id} existing`, 'tooltip id first, existing ids kept');
    assert.dom(el('[data-first]').parentElement).hasAttribute('id', `${id}-wrapper`);

    await triggerEvent(el('[data-second]').parentElement!, 'mouseover');
    await waitUntil(() => document.querySelector('.second-tip'));
    await waitUntil(() => !document.querySelector('.first-tip'));
    assert.dom('.first-tip').doesNotExist('showing a tooltip hides the other');
    assert.dom('[data-first]').hasAttribute('aria-describedby', 'existing', 'restored when hidden');
    assert.strictEqual(el('.second-tip').style.animationName, 'none', 'a replacing tooltip skips the fade in');
    assert.dom('[data-second]').hasAttribute('aria-describedby', el('.second-tip').id);

    await triggerKeyEvent(el('[data-second]').parentElement!, 'keydown', 'Escape');
    await waitUntil(() => !document.querySelector('.second-tip'));
    assert.dom('[data-second]').doesNotHaveAttribute('aria-describedby', 'Escape hides it');

    await triggerEvent(el('[data-visual]').parentElement!, 'mouseover');
    await waitUntil(() => document.querySelector('.visual-tip'));
    assert.dom('[data-visual]').doesNotHaveAttribute('aria-describedby', '@disableScreenReaderOutput');
    assert.dom(el('[data-visual]').parentElement).doesNotHaveAttribute('id');
    await triggerEvent(el('[data-visual]').parentElement!, 'mouseout');
    await waitUntil(() => !document.querySelector('.visual-tip'));
  });

  test('EuiIconTip: focusable icon anchor described by its tooltip', async function (assert) {
    await render(<template><EuiIconTip @content="Explains" @ariaLabel="Help" /></template>);

    assert.dom('.euiToolTipAnchor svg').hasAttribute('tabindex', '0').hasAttribute('aria-label', 'Help');
    await triggerEvent('.euiToolTipAnchor', 'mouseover');
    await waitUntil(() => document.querySelector('.euiToolTip'));
    assert.dom('.euiToolTipAnchor svg').hasAttribute('aria-describedby', el('.euiToolTip').id);
  });

  test('EuiContextMenuItem: list item layout, colors, disabled, icon, arrow and reactive args', async function (assert) {
    const state = new State();

    await render(
      <template>
        <EuiContextMenuPanel>
          <EuiContextMenuItem @icon="copy" @color={{state.color}} @disabled={{state.disabled}} data-item>Copy</EuiContextMenuItem>
          <EuiContextMenuItem @icon="trash" @color="danger" data-danger>Delete</EuiContextMenuItem>
          <EuiContextMenuItem @disabled={{true}} @color="danger" data-disabled>Disabled</EuiContextMenuItem>
          <EuiContextMenuItem @hasPanel={{true}} @href="#more" data-link>More</EuiContextMenuItem>
        </EuiContextMenuPanel>
      </template>
    );

    const item = el('[data-item]');
    const style = css(item);
    assert.dom(item).hasClass('euiContextMenuItem').hasClass('euiListItemLayout');
    assert.strictEqual(style.display, 'flex');
    assert.strictEqual(style.paddingInlineStart, light.size.s);
    assert.strictEqual(style.paddingInlineEnd, light.size.s);
    assert.strictEqual(style.borderTopLeftRadius, light.border.radius.control);
    assert.strictEqual(style.color, rgb(light.colors.textParagraph));
    assert.strictEqual(style.cursor, 'pointer');
    assert.strictEqual(style.backgroundColor, 'rgba(0, 0, 0, 0)', 'no UA button face');
    assert.strictEqual(style.borderTopStyle, 'none');
    assert.true(Math.abs(parseFloat(style.fontSize) - rootFontSize()) < 0.1, 'font size s (1rem)');
    assert.strictEqual(style.width, css(el('.euiContextMenuPanel__list')).width, 'full width');

    const content = css(el('.euiListItemLayout__content', item));
    assert.strictEqual(content.gap, light.size.s);
    assert.strictEqual(css(el('.euiListItemLayout__prepend', item)).flexShrink, '0');
    assert.dom('.euiListItemLayout__prepend .euiContextMenu__icon', item).exists();
    const text = css(el('.euiContextMenuItem__text', item));
    assert.strictEqual(text.flexGrow, '1');
    assert.strictEqual(text.overflow, 'hidden');
    assert.strictEqual(text.paddingTop, '6px', 'text padding: xs + xxs');

    assert.strictEqual(css('[data-danger]').color, rgb(light.colors.textDanger), 'danger color');
    assert.strictEqual(css('[data-disabled]').color, rgb(light.colors.textDisabled), 'disabled wins over the color');
    assert.strictEqual(css('[data-disabled]').cursor, 'not-allowed');
    assert.dom('[data-disabled]').isDisabled();

    assert.dom('[data-link]').hasTagName('a').hasAttribute('href', '#more');
    assert.dom('.euiListItemLayout__append .euiContextMenu__arrow', el('[data-link]')).exists();
    assert.strictEqual(css(el('.euiListItemLayout__append', el('[data-link]'))).alignSelf, 'auto');

    state.color = 'danger';
    await settled();
    assert.strictEqual(el('[data-item]'), item, 'same element after @color change');
    assert.strictEqual(css(item).color, rgb(light.colors.textDanger));
    state.disabled = true;
    await settled();
    assert.strictEqual(css(el('[data-item]')).color, rgb(light.colors.textDisabled));
  });

  test('EuiContextMenu: root, panels, menu roles, separators and back button', async function (assert) {
    const panels = [
      {
        id: 0,
        title: 'Options',
        items: [
          { name: 'Share', icon: 'share', panel: 1 },
          { isSeparator: true as const },
          { name: 'Delete', icon: 'trash', color: 'danger', toolTipContent: 'Cannot be undone' }
        ]
      },
      { id: 1, title: 'Share', items: [{ name: 'Copy link', icon: 'link' }] }
    ];

    await render(<template><EuiContextMenu @panels={{panels}} @initialPanelId={{0}} /></template>);

    const menu = css('.euiContextMenu');
    assert.strictEqual(menu.width, `${light.base * 16}px`, 'upstream panel width');
    assert.strictEqual(menu.overflow, 'hidden');
    assert.strictEqual(menu.borderTopLeftRadius, light.border.radius.panel);
    assert.strictEqual(menu.position, 'relative');
    assert.strictEqual(css('.euiContextMenuPanel').paddingTop, light.size.s);
    assert.strictEqual(css('.euiContextMenu__panel').position, 'absolute');

    const list = el('.euiContextMenuPanel__list');
    const title = el('.euiContextMenuPanelTitle h2');
    assert.dom(list).hasAttribute('role', 'menu').hasAttribute('aria-labelledby', title.id);
    assert.dom('.euiContextMenuItem[role="menuitem"]').exists({ count: 2 });
    assert.dom('hr[role="separator"]').exists();
    const titleStyle = css(title);
    assert.strictEqual(titleStyle.fontWeight, String(light.font.weight.bold), 'title type xxs');
    assert.strictEqual(titleStyle.marginTop, '0px', 'heading reset');

    // tooltip on an item: right of it
    const withTip = document.querySelectorAll<HTMLElement>('.euiContextMenuItem')[1]!;
    await triggerEvent(withTip.closest('.euiToolTipAnchor')!, 'mouseover');
    await waitUntil(() => document.querySelector('.euiToolTip'));
    assert.dom(el('.euiToolTip')).hasText('Cannot be undone');
    assert.dom(withTip).hasAttribute('aria-describedby', el('.euiToolTip').id);

    await click('.euiContextMenuItem');
    await waitUntil(() => document.querySelectorAll('.euiContextMenuPanel').length === 1);
    const back = el('[data-test-subj="contextMenuPanelTitleButton"]');
    assert.dom(back).hasTagName('button').hasAttribute('aria-label', 'Close current panel:');
    assert.dom(back).hasAttribute('aria-labelledby', `${back.id} ${el('.euiContextMenuPanelTitle h2').id}`);
  });

  test('EuiContextMenu panel transitions: slide animations behind reduced-motion, keyboard after the slide', async function (assert) {
    const panels = [
      { id: 0, title: 'Options', items: [{ name: 'Share', panel: 1 }, { name: 'Edit' }] },
      { id: 1, title: 'Share', items: [{ name: 'Copy link' }, { name: 'Email' }] }
    ];

    await render(<template><EuiContextMenu @panels={{panels}} @initialPanelId={{0}} /></template>);

    const styles = euiContextMenuPanelStyles(lightContext);
    for (const direction of ['next', 'previous'] as const)
      for (const type of ['in', 'out'] as const)
        assert.true(
          styles[direction][type].styles.includes('prefers-reduced-motion: reduce'),
          `${direction}/${type} drops to 0s under reduced motion`
        );

    await triggerKeyEvent('.euiContextMenuPanel', 'keydown', 'ArrowDown');
    assert.dom('.euiContextMenuItem').isFocused();
    await triggerKeyEvent('.euiContextMenuPanel', 'keydown', 'ArrowRight');

    if (canAnimate()) {
      const sliding = document.querySelectorAll<HTMLElement>('.euiContextMenuPanel');
      assert.strictEqual(sliding.length, 2, 'both panels during the slide');
      assert.notStrictEqual(css(sliding[0]!).animationName, 'none', 'outgoing slides out');
      assert.notStrictEqual(css(sliding[1]!).animationName, 'none', 'incoming slides in');
      assert.strictEqual(css(sliding[1]!).animationDuration, `${parseFloat(light.animation.normal) / 1000}s`, 'animation.normal');
      assert.strictEqual(css(sliding[0]!).pointerEvents, 'none', 'no clicks while sliding');
    }

    await waitUntil(() => document.querySelectorAll('.euiContextMenuPanel').length === 1);
    assert.dom('.euiContextMenuPanelTitle h2').hasText('Share');
    assert.strictEqual(css('.euiContextMenuPanel').animationName, 'none', 'no animation once settled');
    await waitUntil(() => document.activeElement?.textContent?.trim() === 'Copy link');
    await triggerKeyEvent('.euiContextMenuPanel', 'keydown', 'ArrowDown');
    assert.dom(document.activeElement).hasText('Email');
    await triggerKeyEvent('.euiContextMenuPanel', 'keydown', 'ArrowLeft');
    await waitUntil(() => document.querySelectorAll('.euiContextMenuPanel').length === 1);
    assert.dom('.euiContextMenuPanelTitle h2').hasText('Options');
    await waitUntil(() => document.activeElement?.textContent?.trim() === 'Share');
    assert.dom(document.activeElement).hasText('Share', 'back on the item that opened the panel');
  });

  test('EuiContextMenu in dark mode inside a popover (portaled)', async function (assert) {
    const state = new State();
    const panels = [{ id: 0, items: [{ name: 'Dark item' }, { name: 'Off', disabled: true }] }];

    await render(
      <template>
        <EuiEmotionProvider @colorMode="dark">
          <EuiPopover @isOpen={{true}} @ownFocus={{false}} @panelPaddingSize="none" @closePopover={{state.noop}}>
            <:button><button type="button">menu</button></:button>
            <:content><EuiContextMenu @panels={{panels}} @initialPanelId={{0}} data-dark-menu /></:content>
          </EuiPopover>
        </EuiEmotionProvider>
        <EuiContextMenuItem data-light-item>Light</EuiContextMenuItem>
      </template>
    );

    await waitUntil(() => document.querySelector('[data-dark-menu]'));
    const items = document.querySelectorAll<HTMLElement>('[data-dark-menu] .euiContextMenuItem');
    assert.strictEqual(css(items[0]!).color, rgb(dark.colors.textParagraph), 'dark item text');
    assert.strictEqual(css(items[1]!).color, rgb(dark.colors.textDisabled), 'dark disabled text');
    assert.strictEqual(css('[data-light-item]').color, rgb(light.colors.textParagraph), 'sibling item stays light');
    assert.strictEqual(css(panelOf('dark-menu')).paddingTop, '0px');
  });
});
