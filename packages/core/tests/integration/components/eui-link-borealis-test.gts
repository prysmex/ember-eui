import { tracked } from '@glimmer/tracking';
import {
  click,
  clearRender,
  focus,
  render,
  settled,
  triggerKeyEvent
} from '@ember/test-helpers';
import { setupRenderingTest } from 'ember-qunit';
import { module, test } from 'qunit';
import { get } from '@ember/helper';
import { on } from '@ember/modifier';
import EuiLink, {
  getSecureRelForTarget,
  isValidHref
} from '#src/components/eui-link.gts';
import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';
import type {
  EuiBorealisOverrides,
  EuiBorealisHighContrastMode
} from '#src/utils/eui/theme.ts';
import type { EuiColorMode } from '#src/utils/emotion/theme.ts';
import type { EuiLinkColor } from '#src/components/eui-link.gts';

const light = resolveBorealisTheme('light').euiTheme;
const dark = resolveBorealisTheme('dark').euiTheme;

function el(root: Element, selector: string) {
  const element = root.querySelector<HTMLElement>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

function style(root: Element, selector: string) {
  return getComputedStyle(el(root, selector));
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

// [color, resting token, hover/focus token]
const COLOR_TOKENS = [
  ['primary', 'textPrimary', 'textPrimary'],
  ['subdued', 'textSubdued', 'textSubdued'],
  ['success', 'textSuccess', 'textSuccess'],
  ['accent', 'textAccent', 'textAccent'],
  ['danger', 'textDanger', 'textDanger'],
  ['warning', 'textWarning', 'textWarning'],
  ['ghost', 'textGhost', 'textGhost'],
  ['text', 'textParagraph', 'textPrimary']
] as const;

module('Integration | Component | Borealis link', function (hooks) {
  setupRenderingTest(hooks);

  test('every latest color, for anchors and buttons, plus the upstream base styles', async function (assert) {
    await render(
      <template>
        {{#each COLOR_TOKENS as |entry|}}
          <EuiLink
            @href="#a"
            @color={{get entry 0}}
            data-anchor={{get entry 0}}
          >{{get entry 0}}</EuiLink>
          <EuiLink
            @color={{get entry 0}}
            data-button={{get entry 0}}
          >{{get entry 0}}</EuiLink>
        {{/each}}
        <EuiLink @href="#d" data-default>Default</EuiLink>
        <EuiLink @href="#u" @color="nonsense" data-unknown>Unknown</EuiLink>
      </template>
    );
    for (const [color, token] of COLOR_TOKENS) {
      for (const kind of ['anchor', 'button']) {
        const computed = style(this.element, `[data-${kind}="${color}"]`);
        assert.strictEqual(
          computed.color,
          rgb(light.colors[token]),
          `${kind} ${color} uses ${token}`
        );
      }
    }
    assert.strictEqual(
      style(this.element, '[data-default]').color,
      rgb(light.colors.textParagraph),
      'default color is upstream text (paragraph)'
    );
    assert.strictEqual(
      style(this.element, '[data-unknown]').color,
      rgb(light.colors.textParagraph),
      'unknown colors keep the base link color, as upstream'
    );

    const anchor = style(this.element, '[data-anchor="primary"]');
    assert.strictEqual(anchor.fontWeight, String(light.font.weight.medium));
    assert.strictEqual(anchor.textDecorationLine, 'underline');
    assert.strictEqual(anchor.textDecorationStyle, 'dotted');
    assert.strictEqual(anchor.textAlign, 'start', 'logical text alignment');
    assert.strictEqual(anchor.userSelect, 'text');
    assert.strictEqual(anchor.cursor, 'pointer');

    const button = style(this.element, '[data-button="primary"]');
    assert.strictEqual(button.backgroundColor, 'rgba(0, 0, 0, 0)', 'reset bg');
    assert.strictEqual(button.borderTopStyle, 'none', 'reset border');
    assert.strictEqual(button.paddingLeft, '0px', 'reset padding');
    assert.strictEqual(button.borderTopLeftRadius, '0px');
    assert.strictEqual(button.cursor, 'pointer');
    assert.strictEqual(button.textDecorationStyle, 'dotted');
    assert.strictEqual(button.fontWeight, String(light.font.weight.medium));
    assert.true(button.fontFamily.includes('Inter'), 'Borealis font family');
    assert.strictEqual(
      button.fontSize,
      getComputedStyle(this.element).fontSize,
      'button font size inherits'
    );
    assert
      .dom('.euiLink--primary, .euiLink--text, .euiLink-disabled')
      .doesNotExist('no legacy modifier classes');
    assert.dom('a.euiLink').exists({ count: 10 }, 'stable root class');
  });

  test('focus uses the interaction color, a solid underline and the upstream ring', async function (assert) {
    await render(
      <template>
        {{#each COLOR_TOKENS as |entry|}}
          <EuiLink
            @href="#f"
            @color={{get entry 0}}
            data-focus={{get entry 0}}
          >{{get entry 0}}</EuiLink>
        {{/each}}
        <EuiLink data-focus-button>Button</EuiLink>
      </template>
    );
    for (const [color, , interaction] of COLOR_TOKENS) {
      await focus(`[data-focus="${color}"]`);
      const computed = style(this.element, `[data-focus="${color}"]`);
      assert.strictEqual(
        computed.color,
        rgb(light.colors[interaction]),
        `${color} focus uses ${interaction}`
      );
      assert.strictEqual(computed.textDecorationStyle, 'solid');
      assert.strictEqual(
        computed.textDecorationThickness,
        light.border.width.thick,
        'thick underline on focus'
      );
      const anchor = el(this.element, `[data-focus="${color}"]`);
      if (anchor.matches(':focus-visible')) {
        assert.strictEqual(computed.outlineStyle, 'auto');
        assert.strictEqual(computed.outlineOffset, light.focus.width);
        assert.strictEqual(computed.outlineColor, rgb(light.focus.color));
      } else {
        assert.strictEqual(computed.outlineStyle, 'none');
      }
    }
    await focus('[data-focus-button]');
    assert.dom('[data-focus-button]').isFocused();
    assert.strictEqual(
      style(this.element, '[data-focus-button]').color,
      rgb(light.colors.textPrimary),
      'button link focus color'
    );
  });

  test('disabled semantics for buttons, anchors and javascript: URLs', async function (assert) {
    let clicks = 0;
    const onClick = () => clicks++;
    await render(
      <template>
        <div style="color: rgb(1, 2, 3); font-weight: 300">
          <EuiLink
            @disabled={{true}}
            @color="danger"
            {{on "click" onClick}}
            data-disabled-button
          >Off</EuiLink>
          <EuiLink
            @href="#here"
            @disabled={{true}}
            @target="_blank"
            {{on "click" onClick}}
            data-disabled-anchor
          >Off</EuiLink>
          {{! template-lint-disable no-invalid-link-text }}
          <EuiLink
            @href="  JavaScript:alert(1)"
            data-script
          >Script</EuiLink>
        </div>
      </template>
    );
    assert.dom('a').doesNotExist('no disabled anchors');
    assert
      .dom('[data-disabled-button]')
      .hasTagName('button')
      .isDisabled()
      .hasAttribute('type', 'button');
    assert
      .dom('[data-disabled-anchor]')
      .hasTagName('button')
      .isDisabled()
      .doesNotHaveAttribute('href')
      .doesNotHaveAttribute('target')
      .doesNotHaveAttribute('rel');
    assert.dom('[data-disabled-anchor] .euiLink__externalIcon').doesNotExist();
    assert
      .dom('[data-script]')
      .hasTagName('button')
      .isDisabled('javascript: links render as disabled buttons, as upstream')
      .doesNotHaveAttribute('href');

    for (const selector of [
      '[data-disabled-button]',
      '[data-disabled-anchor]',
      '[data-script]'
    ]) {
      const computed = style(this.element, selector);
      assert.strictEqual(computed.color, 'rgb(1, 2, 3)', `${selector} inherits color`);
      assert.strictEqual(computed.fontWeight, '300', 'inherits weight');
      assert.strictEqual(computed.textDecorationLine, 'none');
    }

    await click('[data-disabled-button]').catch(() => {});
    el(this.element, '[data-disabled-anchor]').click();
    assert.strictEqual(clicks, 0, 'disabled links do not fire clicks');
    el(this.element, '[data-disabled-button]').focus();
    assert.notStrictEqual(
      document.activeElement,
      el(this.element, '[data-disabled-button]'),
      'disabled links are not focusable'
    );
  });

  test('external links: secure rel, decorative icon and screen reader text', async function (assert) {
    await render(
      <template>
        <EuiLink
          @href="https://example.com"
          @target="_blank"
          data-blank
        >Out</EuiLink>
        <EuiLink @href="/same" data-plain>Same</EuiLink>
        <EuiLink
          @href="https://example.com"
          @target="_blank"
          @rel="nofollow noreferrer noopener"
          data-merged
        >Merge</EuiLink>
        <EuiLink
          @href="https://example.com"
          @external={{true}}
          data-external
        >External</EuiLink>
        <EuiLink
          @href="https://example.com"
          @target="_blank"
          @external={{false}}
          data-hidden
        >Hidden</EuiLink>
        <EuiLink
          @href="https://example.com"
          rel="me"
          data-attr-rel
        >Attr</EuiLink>
        <div dir="rtl"><EuiLink
            @href="https://example.com"
            @target="_blank"
            data-rtl
          >RTL</EuiLink></div>
      </template>
    );
    assert
      .dom('[data-blank]')
      .hasAttribute('target', '_blank')
      .hasAttribute('rel', 'noopener noreferrer');
    assert.dom('[data-plain]').hasAttribute('rel', 'noreferrer');
    assert.dom('[data-plain]').doesNotHaveAttribute('target');
    assert.dom('[data-merged]').hasAttribute('rel', 'nofollow noopener noreferrer');
    assert
      .dom('[data-attr-rel]')
      .hasAttribute('rel', 'me', 'a rel attribute is the native escape hatch');
    assert.dom('[data-external]').hasAttribute('rel', 'noreferrer');
    assert.strictEqual(
      style(this.element, '[data-blank]').position,
      'relative',
      'upstream positions _blank links'
    );

    const icon = el(this.element, '[data-blank] .euiLink__externalIcon');
    // upstream 123 EuiIcon: role="presentation" makes it decorative; it no
    // longer adds aria-hidden by default (EuiLink passes none, as upstream)
    assert.dom(icon).doesNotHaveAttribute('aria-hidden');
    assert.dom(icon).hasAttribute('role', 'presentation');
    assert.dom(icon).doesNotHaveAttribute('aria-label');
    const iconStyle = getComputedStyle(icon);
    assert.strictEqual(iconStyle.width, light.size.m, 'icon size s');
    assert.strictEqual(iconStyle.height, light.size.m);
    assert.strictEqual(iconStyle.marginLeft, light.size.xs, 'logical start margin');
    assert.strictEqual(
      iconStyle.fill,
      style(this.element, '[data-blank]').color,
      'icon uses the link color'
    );
    assert.strictEqual(
      getComputedStyle(el(this.element, '[data-rtl] .euiLink__externalIcon'))
        .marginRight,
      light.size.xs,
      'margin flips in RTL'
    );

    const sr = el(this.element, '[data-blank] .euiLink__screenReaderOnly');
    assert.strictEqual(
      sr.textContent?.trim(),
      '(external, opens in a new tab or window)'
    );
    assert.strictEqual(getComputedStyle(sr).position, 'absolute');
    assert.true(sr.getBoundingClientRect().width <= 1, 'visually hidden');
    assert.strictEqual(getComputedStyle(sr).overflow, 'hidden');
    assert.strictEqual(
      el(this.element, '[data-external] .euiLink__screenReaderOnly').textContent?.trim(),
      '(external)'
    );
    assert.dom('[data-external] .euiLink__externalIcon').exists();
    assert.dom('[data-hidden] .euiLink__externalIcon').doesNotExist();
    assert.dom('[data-hidden] .euiLink__screenReaderOnly').doesNotExist();
    assert.dom('[data-plain] .euiLink__externalIcon').doesNotExist();
    assert.dom('[data-blank]').hasText('Out (external, opens in a new tab or window)');

    assert.strictEqual(getSecureRelForTarget('_blank', 'noopener'), 'noopener noreferrer');
    assert.strictEqual(getSecureRelForTarget(undefined, ''), 'noreferrer');
    assert.true(isValidHref('https://example.com'));
    assert.true(isValidHref('#anchor'));
    assert.false(isValidHref('javascript:void(0)'));
    assert.false(isValidHref('\tjavascript:void(0)'));
  });

  test('arguments update reactively without replacing elements', async function (assert) {
    class State {
      @tracked color: EuiLinkColor = 'primary';
      @tracked target: string | undefined = undefined;
      @tracked external: boolean | undefined = undefined;
      @tracked href = '#one';
      @tracked type = 'button';
      @tracked disabled = false;
    }
    const state = new State();
    await render(
      <template>
        <EuiLink
          @href={{state.href}}
          @color={{state.color}}
          @target={{state.target}}
          @external={{state.external}}
          data-anchor
        >A</EuiLink>
        <EuiLink
          @color={{state.color}}
          @type={{state.type}}
          @disabled={{state.disabled}}
          data-button
        >B</EuiLink>
      </template>
    );
    const anchor = el(this.element, '[data-anchor]');
    const button = el(this.element, '[data-button]');
    assert.strictEqual(getComputedStyle(anchor).color, rgb(light.colors.textPrimary));

    state.color = 'danger';
    state.target = '_blank';
    state.href = '#two';
    state.type = 'submit';
    state.disabled = true;
    await settled();

    assert.strictEqual(el(this.element, '[data-anchor]'), anchor, 'anchor kept');
    assert.strictEqual(el(this.element, '[data-button]'), button, 'button kept');
    assert.strictEqual(getComputedStyle(anchor).color, rgb(light.colors.textDanger));
    assert
      .dom(anchor)
      .hasAttribute('href', '#two')
      .hasAttribute('rel', 'noopener noreferrer');
    assert.dom('[data-anchor] .euiLink__externalIcon').exists();
    assert.dom(button).isDisabled().hasAttribute('type', 'submit');
    assert.strictEqual(getComputedStyle(button).textDecorationLine, 'none');

    state.external = false;
    state.disabled = false;
    await settled();
    assert.dom('[data-anchor] .euiLink__externalIcon').doesNotExist();
    assert.dom(button).isNotDisabled();
    assert.strictEqual(getComputedStyle(button).color, rgb(light.colors.textDanger));
  });

  test('light/dark modes follow the nearest provider; siblings stay isolated', async function (assert) {
    class State {
      @tracked mode: EuiColorMode = 'light';
    }
    const state = new State();
    await render(
      <template>
        <EuiEmotionProvider @colorMode={{state.mode}}>
          <EuiLink @href="#p" data-parent>Parent</EuiLink>
          <EuiLink @color="primary" data-parent-button>Button</EuiLink>
          <EuiEmotionProvider>
            <EuiLink @href="#n" @color="success" data-nested>Nested</EuiLink>
          </EuiEmotionProvider>
          <EuiEmotionProvider @colorMode="light">
            <EuiLink @href="#l" data-fixed-light>Fixed</EuiLink>
          </EuiEmotionProvider>
        </EuiEmotionProvider>
        <EuiEmotionProvider @colorMode="light">
          <EuiLink @href="#s" data-sibling>Sibling</EuiLink>
        </EuiEmotionProvider>
      </template>
    );
    const parent = el(this.element, '[data-parent]');
    assert.strictEqual(getComputedStyle(parent).color, rgb(light.colors.textParagraph));

    state.mode = 'dark';
    await settled();

    assert.strictEqual(el(this.element, '[data-parent]'), parent, 'kept');
    assert.strictEqual(getComputedStyle(parent).color, rgb(dark.colors.textParagraph));
    assert.strictEqual(
      style(this.element, '[data-parent-button]').color,
      rgb(dark.colors.textPrimary)
    );
    assert.strictEqual(
      style(this.element, '[data-nested]').color,
      rgb(dark.colors.textSuccess),
      'nested provider inherits dark'
    );
    assert.strictEqual(
      style(this.element, '[data-fixed-light]').color,
      rgb(light.colors.textParagraph),
      'fixed light child is isolated'
    );
    assert.strictEqual(
      style(this.element, '[data-sibling]').color,
      rgb(light.colors.textParagraph),
      'outer sibling is isolated'
    );
    await focus('[data-parent]');
    assert.strictEqual(
      getComputedStyle(parent).color,
      rgb(dark.colors.textPrimary),
      'dark interaction color'
    );
  });

  test('native token overrides and contrast modes reach the link factory', async function (assert) {
    class State {
      @tracked overrides: EuiBorealisOverrides = {};
      @tracked contrast: EuiBorealisHighContrastMode = false;
    }
    const state = new State();
    const nestedOverrides: EuiBorealisOverrides = {
      colors: { LIGHT: { textParagraph: '#00aa00' } }
    };
    await render(
      <template>
        <EuiEmotionProvider
          @borealisOverrides={{state.overrides}}
          @highContrastMode={{state.contrast}}
        >
          <EuiLink @href="#t" data-text>Text</EuiLink>
          <EuiLink @href="#d" @color="danger" data-danger>Danger</EuiLink>
          <EuiEmotionProvider @borealisOverrides={{nestedOverrides}}>
            <EuiLink @href="#n" data-nested>Nested</EuiLink>
          </EuiEmotionProvider>
        </EuiEmotionProvider>
        <EuiLink @href="#o" data-outside>Outside</EuiLink>
      </template>
    );
    assert.strictEqual(
      style(this.element, '[data-nested]').color,
      'rgb(0, 170, 0)',
      'nested override applies'
    );

    state.overrides = {
      colors: { LIGHT: { textParagraph: '#123456', textDanger: '#654321' } },
      font: { weight: { medium: 600 } }
    };
    await settled();

    assert.strictEqual(style(this.element, '[data-text]').color, 'rgb(18, 52, 86)');
    assert.strictEqual(style(this.element, '[data-text]').fontWeight, '600');
    assert.strictEqual(style(this.element, '[data-danger]').color, 'rgb(101, 67, 33)');
    assert.strictEqual(
      style(this.element, '[data-nested]').color,
      'rgb(0, 170, 0)',
      'nearest override wins'
    );
    assert.strictEqual(
      style(this.element, '[data-outside]').color,
      rgb(light.colors.textParagraph),
      'overrides stay scoped'
    );

    for (const mode of ['preferred', 'forced'] as const) {
      el(this.element, '[data-text]').blur();
      state.overrides = {};
      state.contrast = mode;
      await settled();
      const contrast = resolveBorealisTheme('light', {}, mode).euiTheme;
      for (const [selector, token] of [
        ['[data-text]', 'textParagraph'],
        ['[data-danger]', 'textDanger']
      ] as const) {
        assert.strictEqual(
          style(this.element, selector).color,
          rgb(contrast.colors[token]),
          `${mode} contrast ${token}`
        );
      }
      await focus('[data-text]');
      assert.strictEqual(
        style(this.element, '[data-text]').color,
        rgb(contrast.colors.textPrimary),
        `${mode} contrast interaction color`
      );
    }

    await clearRender();
    assert.dom('.euiLink').doesNotExist('teardown');
  });

  test('attributes, events, blocks and keyboard access', async function (assert) {
    const events: string[] = [];
    const record = (name: string) => (event: Event) => {
      event.preventDefault();
      events.push(name);
    };
    const onSubmit = (event: Event) => {
      event.preventDefault();
      events.push('submit');
    };
    const onKey = (event: KeyboardEvent) => events.push(`key:${event.key}`);
    await render(
      <template>
        <form {{on "submit" onSubmit}}>
          <EuiLink
            @href="#anchor"
            id="docs-link"
            aria-label="Read the docs"
            title="Docs"
            data-test-subj="docs"
            class="extra"
            {{on "click" (record "anchor")}}
            {{on "keydown" onKey}}
          ><strong data-block>Docs</strong></EuiLink>
          <EuiLink
            @type="submit"
            aria-describedby="hint"
            data-submit
          >Submit</EuiLink>
          <EuiLink {{on "click" (record "button")}} data-action>Act</EuiLink>
        </form>
        <span id="hint">hint</span>
      </template>
    );
    assert
      .dom('#docs-link')
      .hasTagName('a')
      .hasClass('euiLink')
      .hasClass('extra')
      .hasAttribute('aria-label', 'Read the docs')
      .hasAttribute('title', 'Docs')
      .hasAttribute('data-test-subj', 'docs');
    assert.dom('#docs-link [data-block]').hasText('Docs', 'block content');

    await click('#docs-link');
    await click('[data-action]');
    assert
      .dom('[data-submit]')
      .hasAttribute('type', 'submit')
      .hasAttribute('aria-describedby', 'hint');
    await click('[data-submit]');
    assert.dom('[data-action]').hasAttribute('type', 'button', 'default type');

    await focus('#docs-link');
    assert.dom('#docs-link').isFocused('anchors are focusable');
    await triggerKeyEvent('#docs-link', 'keydown', 'Enter');
    await focus('[data-action]');
    assert.dom('[data-action]').isFocused('button links are focusable');
    assert.deepEqual(events, ['anchor', 'button', 'submit', 'key:Enter']);
    assert.strictEqual(el(this.element, '#docs-link').tabIndex, 0);
    assert.strictEqual(el(this.element, '[data-action]').tabIndex, 0);
  });
});
