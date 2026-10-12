import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { on } from '@ember/modifier';
import {
  click,
  focus,
  render,
  settled,
  triggerKeyEvent
} from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import EuiButtonEmpty from '#src/components/eui-button-empty.gts';
import EuiButtonIcon from '#src/components/eui-button-icon.gts';
import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';
import type { EuiColorMode } from '#src/utils/emotion/theme.ts';
import type { EuiBorealisOverrides } from '#src/utils/eui/theme.ts';
import type EuiConfigService from '#src/services/eui-config.ts';

const light = resolveBorealisTheme('light').euiTheme;
const dark = resolveBorealisTheme('dark').euiTheme;
const TRANSPARENT = 'rgba(0, 0, 0, 0)';

type ButtonTokens = Record<string, string>;
const buttons = (theme: typeof light) =>
  theme.components.buttons as unknown as ButtonTokens;

function capitalize(value: string) {
  return value.charAt(0).toUpperCase() + value.slice(1);
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

function el(root: Element, selector: string) {
  const element = root.querySelector(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

function style(root: Element, selector: string) {
  return getComputedStyle(el(root, selector));
}

/**
 * Measured layout box in CSS pixels. The ember-qunit container is scaled, so
 * client rects are divided by that scale to give real rendered dimensions.
 */
function box(element: Element) {
  const container = document.querySelector<HTMLElement>('#ember-testing')!;
  const scale = container.getBoundingClientRect().width / container.offsetWidth;
  const rect = element.getBoundingClientRect();
  return {
    width: Math.round((rect.width / scale) * 100) / 100,
    height: Math.round((rect.height / scale) * 100) / 100,
    left: rect.left / scale,
    right: rect.right / scale
  };
}

/** Empty-display text tokens (accentSecondary is contrast-adjusted upstream). */
function emptyColor(theme: typeof light, color: string) {
  return rgb(buttons(theme)[`textColor${capitalize(color)}`]!);
}

const EMPTY_COLORS = [
  'primary',
  'accent',
  'accentSecondary',
  'success',
  'warning',
  'danger',
  'text',
  'neutral',
  'risk',
  'ghost'
];
const SIZES = ['xs', 's', 'm'] as const;
const HEIGHTS = { xs: '24px', s: '32px', m: '40px' };

module(
  'Integration | Component | Borealis button empty/icon',
  function (hooks) {
    setupRenderingTest(hooks);

    test('EuiButtonEmpty color × size matrix uses upstream sizing and empty-color tokens', async function (assert) {
      const colors = EMPTY_COLORS;
      const sizes = SIZES;
      await render(
        <template>
          {{#each colors as |color|}}
            {{#each sizes as |size|}}
              <EuiButtonEmpty
                @color={{color}}
                @size={{size}}
                @iconType="plus"
                data-color={{color}}
                data-size={{size}}
              >Action</EuiButtonEmpty>
            {{/each}}
          {{/each}}
        </template>
      );
      const all = this.element.querySelectorAll<HTMLButtonElement>(
        'button.euiButtonEmpty'
      );
      assert.strictEqual(all.length, colors.length * sizes.length);
      const padding = { xs: '6px', s: '8px', m: '12px' };
      const textPadding = { xs: '2px', s: '4px', m: '4px' };
      const iconSize = { xs: '12px', s: '16px', m: '16px' };
      const fontSizes: Record<string, number> = {};
      for (const button of all) {
        const color = button.dataset.color!;
        const size = button.dataset.size as (typeof SIZES)[number];
        const label = `${color}/${size}`;
        const css = getComputedStyle(button);
        assert.strictEqual(css.height, HEIGHTS[size], `${label} height`);
        assert.strictEqual(
          css.paddingInlineStart,
          padding[size],
          `${label} padding`
        );
        assert.strictEqual(css.paddingInlineEnd, padding[size]);
        assert.strictEqual(css.boxSizing, 'border-box');
        assert.strictEqual(
          css.backgroundColor,
          TRANSPARENT,
          `${label} has no fill (scoped reset removes the UA button face)`
        );
        assert.strictEqual(css.borderTopStyle, 'none', `${label} no border`);
        assert.strictEqual(css.borderRadius, '8px', `${label} control radius`);
        assert.strictEqual(css.fontWeight, String(light.font.weight.medium));
        assert.true(css.fontFamily.includes('Inter'), `${label} Borealis font`);
        assert.strictEqual(css.textDecorationLine, 'none');
        if (color === 'accentSecondary') {
          assert.notStrictEqual(css.color, emptyColor(light, 'primary'));
          assert.notStrictEqual(css.color, TRANSPARENT);
        } else {
          assert.strictEqual(
            css.color,
            emptyColor(light, color === 'ghost' ? 'text' : color),
            `${label} color token`
          );
        }
        const text = getComputedStyle(el(button, '.euiButtonEmpty__text'));
        assert.strictEqual(text.paddingInlineStart, textPadding[size]);
        assert.strictEqual(text.textOverflow, 'ellipsis');
        const icon = box(el(button, '.euiButtonContent__icon'));
        assert.strictEqual(`${icon.width}px`, iconSize[size], `${label} icon`);
        fontSizes[size] = parseFloat(css.fontSize);
      }
      assert.true(
        fontSizes['xs']! < fontSizes['s']!,
        'xs uses the xs font scale'
      );
      assert.strictEqual(
        fontSizes['s'],
        fontSizes['m'],
        's and m share the s scale'
      );
    });

    test('EuiButtonEmpty flush sides, explicit icon size and class hooks', async function (assert) {
      await render(
        <template>
          <EuiButtonEmpty data-none>None</EuiButtonEmpty>
          <EuiButtonEmpty
            @flush="left"
            @iconType="plus"
            data-left
          >Left</EuiButtonEmpty>
          <EuiButtonEmpty @flush="right" data-right>Right</EuiButtonEmpty>
          <EuiButtonEmpty @flush="both" data-both>Both</EuiButtonEmpty>
          <EuiButtonEmpty
            @iconType="plus"
            @iconSize="l"
            @iconClasses="custom-icon"
            @contentClasses="custom-content"
            @textClasses="custom-text"
            data-custom
          >Custom</EuiButtonEmpty>
        </template>
      );
      const none = style(this.element, '[data-none]');
      assert.strictEqual(none.paddingInlineStart, '12px');
      assert.strictEqual(none.marginInlineEnd, '0px');
      assert.strictEqual(
        style(this.element, '[data-none] .euiButtonEmpty__content').gap,
        '4px'
      );
      for (const side of ['left', 'right', 'both']) {
        const css = style(this.element, `[data-${side}]`);
        assert.strictEqual(
          css.paddingInlineStart,
          '0px',
          `${side} flush start`
        );
        assert.strictEqual(css.paddingInlineEnd, '0px', `${side} flush end`);
        assert.strictEqual(
          style(this.element, `[data-${side}] .euiButtonEmpty__text`)
            .paddingInlineStart,
          '0px',
          `${side} text padding removed`
        );
        assert.strictEqual(
          style(this.element, `[data-${side}] .euiButtonEmpty__content`).gap,
          '8px',
          `${side} content gap`
        );
      }
      assert.strictEqual(
        style(this.element, '[data-left]').marginInlineEnd,
        '8px'
      );
      assert.strictEqual(
        style(this.element, '[data-left]').marginInlineStart,
        '0px'
      );
      assert.strictEqual(
        style(this.element, '[data-right]').marginInlineStart,
        '8px'
      );
      assert.strictEqual(
        style(this.element, '[data-both]').marginInlineStart,
        '0px'
      );
      assert.strictEqual(
        style(this.element, '[data-both]').marginInlineEnd,
        '0px'
      );

      assert
        .dom('[data-custom] .euiButtonEmpty__content.custom-content')
        .exists();
      assert
        .dom('[data-custom] .euiButtonEmpty__text.custom-text')
        .hasText('Custom');
      const icon = el(this.element, '[data-custom] svg.custom-icon');
      assert.strictEqual(box(icon).width, 24, 'l icon');
      assert.strictEqual(
        getComputedStyle(icon).fill,
        style(this.element, '[data-custom]').color,
        'icon inherits the button color'
      );
    });

    test('EuiButtonIcon display × color × size matrix and measured dimensions', async function (assert) {
      const displays = ['empty', 'base', 'fill'] as const;
      const colors = [
        'primary',
        'accent',
        'accentSecondary',
        'success',
        'warning',
        'danger',
        'text',
        'neutral',
        'risk'
      ];
      const sizes = SIZES;
      await render(
        <template>
          {{#each displays as |display|}}
            {{#each colors as |color|}}
              {{#each sizes as |size|}}
                <EuiButtonIcon
                  @display={{display}}
                  @color={{color}}
                  @size={{size}}
                  @iconType="gear"
                  aria-label="Settings"
                  data-display={{display}}
                  data-color={{color}}
                  data-size={{size}}
                />
              {{/each}}
            {{/each}}
          {{/each}}
        </template>
      );
      const all = this.element.querySelectorAll<HTMLButtonElement>(
        'button.euiButtonIcon'
      );
      assert.strictEqual(all.length, 81);
      const tokens = buttons(light);
      for (const button of all) {
        const { display, color, size } = button.dataset as Record<
          string,
          string
        >;
        const label = `${display}/${color}/${size}`;
        const css = getComputedStyle(button);
        const rect = box(button);
        const height = HEIGHTS[size as (typeof SIZES)[number]];
        assert.strictEqual(`${rect.width}px`, height, `${label} width`);
        assert.strictEqual(`${rect.height}px`, height, `${label} height`);
        assert.strictEqual(css.display, 'inline-flex');
        assert.strictEqual(css.borderRadius, '8px');
        assert.strictEqual(css.paddingInlineStart, '0px');
        const Color = capitalize(color!);
        if (display === 'empty') {
          assert.strictEqual(css.backgroundColor, TRANSPARENT, `${label} bg`);
          if (color !== 'accentSecondary') {
            assert.strictEqual(css.color, emptyColor(light, color!), label);
          }
        } else if (display === 'base') {
          assert.strictEqual(
            css.backgroundColor,
            rgb(tokens[`background${Color}`]!),
            `${label} bg`
          );
          assert.notStrictEqual(css.color, css.backgroundColor);
          assert.strictEqual(
            css.borderTopStyle,
            color === 'text' ? 'solid' : 'none',
            `${label} only base text has a border`
          );
        } else {
          assert.strictEqual(
            css.backgroundColor,
            rgb(tokens[`backgroundFilled${Color}`]!),
            `${label} bg`
          );
          assert.strictEqual(
            css.color,
            rgb(tokens[`textColorFilled${Color}`]!),
            `${label} fg`
          );
        }
        const icon = el(button, 'svg.euiButtonIcon__icon');
        assert.strictEqual(box(icon).width, 16, `${label} m icon`);
        assert.strictEqual(icon.getAttribute('aria-hidden'), 'true');
        assert.strictEqual(getComputedStyle(icon).fill, css.color);
        const iconRect = box(icon);
        assert.true(
          Math.abs(iconRect.left - rect.left - (rect.right - iconRect.right)) <
            0.5,
          `${label} icon centered`
        );
      }
    });

    test('EuiButtonIcon defaults, ghost, icon sizes and the size config', async function (assert) {
      const config = this.owner.lookup(
        'service:eui-config'
      ) as EuiConfigService;
      await render(
        <template>
          <EuiButtonIcon @iconType="gear" aria-label="Default" data-default />
          <EuiButtonIcon
            @iconType="gear"
            @color="ghost"
            aria-label="Ghost"
            data-ghost
          />
          <EuiButtonIcon
            @iconType="gear"
            @iconSize="s"
            aria-label="S"
            data-icon-s
          />
          <EuiButtonIcon
            @iconType="gear"
            @iconSize="l"
            @size="m"
            aria-label="L"
            data-icon-l
          />
          <EuiButtonIcon
            @iconType="gear"
            @size="s"
            aria-label="S"
            data-explicit
          />
        </template>
      );
      const def = el(this.element, '[data-default]');
      assert.strictEqual(box(def).height, 24, 'default size xs');
      assert.strictEqual(getComputedStyle(def).backgroundColor, TRANSPARENT);
      assert.strictEqual(
        getComputedStyle(def).color,
        emptyColor(light, 'primary')
      );
      assert.dom('[data-default]').doesNotHaveAttribute('aria-pressed');
      assert.dom('[data-default]').hasAttribute('type', 'button');
      assert.strictEqual(
        style(this.element, '[data-ghost]').color,
        emptyColor(light, 'text'),
        'ghost maps to text'
      );
      assert.strictEqual(box(el(this.element, '[data-icon-s] svg')).width, 12);
      assert.strictEqual(box(el(this.element, '[data-icon-l] svg')).width, 24);

      config.updateConfig({ 'euiButtonIcon.size': 'm' });
      await settled();
      assert.strictEqual(
        el(this.element, '[data-default]'),
        def,
        'config change restyles in place'
      );
      assert.strictEqual(box(def).height, 40, 'config size m');
      assert.strictEqual(
        box(el(this.element, '[data-explicit]')).height,
        32,
        'explicit @size wins over config'
      );
    });

    test('disabled and loading states for buttons and links', async function (assert) {
      class State {
        @tracked disabled = false;
        @tracked loading = false;
      }
      const state = new State();
      let clicks = 0;
      const onClick = () => clicks++;
      await render(
        <template>
          <EuiButtonEmpty
            @href="#docs"
            @target="_blank"
            @isDisabled={{state.disabled}}
            @isLoading={{state.loading}}
            @iconType="plus"
            data-empty
            {{on "click" onClick}}
          >Docs</EuiButtonEmpty>
          <EuiButtonIcon
            @href="#docs"
            @target="_blank"
            @display="base"
            @isDisabled={{state.disabled}}
            @isLoading={{state.loading}}
            @iconType="gear"
            aria-label="Docs"
            data-icon
            {{on "click" onClick}}
          />
          <EuiButtonEmpty
            @href="#x"
            @disabled={{true}}
            data-empty-native
          >X</EuiButtonEmpty>
          <EuiButtonIcon
            @href="#x"
            @disabled={{true}}
            @iconType="gear"
            aria-label="X"
            data-icon-native
          />
        </template>
      );
      const tokens = buttons(light);
      for (const sel of ['[data-empty]', '[data-icon]']) {
        assert
          .dom(`a${sel}`)
          .hasAttribute('href', '#docs')
          .hasAttribute('target', '_blank')
          .doesNotHaveAttribute('type')
          .doesNotHaveAttribute('disabled')
          .doesNotHaveAttribute('aria-pressed');
        assert.strictEqual(style(this.element, sel).cursor, 'pointer');
      }
      await click('[data-empty]');
      await click('[data-icon]');
      assert.strictEqual(clicks, 2);

      state.disabled = true;
      await settled();
      for (const sel of ['[data-empty]', '[data-icon]']) {
        assert
          .dom(`button${sel}`)
          .isDisabled()
          .doesNotHaveAttribute('href')
          .doesNotHaveAttribute('target')
          .hasAttribute('type', 'button');
        const css = style(this.element, sel);
        assert.strictEqual(css.cursor, 'not-allowed', `${sel} cursor`);
        assert.strictEqual(
          css.color,
          rgb(tokens['textColorDisabled']!),
          `${sel} color`
        );
        assert.strictEqual(css.opacity, '1');
        (el(this.element, sel) as HTMLButtonElement).click();
      }
      assert.strictEqual(
        clicks,
        2,
        'native disabled buttons do not dispatch click'
      );
      assert.strictEqual(
        style(this.element, '[data-icon]').backgroundColor,
        rgb(tokens['backgroundDisabled']!),
        'base display uses the disabled surface'
      );
      assert.strictEqual(
        style(this.element, '[data-empty]').backgroundColor,
        TRANSPARENT
      );
      for (const sel of ['[data-empty-native]', '[data-icon-native]']) {
        assert.dom(`button${sel}`).isDisabled().doesNotHaveAttribute('href');
      }

      state.disabled = false;
      state.loading = true;
      await settled();
      assert
        .dom('button[data-empty]')
        .isDisabled()
        .hasAttribute('aria-busy', 'true');
      assert.dom('[data-empty] .euiButtonContent__spinner').exists();
      assert.dom('[data-empty] .euiButtonContent__icon').doesNotExist();
      assert
        .dom('button[data-icon]')
        .isDisabled()
        .hasAttribute('aria-busy', 'true');
      assert.dom('[data-icon] .euiButtonIcon__icon').doesNotExist();
      const spinner = style(
        this.element,
        '[data-icon] .euiButtonIcon__spinner'
      );
      assert.strictEqual(
        spinner.borderBottomColor,
        rgb(tokens['textColorDisabled']!),
        'icon spinner border follows the disabled text color'
      );
      assert.strictEqual(spinner.width, '16px', 'spinner follows icon size m');
      assert.strictEqual(
        style(this.element, '[data-empty] .euiButtonContent__spinner')
          .borderTopColor,
        rgb(tokens['textColorDisabled']!)
      );

      state.loading = false;
      await settled();
      assert.dom('a[data-empty]').doesNotHaveAttribute('aria-busy');
      assert.dom('a[data-icon] svg.euiButtonIcon__icon').exists();
      await click('[data-icon]');
      assert.strictEqual(clicks, 3, 'modifier survives element replacement');
    });

    test('aria-pressed is a toggle only when @isSelected is defined, and only on buttons', async function (assert) {
      class State {
        @tracked selected: boolean | undefined = undefined;
      }
      const state = new State();
      await render(
        <template>
          <EuiButtonEmpty
            @isSelected={{state.selected}}
            data-empty
          >Bold</EuiButtonEmpty>
          <EuiButtonIcon
            @isSelected={{state.selected}}
            @iconType="gear"
            aria-label="Bold"
            data-icon
          />
          <EuiButtonEmpty
            @href="#a"
            @isSelected={{true}}
            data-link
          >A</EuiButtonEmpty>
          <EuiButtonIcon
            @href="#a"
            @isSelected={{true}}
            @iconType="gear"
            aria-label="A"
            data-icon-link
          />
        </template>
      );
      assert.dom('[data-empty]').doesNotHaveAttribute('aria-pressed');
      assert.dom('[data-icon]').doesNotHaveAttribute('aria-pressed');
      assert.dom('a[data-link]').doesNotHaveAttribute('aria-pressed');
      assert.dom('a[data-icon-link]').doesNotHaveAttribute('aria-pressed');
      const empty = el(this.element, '[data-empty]');
      state.selected = true;
      await settled();
      assert.dom('[data-empty]').hasAttribute('aria-pressed', 'true');
      assert.dom('[data-icon]').hasAttribute('aria-pressed', 'true');
      state.selected = false;
      await settled();
      assert.dom('[data-empty]').hasAttribute('aria-pressed', 'false');
      assert.dom('[data-icon]').hasAttribute('aria-pressed', 'false');
      assert.strictEqual(
        el(this.element, '[data-empty]'),
        empty,
        'same element'
      );
    });

    test('EuiButtonIcon warns without an accessible name and leaves aria-hidden buttons out of the tab order', async function (assert) {
      const original = console.warn;
      const warnings: string[] = [];
      console.warn = (message: string) => warnings.push(message);
      try {
        await render(
          <template>
            <EuiButtonIcon @iconType="gear" aria-label="Settings" data-label />
            <span id="external-label">Settings</span>
            <EuiButtonIcon
              @iconType="gear"
              aria-labelledby="external-label"
              data-labelledby
            />
            <EuiButtonIcon @iconType="gear" aria-hidden="true" data-hidden />
            <EuiButtonIcon
              @iconType="gear"
              aria-hidden="true"
              tabindex="0"
              data-hidden-tab
            />
          </template>
        );
        assert.deepEqual(
          warnings,
          [],
          'labelled and hidden buttons do not warn'
        );
        assert.dom('[data-hidden]').hasAttribute('tabindex', '-1');
        assert
          .dom('[data-hidden-tab]')
          .hasAttribute('tabindex', '0', 'caller tabindex wins');
        assert.dom('[data-label]').doesNotHaveAttribute('tabindex');

        await render(
          <template>
            <EuiButtonIcon @iconType="gear" data-unlabelled />
          </template>
        );
        assert.strictEqual(warnings.length, 1);
        assert.true(warnings[0]!.includes('aria-label or aria-labelledby'));
        assert.dom('[data-unlabelled]').doesNotHaveAttribute('tabindex');
      } finally {
        console.warn = original;
      }
    });

    test('native click, keyboard and focus ring', async function (assert) {
      let clicks = 0;
      let keys = 0;
      const onClick = () => clicks++;
      const onKey = () => keys++;
      await render(
        <template>
          <EuiButtonEmpty
            data-empty
            {{on "click" onClick}}
            {{on "keydown" onKey}}
          >Empty</EuiButtonEmpty>
          <EuiButtonIcon
            @iconType="gear"
            aria-label="Icon"
            data-icon
            {{on "click" onClick}}
            {{on "keydown" onKey}}
          />
          <form data-form>
            <EuiButtonIcon
              @type="submit"
              @iconType="gear"
              aria-label="Submit"
              data-submit
            />
          </form>
        </template>
      );
      let submits = 0;
      el(this.element, '[data-form]').addEventListener('submit', (event) => {
        event.preventDefault();
        submits++;
      });
      for (const sel of ['[data-empty]', '[data-icon]']) {
        await focus(sel);
        assert.dom(sel).isFocused();
        await triggerKeyEvent(sel, 'keydown', 'Enter');
        await click(sel);
        const node = el(this.element, sel);
        const css = getComputedStyle(node);
        if (node.matches(':focus-visible')) {
          assert.strictEqual(css.outlineStyle, 'auto');
          assert.strictEqual(css.outlineColor, rgb(light.focus.color));
        } else {
          assert.strictEqual(css.outlineStyle, 'none', `${sel} no mouse ring`);
        }
        assert.strictEqual(css.outlineOffset, '-1px', `${sel} centered ring`);
        assert.strictEqual(css.transitionDuration, '0s');
      }
      assert.strictEqual(keys, 2);
      assert.strictEqual(clicks, 2);
      (el(this.element, '[data-submit]') as HTMLButtonElement).click();
      assert.strictEqual(submits, 1, 'submit type submits its form');
    });

    test('reactive args restyle the existing element', async function (assert) {
      class State {
        @tracked color = 'primary';
        @tracked size: 'xs' | 's' | 'm' = 'm';
        @tracked flush: 'left' | 'right' | 'both' | undefined = undefined;
        @tracked display: 'empty' | 'base' | 'fill' = 'empty';
        @tracked iconSide: 'right' | undefined = undefined;
      }
      const state = new State();
      await render(
        <template>
          <EuiButtonEmpty
            @color={{state.color}}
            @size={{state.size}}
            @flush={{state.flush}}
            @iconSide={{state.iconSide}}
            @iconType="plus"
            data-empty
          >Empty</EuiButtonEmpty>
          <EuiButtonIcon
            @color={{state.color}}
            @size={{state.size}}
            @display={{state.display}}
            @iconType="gear"
            aria-label="Icon"
            data-icon
          />
        </template>
      );
      const empty = el(this.element, '[data-empty]');
      const icon = el(this.element, '[data-icon]');
      assert.strictEqual(getComputedStyle(empty).height, '40px');
      assert.strictEqual(
        style(this.element, '[data-empty] .euiButtonEmpty__content')
          .flexDirection,
        'row'
      );
      state.color = 'danger';
      state.size = 'xs';
      state.flush = 'both';
      state.display = 'fill';
      state.iconSide = 'right';
      await settled();
      assert.strictEqual(el(this.element, '[data-empty]'), empty, 'empty kept');
      assert.strictEqual(el(this.element, '[data-icon]'), icon, 'icon kept');
      assert.strictEqual(getComputedStyle(empty).height, '24px');
      assert.strictEqual(getComputedStyle(empty).paddingInlineStart, '0px');
      assert.strictEqual(
        getComputedStyle(empty).color,
        emptyColor(light, 'danger')
      );
      assert.strictEqual(
        style(this.element, '[data-empty] .euiButtonEmpty__content')
          .flexDirection,
        'row-reverse'
      );
      assert.strictEqual(
        box(el(this.element, '[data-empty] svg')).width,
        12,
        'xs forces the s icon'
      );
      assert.strictEqual(box(icon).height, 24);
      assert.strictEqual(
        getComputedStyle(icon).backgroundColor,
        rgb(buttons(light)['backgroundFilledDanger']!)
      );
    });

    test('nearest-provider light/dark, sibling isolation and JS-object token overrides', async function (assert) {
      class State {
        @tracked mode: EuiColorMode = 'light';
        @tracked overrides: EuiBorealisOverrides = {};
      }
      const state = new State();
      const own: EuiBorealisOverrides = {
        border: { radius: { control: '13px' } },
        colors: {
          LIGHT: { textDanger: '#123456' },
          DARK: { textDanger: '#ffccdd' }
        }
      };
      await render(
        <template>
          <EuiEmotionProvider
            @colorMode={{state.mode}}
            @borealisOverrides={{state.overrides}}
          >
            <EuiButtonEmpty data-parent-empty>Parent</EuiButtonEmpty>
            <EuiButtonIcon
              @display="fill"
              @iconType="gear"
              aria-label="Parent"
              data-parent-icon
            />
            <EuiEmotionProvider @borealisOverrides={{own}}>
              <EuiButtonEmpty
                @color="danger"
                data-child-empty
              >Child</EuiButtonEmpty>
              <EuiButtonIcon
                @display="fill"
                @iconType="gear"
                aria-label="Child"
                data-child-icon
              />
            </EuiEmotionProvider>
            <EuiEmotionProvider @colorMode="light">
              <EuiButtonEmpty data-fixed>Fixed</EuiButtonEmpty>
            </EuiEmotionProvider>
          </EuiEmotionProvider>
          <EuiEmotionProvider @colorMode="light">
            <EuiButtonEmpty data-sibling-empty>Sibling</EuiButtonEmpty>
            <EuiButtonIcon
              @display="fill"
              @iconType="gear"
              aria-label="Sibling"
              data-sibling-icon
            />
          </EuiEmotionProvider>
        </template>
      );
      const parentEmpty = el(this.element, '[data-parent-empty]');
      const parentIcon = el(this.element, '[data-parent-icon]');
      const lightFill = rgb(buttons(light)['backgroundFilledPrimary']!);
      const darkFill = rgb(buttons(dark)['backgroundFilledPrimary']!);
      assert.strictEqual(
        getComputedStyle(parentEmpty).color,
        emptyColor(light, 'primary')
      );
      assert.strictEqual(
        getComputedStyle(parentIcon).backgroundColor,
        lightFill
      );
      assert.strictEqual(
        style(this.element, '[data-child-empty]').color,
        'rgb(18, 52, 86)'
      );
      assert.strictEqual(
        style(this.element, '[data-child-icon]').borderRadius,
        '13px'
      );

      state.mode = 'dark';
      await settled();
      assert.strictEqual(
        el(this.element, '[data-parent-empty]'),
        parentEmpty,
        'no replacement'
      );
      assert.strictEqual(el(this.element, '[data-parent-icon]'), parentIcon);
      assert.strictEqual(
        getComputedStyle(parentEmpty).color,
        emptyColor(dark, 'primary')
      );
      assert.strictEqual(
        getComputedStyle(parentIcon).backgroundColor,
        darkFill
      );
      assert.strictEqual(
        style(this.element, '[data-child-icon]').backgroundColor,
        darkFill,
        'child inherits mode'
      );
      assert.strictEqual(
        style(this.element, '[data-child-empty]').color,
        'rgb(255, 204, 221)',
        'mode-specific override follows the inherited mode'
      );
      assert.strictEqual(
        style(this.element, '[data-fixed]').color,
        emptyColor(light, 'primary'),
        'fixed light island'
      );
      assert.strictEqual(
        style(this.element, '[data-sibling-empty]').color,
        emptyColor(light, 'primary')
      );
      assert.strictEqual(
        style(this.element, '[data-sibling-icon]').backgroundColor,
        lightFill,
        'sibling isolated'
      );

      state.overrides = { border: { radius: { control: '4px' } } };
      await settled();
      assert.strictEqual(getComputedStyle(parentIcon).borderRadius, '4px');
      assert.strictEqual(getComputedStyle(parentEmpty).borderRadius, '4px');
      assert.strictEqual(
        style(this.element, '[data-child-icon]').borderRadius,
        '13px',
        'nearest override wins'
      );
      assert.strictEqual(
        style(this.element, '[data-sibling-icon]').borderRadius,
        '8px',
        'sibling tokens isolated'
      );
    });

    test('high contrast borders and RTL icon side', async function (assert) {
      await render(
        <template>
          <EuiEmotionProvider @highContrastMode="preferred">
            <EuiButtonIcon
              @display="base"
              @iconType="gear"
              aria-label="Base"
              data-hc-base
            />
            <EuiButtonIcon
              @display="fill"
              @iconType="gear"
              aria-label="Fill"
              data-hc-fill
            />
            <EuiButtonEmpty data-hc-empty>Empty</EuiButtonEmpty>
          </EuiEmotionProvider>
          <EuiButtonIcon
            @display="base"
            @iconType="gear"
            aria-label="Std"
            data-std-base
          />
          <div dir="rtl">
            <EuiButtonEmpty @iconType="plus" data-rtl-start>Add</EuiButtonEmpty>
            <EuiButtonEmpty
              @iconType="plus"
              @iconSide="right"
              data-rtl-end
            >Add</EuiButtonEmpty>
            <EuiButtonEmpty @flush="left" data-rtl-flush>Flush</EuiButtonEmpty>
          </div>
        </template>
      );
      const hcBase = style(this.element, '[data-hc-base]');
      assert.strictEqual(
        hcBase.borderTopWidth,
        '1px',
        'base gets a contrast border'
      );
      assert.strictEqual(hcBase.borderTopStyle, 'solid');
      assert.strictEqual(
        style(this.element, '[data-hc-fill]').borderTopStyle,
        'solid'
      );
      assert.strictEqual(
        style(this.element, '[data-std-base]').borderTopStyle,
        'none',
        'standard contrast isolated'
      );
      assert.strictEqual(
        style(this.element, '[data-hc-empty]').borderTopStyle,
        'none',
        'empty relies on text color'
      );

      const rect = (sel: string) =>
        el(this.element, sel).getBoundingClientRect();
      const startIcon = rect('[data-rtl-start] .euiButtonContent__icon');
      const startText = rect('[data-rtl-start] .euiButtonEmpty__text');
      const endIcon = rect('[data-rtl-end] .euiButtonContent__icon');
      const endText = rect('[data-rtl-end] .euiButtonEmpty__text');
      assert.true(
        startIcon.left >= startText.right,
        'start icon sits right of text in RTL'
      );
      assert.true(
        endIcon.right <= endText.left,
        'end icon sits left of text in RTL'
      );
      const flush = style(this.element, '[data-rtl-flush]');
      assert.strictEqual(flush.marginInlineEnd, '8px');
      assert.strictEqual(
        flush.marginLeft,
        '8px',
        'logical end margin is physical left in RTL'
      );
    });
  }
);
