import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import { array, hash } from '@ember/helper';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import { on } from '@ember/modifier';
import {
  blur,
  clearRender,
  click,
  focus,
  render,
  settled,
  triggerEvent,
  triggerKeyEvent,
  waitUntil
} from '@ember/test-helpers';

import EuiAspectRatio from '#src/components/eui-aspect-ratio.gts';
import EuiAutoSizer from '#src/components/eui-auto-sizer.gts';
import EuiCode from '#src/components/eui-code.gts';
import EuiCopy from '#src/components/eui-copy.gts';
import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import EuiHideFor from '#src/components/eui-hide-for.gts';
import EuiHighlight from '#src/components/eui-highlight.gts';
import EuiImage from '#src/components/eui-image.gts';
import EuiInnerText from '#src/components/eui-inner-text.gts';
import EuiLoadingChart from '#src/components/eui-loading-chart.gts';
import EuiLoadingContent from '#src/components/eui-loading-content.gts';
import EuiLoadingElastic from '#src/components/eui-loading-elastic.gts';
import EuiLoadingLogo from '#src/components/eui-loading-logo.gts';
import EuiMark from '#src/components/eui-mark.gts';
import EuiOverlayMask from '#src/components/eui-overlay-mask.gts';
import EuiProgress from '#src/components/eui-progress.gts';
import EuiScreenReaderOnly from '#src/components/eui-screen-reader-only.gts';
import EuiShowFor from '#src/components/eui-show-for.gts';
import EuiSkipLink from '#src/components/eui-skip-link.gts';
import screenReaderOnly from '#src/modifiers/screen-reader-only.ts';
import {
  euiLoadingChartBarStyles,
  euiLoadingElasticStyles,
  euiLoadingLogoStyles,
  euiProgressStyles,
  euiSkeletonTextStyles
} from '#src/utils/eui/styles.generated.ts';
import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';

import type { EuiBorealisHighContrastMode, EuiBorealisOverrides } from '#src/utils/eui/theme.ts';
import type { EuiColorMode } from '#src/utils/emotion/theme.ts';
import type { EuiProgressColor } from '#src/components/eui-progress.gts';

module('Integration | Component | utilities', function (hooks) {
  setupRenderingTest(hooks);

  test('EuiShowFor / EuiHideFor with "all" and "none"', async function (assert) {
    await render(
      <template>
        <EuiShowFor @sizes="all"><span class="show-all">a</span></EuiShowFor>
        <EuiShowFor @sizes="none"><span class="show-none">b</span></EuiShowFor>
        <EuiHideFor @sizes="all"><span class="hide-all">c</span></EuiHideFor>
        <EuiHideFor @sizes="none"><span class="hide-none">d</span></EuiHideFor>
      </template>
    );

    assert.dom('.show-all').exists();
    assert.dom('.show-none').doesNotExist();
    assert.dom('.hide-all').doesNotExist();
    assert.dom('.hide-none').exists();
  });

  test('EuiShowFor / EuiHideFor follow the current breakpoint', async function (assert) {
    // the test browser is 1440px wide, i.e. the "xl" breakpoint
    await render(
      <template>
        <EuiShowFor @sizes={{array "l" "xl"}}><span class="show-desktop">a</span></EuiShowFor>
        <EuiShowFor @sizes={{array "xs" "s"}}><span class="show-mobile">b</span></EuiShowFor>
        <EuiHideFor @sizes={{array "xs" "s"}}><span class="hide-mobile">c</span></EuiHideFor>
      </template>
    );

    assert.dom('.show-desktop').exists();
    assert.dom('.show-mobile').doesNotExist();
    assert.dom('.hide-mobile').exists();
  });

  test('EuiAutoSizer yields the size of its parent', async function (assert) {
    await render(
      <template>
        <div style="width: 300px; height: 120px;">
          <EuiAutoSizer as |childStyle|>
            <span class="sized-width">{{childStyle.width}}</span>
            <span class="sized-height">{{childStyle.height}}</span>
          </EuiAutoSizer>
        </div>
      </template>
    );

    await waitUntil(() => document.querySelector('.sized-width')?.textContent?.trim() === '300px');
    assert.dom('.sized-width').hasText('300px');
    assert.dom('.sized-height').hasText('120px');
  });

  test('EuiInnerText yields the text of the referenced element', async function (assert) {
    await render(
      <template>
        <EuiInnerText as |setRef innerText|>
          <span {{didInsert setRef}}>Visible text</span>
          <span class="copy-of-text">{{innerText}}</span>
        </EuiInnerText>
      </template>
    );

    
    assert.dom('.copy-of-text').hasText('Visible text');
  });

  test('EuiCopy copies the text and changes the tooltip', async function (assert) {
    const original = document.execCommand;
    const copied: string[] = [];

    document.execCommand = ((command: string) => {
      copied.push(command);

      return true;
    }) as typeof document.execCommand;

    try {
      await render(
        <template>
          <EuiCopy @textToCopy="secret" @beforeMessage="Click to copy" @afterMessage="Copied!" as |copy|>
            <button type="button" class="copy-button" {{on "click" copy}}>Copy</button>
          </EuiCopy>
        </template>
      );

      await triggerEvent('.euiToolTipAnchor', 'mouseover');
      await waitUntil(() => document.querySelector('.euiToolTip'));
      assert.dom('.euiToolTip', document.body).containsText('Click to copy');

      await click('.copy-button');
      assert.deepEqual(copied, ['copy']);
      assert.dom('.euiToolTip', document.body).containsText('Copied!');
    } finally {
      document.execCommand = original;
    }
  });

  test('EuiCode highlights inline code', async function (assert) {
    await render(<template><EuiCode @language="js">const answer = 42;</EuiCode></template>);

    await waitUntil(() => document.querySelector('code.euiCode .token'));
    assert.dom('code.euiCode').hasAttribute('data-code-language', 'js').hasText('const answer = 42;');
    assert.dom('code.euiCode .token.keyword').hasText('const');
  });

  test('EuiCode transparent background', async function (assert) {
    await render(<template><EuiCode @transparentBackground={{true}}>plain</EuiCode></template>);

    
    // Legacy `euiCode--transparentBackground` modifier class is gone; the
    // upstream slot is asserted on computed styles in the Borealis module below.
    assert.dom('code.euiCode').hasAttribute('data-code-language', 'text');
    assert.strictEqual(getComputedStyle(document.querySelector('code.euiCode')!).backgroundColor, 'rgba(0, 0, 0, 0)');
  });
});

const light = resolveBorealisTheme('light').euiTheme;
const dark = resolveBorealisTheme('dark').euiTheme;

function el(selector: string, root: ParentNode = document): HTMLElement {
  const element = root.querySelector<HTMLElement>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

function css(selector: string, pseudo?: string) {
  return getComputedStyle(el(selector), pseudo);
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

/** Normalize a background (which may carry alpha) through a probe. */
function bg(color: string) {
  const probe = document.createElement('span');
  probe.style.backgroundColor = color;
  document.body.appendChild(probe);
  const value = getComputedStyle(probe).backgroundColor;
  probe.remove();
  return value;
}

/**
 * Chrome's getComputedStyle ignores `::-webkit-progress-value`, so read the
 * declaration from the stylesheet rule that targets the element's pseudo.
 */
function pseudoRule(element: Element, pseudo: string, property: string): string | undefined {
  let found: string | undefined;
  const visit = (rules: CSSRuleList) => {
    for (const rule of rules) {
      if (rule instanceof CSSStyleRule) {
        for (const selector of rule.selectorText.split(',')) {
          const trimmed = selector.trim();
          if (!trimmed.endsWith(pseudo)) continue;
          try {
            if (element.matches(trimmed.slice(0, -pseudo.length))) {
              const value = rule.style.getPropertyValue(property);
              if (value) found = value;
            }
          } catch {
            // selectors this browser cannot match
          }
        }
      } else if (rule instanceof CSSMediaRule && matchMedia(rule.conditionText).matches) {
        visit(rule.cssRules);
      }
    }
  };
  for (const sheet of document.styleSheets) {
    try {
      visit(sheet.cssRules);
    } catch {
      // cross-origin sheets
    }
  }
  return found;
}

const canAnimate = () => matchMedia('(prefers-reduced-motion: no-preference)').matches;

/**
 * Upstream `euiScreenReaderOnly`. On a button (skip link, modifier on a
 * button) EuiButton's min sizes still apply, as they do upstream; the clip
 * keeps it invisible, so `exactSize` is only checked on plain elements.
 */
function assertHidden(assert: Assert, style: CSSStyleDeclaration, label: string, exactSize = true) {
  assert.strictEqual(style.position, 'absolute', `${label}: out of the layout`);
  if (exactSize) {
    assert.strictEqual(style.width, '1px', `${label}: 1px wide`);
    assert.strictEqual(style.height, '1px', `${label}: 1px high`);
  }
  assert.strictEqual(style.clipPath, 'inset(50%)', `${label}: clipped`);
  assert.strictEqual(style.overflow, 'hidden', `${label}: no overflow`);
  assert.strictEqual(style.marginTop, '-1px', `${label}: negative margin`);
  assert.strictEqual(style.left, '-10000px', `${label}: off screen`);
}

class State {
  @tracked size: 'xs' | 's' | 'm' | 'l' = 'm';
  @tracked color: EuiProgressColor = 'success';
  @tracked value = 20;
  @tracked mode: EuiColorMode = 'light';
  @tracked contrast: EuiBorealisHighContrastMode = false;
  @tracked overrides: EuiBorealisOverrides = {};
  @tracked show = true;
  @tracked location: 'above' | 'below' = 'above';
  @tracked width = 16;
  @tracked height = 9;
  @tracked search: string | string[] = 'apple';
}

module('Integration | Component | Borealis utilities', function (hooks) {
  setupRenderingTest(hooks);

  test('EuiScreenReaderOnly hides visually; showOnFocus reveals while focused; the modifier matches', async function (assert) {
    await render(
      <template>
        <EuiScreenReaderOnly data-sr>Sorted ascending</EuiScreenReaderOnly>
        <EuiScreenReaderOnly @showOnFocus={{true}} data-focus>
          <a href="#main" data-focus-link>Skip</a>
        </EuiScreenReaderOnly>
        <h2 {{screenReaderOnly}} data-modifier>Hidden heading</h2>
        <button type="button" {{screenReaderOnly true}} data-modifier-focus>Reveal</button>
      </template>
    );

    assert.dom('[data-sr]').hasClass('euiScreenReaderOnly').hasText('Sorted ascending');
    assertHidden(assert, css('[data-sr]'), 'component');
    assert.dom('[data-focus]').hasClass('euiScreenReaderOnly-showOnFocus').doesNotHaveClass('euiScreenReaderOnly');
    assertHidden(assert, css('[data-focus]'), 'showOnFocus at rest');
    assertHidden(assert, css('[data-modifier]'), 'modifier');
    assert.dom('[data-modifier]').hasClass('euiScreenReaderOnly');
    assertHidden(assert, css('[data-modifier-focus]'), 'modifier showOnFocus at rest', false);

    await focus('[data-focus-link]');
    let revealed = css('[data-focus]');
    assert.strictEqual(revealed.position, 'static', 'focus-within reveals the wrapper');
    assert.strictEqual(revealed.clipPath, 'none');
    await blur('[data-focus-link]');
    assertHidden(assert, css('[data-focus]'), 'hidden again after blur');

    await focus('[data-modifier-focus]');
    revealed = css('[data-modifier-focus]');
    assert.strictEqual(revealed.clipPath, 'none', 'modifier showOnFocus reveals on focus');
    assert.strictEqual(revealed.position, 'static');
  });

  test('EuiSkipLink is hidden until focused, positions itself and moves focus to the destination', async function (assert) {
    let clicks = 0;
    const onClick = (event: Event) => {
      clicks++;
      event.preventDefault();
    };
    await render(
      <template>
        <EuiSkipLink @destinationId="skip-target" @overrideLinkBehavior={{true}} data-static>Skip to content</EuiSkipLink>
        <EuiSkipLink @destinationId="skip-target" @position="fixed" @tabIndex={{-1}} data-fixed>Skip fixed</EuiSkipLink>
        <EuiSkipLink @destinationId="skip-target" @position="absolute" data-absolute>Skip absolute</EuiSkipLink>
        <EuiSkipLink @destinationId="nowhere" @fallbackDestination={{array ".missing" ".fallback-target"}} data-fallback {{on "click" onClick}}>Fallback</EuiSkipLink>
        <div id="skip-target">Main content</div>
        <section class="fallback-target"><button type="button" data-tabbable>Tabbable</button></section>
      </template>
    );

    assert.dom('[data-static]').hasTagName('a').hasClass('euiSkipLink').hasAttribute('href', '#skip-target').hasText('Skip to content');
    assertHidden(assert, css('[data-static]'), 'static skip link at rest', false);
    assert.strictEqual(css('[data-static]').transitionProperty, 'none', 'upstream disables transitions');

    await focus('[data-static]');
    const focused = css('[data-static]');
    assert.strictEqual(focused.clipPath, 'none', 'shown on focus');
    assert.strictEqual(focused.position, 'static');
    assert.strictEqual(focused.backgroundColor, rgb(light.colors.backgroundFilledPrimary), 'filled primary button');

    assert.dom('[data-fixed]').hasAttribute('tabindex', '0', 'a fixed link is always reachable');
    assert.strictEqual(css('[data-fixed]').position, 'fixed', 'position fixed wins over the hidden state');
    await focus('[data-fixed]');
    const fixed = css('[data-fixed]');
    assert.strictEqual(fixed.top, light.size.xs);
    assert.strictEqual(fixed.left, light.size.xs);
    assert.strictEqual(fixed.zIndex, String(Number(light.levels.header) + 1));

    await focus('[data-absolute]');
    assert.strictEqual(css('[data-absolute]').position, 'absolute', 'absolute on focus; caller positions it');

    await click('[data-static]');
    const target = el('#skip-target');
    assert.strictEqual(document.activeElement, target, 'destination receives focus');
    assert.strictEqual(target.getAttribute('tabindex'), '-1', 'non-focusable destination becomes focusable');
    await blur(target);
    assert.false(target.hasAttribute('tabindex'), 'and is restored on blur');

    await click('[data-fallback]');
    assert.strictEqual(clicks, 1, 'caller click handlers still run');
    assert.strictEqual(document.activeElement, el('.fallback-target'), 'first matching fallback is focused');
  });

  test('EuiProgress: sizes, colors, positions and reactive args update one element', async function (assert) {
    const state = new State();
    await render(
      <template>
        <EuiProgress @size={{state.size}} @color={{state.color}} data-indeterminate />
        <EuiProgress @max={{100}} @value={{state.value}} @size={{state.size}} @color={{state.color}} data-native />
        <div style="position: relative; height: 40px; border-radius: 6px">
          <EuiProgress @position="absolute" data-absolute />
        </div>
        <EuiProgress @position="fixed" data-fixed />
      </template>
    );

    const bar = el('[data-indeterminate]');
    const native = el('[data-native]') as HTMLProgressElement;
    assert.strictEqual(bar.tagName, 'DIV', 'indeterminate bars are divs');
    assert.strictEqual(native.tagName, 'PROGRESS', 'determinate bars are native progress elements');
    assert.dom(bar).hasClass('euiProgress');
    assert.strictEqual(getComputedStyle(bar).backgroundColor, rgb(light.colors.lightShade), 'track color');
    assert.strictEqual(getComputedStyle(bar).position, 'relative', 'static position');
    assert.strictEqual(getComputedStyle(bar, '::before').backgroundColor, rgb(light.colors.success), 'default color is success');
    assert.strictEqual(bg(pseudoRule(native, '::-webkit-progress-value', 'background-color')!), bg(light.colors.success));
    assert.strictEqual(getComputedStyle(native).width, getComputedStyle(native.parentElement!).width, 'native bars are full width');

    const heights = { xs: light.size.xxs, s: light.size.xs, m: light.size.s, l: light.size.m };
    for (const size of ['xs', 's', 'm', 'l'] as const) {
      state.size = size;
      await settled();
      assert.strictEqual(getComputedStyle(bar).height, heights[size], `indeterminate ${size}`);
      assert.strictEqual(getComputedStyle(native).height, heights[size], `native ${size}`);
    }

    for (const [color, token] of [
      ['primary', light.colors.primary],
      ['danger', light.colors.danger],
      ['subdued', light.colors.textSubdued],
      ['accentSecondary', light.colors.accentSecondary],
      ['vis3', light.colors.vis.euiColorVis3]
    ] as const) {
      state.color = color;
      await settled();
      assert.strictEqual(getComputedStyle(bar, '::before').backgroundColor, rgb(token), `indeterminate ${color}`);
      assert.strictEqual(bg(pseudoRule(native, '::-webkit-progress-value', 'background-color')!), bg(token), `native ${color}`);
    }

    state.color = '#c0ffee';
    state.value = 75;
    await settled();
    assert.strictEqual(getComputedStyle(bar).color, 'rgb(192, 255, 238)', 'custom colors set currentColor');
    assert.strictEqual(getComputedStyle(bar, '::before').backgroundColor, 'rgb(192, 255, 238)');
    assert.strictEqual(pseudoRule(native, '::-webkit-progress-value', 'background-color'), 'currentcolor');
    assert.strictEqual(getComputedStyle(native).color, 'rgb(192, 255, 238)');
    assert.strictEqual(native.value, 75, 'value updates');
    assert.strictEqual(el('[data-indeterminate]'), bar, 'indeterminate element was not replaced');
    assert.strictEqual(el('[data-native]'), native, 'native element was not replaced');

    const absolute = css('[data-absolute]');
    assert.strictEqual(absolute.position, 'absolute');
    assert.strictEqual(absolute.zIndex, String(Number(light.levels.content) + 1));
    assert.strictEqual(absolute.top, '0px');
    assert.strictEqual(absolute.backgroundColor, 'rgba(0, 0, 0, 0)', 'non-static bars have a transparent track');
    assert.strictEqual(absolute.borderTopLeftRadius, '6px', 'inherits the parent radius');
    const fixed = css('[data-fixed]');
    assert.strictEqual(fixed.position, 'fixed');
    assert.strictEqual(fixed.zIndex, String(Number(light.levels.header) + 1));

    const styles = euiProgressStyles(resolveBorealisTheme('light'), false);
    // Upstream animates by default and swaps the animation for static stripes under `reduce`.
    assert.true(styles.indeterminate.styles.includes('prefers-reduced-motion: reduce'), 'reduced motion gets stripes');
    const before = getComputedStyle(bar, '::before');
    if (canAnimate()) assert.notStrictEqual(before.animationName, 'none');
    else assert.strictEqual(before.animationName, 'none');
  });

  test('EuiProgress value semantics: label, value text and live region', async function (assert) {
    const state = new State();
    state.value = 70;
    await render(
      <template>
        <EuiProgress @max={{100}} @value={{state.value}} @valueText={{true}} @color="primary" data-percent>
          <:label>Upload</:label>
        </EuiProgress>
        <EuiProgress @max={{10}} @value={{3}} @label="Steps" @valueText="3 of 10" @size="l" @labelClasses="extra" data-string />
        <EuiProgress @max={{100}} @value={{40}} @color="#E7664C" data-custom>
          <:valueText>forty</:valueText>
        </EuiProgress>
        <EuiProgress @max={{100}} @value={{5}} aria-label="Own label" data-plain />
      </template>
    );
    // label/value text feed aria attributes after a microtask
    await waitUntil(() => el('[data-percent]').getAttribute('aria-valuetext') === '70%');

    const percent = el('[data-percent]');
    assert.dom(percent).hasAttribute('max', '100').hasAttribute('value', '70');
    assert.dom(percent).hasAria('label', 'Upload').hasAria('valuetext', '70%');
    const data = percent.previousElementSibling!.previousElementSibling as HTMLElement;
    assert.dom(data).hasClass('euiProgress__data');
    assert.dom('.euiProgress__label', data).hasText('Upload').hasAria('hidden', 'true');
    assert.dom('.euiProgress__valueText', data).hasText('70%').hasAria('hidden', 'true');
    assert.strictEqual(getComputedStyle(el('.euiProgress__valueText', data)).color, rgb(light.colors.textPrimary));
    assert.strictEqual(getComputedStyle(data).display, 'flex');
    const live = percent.previousElementSibling as HTMLElement;
    assert.dom(live).hasAttribute('aria-live', 'polite').hasAttribute('aria-atomic', 'true').hasText('Upload 70%');
    assertHidden(assert, getComputedStyle(live), 'live region');

    state.value = 90;
    await settled();
    await waitUntil(() => percent.getAttribute('aria-valuetext') === '90%');
    assert.dom(live).hasText('Upload 90%', 'live region follows the value');

    const stringData = el('[data-string]').previousElementSibling!.previousElementSibling as HTMLElement;
    assert.dom('.euiProgress__label', stringData).hasText('Steps');
    assert.dom('.euiProgress__valueText', stringData).hasText('3 of 10').hasClass('extra');
    assert.true(
      parseFloat(getComputedStyle(stringData).fontSize) > parseFloat(getComputedStyle(data).fontSize),
      'size l uses the s data font instead of xs'
    );
    assert.dom('[data-string]').hasAria('label', 'Steps').hasAria('valuetext', '3 of 10');

    const customText = el('[data-custom]').previousElementSibling!.previousElementSibling!.querySelector('.euiProgress__valueText')!;
    assert.dom(customText).hasText('forty');
    assert.notStrictEqual(getComputedStyle(customText).color, rgb(light.colors.textParagraph), 'custom colors get a contrast-adjusted text color');
    assert.dom('[data-custom]').hasAria('valuetext', 'forty');

    assert.dom('[data-plain]').hasAria('label', 'Own label', 'caller attributes win');
    assert.dom('[data-plain]').doesNotHaveAttribute('aria-valuetext');
    assert.strictEqual(el('[data-plain]').previousElementSibling!.textContent!.trim(), '5', 'live region announces the raw value');
  });

  test('loaders: dimensions, colors, labels and reduced-motion guards', async function (assert) {
    await render(
      <template>
        <EuiLoadingChart data-chart-m />
        <EuiLoadingChart @size="l" data-chart-l />
        <EuiLoadingChart @size="xl" @mono={{true}} aria-label="Loading chart" data-chart-xl />
        <EuiLoadingElastic @size="xl" data-elastic />
        <EuiLoadingLogo @logo="logoElastic" @size="l" data-logo />
        <div style="width: 400px"><EuiLoadingContent @lines={{3}} @singleLineClasses="extra" data-content /></div>
        <EuiLoadingContent @lines={{40}} data-many />
        <EuiLoadingContent @size="relative" data-relative style="font-size: 20px" />
      </template>
    );

    for (const [selector, height, width] of [
      ['[data-chart-m]', light.size.base, light.size.xxs],
      ['[data-chart-l]', light.size.l, light.size.xs],
      ['[data-chart-xl]', light.size.xl, light.size.s]
    ]) {
      const chart = el(selector!);
      assert.dom(chart).hasClass('euiLoadingChart').hasAttribute('role', 'progressbar');
      assert.strictEqual(getComputedStyle(chart).height, height, `${selector} height`);
      assert.strictEqual(getComputedStyle(chart).display, 'inline-flex');
      const bars = chart.querySelectorAll('.euiLoadingChart__bar');
      assert.strictEqual(bars.length, 4);
      assert.strictEqual(getComputedStyle(bars[0]!).width, width, `${selector} bar width`);
      bars.forEach((bar, index) =>
        assert.strictEqual(
          getComputedStyle(bar).backgroundColor,
          rgb((light.components as Record<string, string>)[`loadingChartMonoBackground${index}`]!),
          `bar ${index} uses the mono token`
        )
      );
    }
    assert.dom('[data-chart-m]').hasAria('label', 'Loading', 'default label');
    assert.dom('[data-chart-xl]').hasAria('label', 'Loading chart', 'caller label wins');

    assert.dom('[data-elastic]').hasClass('euiLoadingElastic').hasAttribute('role', 'progressbar').hasAria('label', 'Loading');
    assert.dom('[data-elastic] .euiIcon').exists();
    assert.strictEqual(css('[data-elastic]').display, 'inline-block');

    assert.dom('[data-logo]').hasClass('euiLoadingLogo').hasAttribute('role', 'progressbar');
    assert.dom('[data-logo] .euiLoadingLogo__icon .euiIcon').exists();
    assert.strictEqual(css('[data-logo]').position, 'relative');

    assert.dom('[data-content]').hasAttribute('role', 'progressbar').hasAria('label', 'Loading');
    assert.dom('[data-content] .euiLoadingContent__singleLine').exists({ count: 3 });
    assert.dom('[data-content] .euiLoadingContent__singleLine').hasClass('extra');
    assert.dom('[data-many] .euiLoadingContent__singleLine').exists({ count: 10 }, 'capped at 10 lines');
    const lines = document.querySelectorAll<HTMLElement>('[data-content] .euiLoadingContent__singleLine');
    assert.strictEqual(getComputedStyle(lines[0]!).width, '400px');
    assert.strictEqual(getComputedStyle(lines[2]!).width, '300px', 'last line is 75% wide');
    assert.strictEqual(getComputedStyle(lines[0]!).display, 'block');
    assert.strictEqual(getComputedStyle(lines[0]!).borderTopLeftRadius, light.border.radius.inline);
    assert.strictEqual(css('[data-relative] .euiLoadingContent__singleLine').height, '20px', 'relative lines are 1em');

    const context = resolveBorealisTheme('light');
    const guard = 'prefers-reduced-motion: no-preference';
    assert.true(euiLoadingChartBarStyles(context).euiLoadingChart__bar.styles.includes(guard));
    assert.true(euiLoadingElasticStyles.euiLoadingElastic.styles.includes(guard));
    assert.true(euiLoadingLogoStyles(context).euiLoadingLogo.styles.includes(guard));
    assert.true(euiSkeletonTextStyles(context).euiSkeletonText.styles.includes(guard));
    const bar = el('[data-chart-m] .euiLoadingChart__bar');
    const line = lines[0]!;
    if (canAnimate()) {
      assert.notStrictEqual(getComputedStyle(bar).animationName, 'none', 'bars animate');
      assert.notStrictEqual(getComputedStyle(line, '::after').animationName, 'none', 'skeleton shines');
    } else {
      assert.strictEqual(getComputedStyle(bar).animationName, 'none');
      assert.strictEqual(getComputedStyle(line).backgroundColor, rgb(light.colors.backgroundBaseSkeletonEdge));
    }
  });

  test('EuiOverlayMask: theme z-index levels, header location, body class and cleanup', async function (assert) {
    const state = new State();
    let maskRef: HTMLElement | undefined;
    const setRef = (element: HTMLElement) => (maskRef = element);
    await render(
      <template>
        {{#if state.show}}
          <EuiOverlayMask @headerZindexLocation={{state.location}} @maskRef={{setRef}} data-mask>
            <div class="mask-content">content</div>
          </EuiOverlayMask>
        {{/if}}
      </template>
    );

    const mask = el('[data-mask]');
    assert.strictEqual(mask.parentElement, document.body, 'rendered at the end of body');
    assert.strictEqual(maskRef, mask, '@maskRef receives the element');
    assert.dom(mask).hasClass('euiOverlayMask').hasAttribute('data-relative-to-header', 'above');
    let style = getComputedStyle(mask);
    assert.strictEqual(style.position, 'fixed');
    assert.strictEqual(style.zIndex, String(light.levels.mask));
    assert.strictEqual(style.display, 'flex');
    assert.strictEqual(style.alignItems, 'center');
    assert.strictEqual(style.backgroundColor, bg(light.components.overlayMaskBackground));
    assert.strictEqual(style.top, '0px');
    assert.dom(document.body).hasClass('euiBody-hasOverlayMask');
    assert.strictEqual(getComputedStyle(document.body).overflow, 'hidden', 'page scrolling is locked');

    state.location = 'below';
    await settled();
    assert.strictEqual(el('[data-mask]'), mask, 'same element');
    style = getComputedStyle(mask);
    assert.strictEqual(style.zIndex, String(light.levels.maskBelowHeader));
    assert.dom(mask).hasAttribute('data-relative-to-header', 'below');
    document.body.style.setProperty('--euiFixedHeadersOffset', '48px');
    assert.strictEqual(getComputedStyle(mask).top, '48px', 'below-header masks start under fixed headers');
    document.body.style.removeProperty('--euiFixedHeadersOffset');

    state.show = false;
    await settled();
    assert.dom('[data-mask]').doesNotExist();
    assert.dom(document.body).doesNotHaveClass('euiBody-hasOverlayMask', 'body class removed on teardown');
    assert.notStrictEqual(getComputedStyle(document.body).overflow, 'hidden', 'scroll lock released');
  });

  test('EuiOverlayMask: nested masks keep the body locked; no animation; contrast background', async function (assert) {
    const state = new State();
    await render(
      <template>
        <EuiEmotionProvider @highContrastMode="preferred">
          <EuiOverlayMask @hasAnimation={{false}} data-first />
          {{#if state.show}}<EuiOverlayMask data-second />{{/if}}
        </EuiEmotionProvider>
      </template>
    );

    const hc = resolveBorealisTheme('light', {}, 'preferred').euiTheme;
    assert.strictEqual(css('[data-first]').backgroundColor, bg(hc.components.overlayMaskBackgroundHighContrast));
    assert.strictEqual(css('[data-first]').animationName, 'none', '@hasAnimation={{false}}');
    assert.notStrictEqual(css('[data-second]').animationName, 'none', 'fades in by default');
    state.show = false;
    await settled();
    assert.dom(document.body).hasClass('euiBody-hasOverlayMask', 'one mask still open');
    assert.strictEqual(getComputedStyle(document.body).overflow, 'hidden');
    await clearRender();
    assert.dom(document.body).doesNotHaveClass('euiBody-hasOverlayMask');
  });

  test('EuiMark and EuiHighlight: colors, screen reader help text and matching', async function (assert) {
    const state = new State();
    await render(
      <template>
        <p style="color: rgb(1, 2, 3)"><EuiMark data-mark>match</EuiMark></p>
        <EuiMark @hasScreenReaderHelpText={{false}} data-quiet>quiet</EuiMark>
        <EuiHighlight @text="Apple and apple pie, pear" @search={{state.search}} @highlightAll={{true}} data-highlight />
        <EuiHighlight @text="Apple pie" @search="apple" @hasScreenReaderHelpText={{false}} data-first />
      </template>
    );

    const mark = css('[data-mark]');
    assert.strictEqual(mark.color, rgb(light.colors.textParagraph), 'overrides the browser mark color');
    assert.strictEqual(mark.backgroundColor, rgb(light.components.markBackground));
    assert.strictEqual(mark.fontWeight, String(light.font.weight.bold));
    const before = css('[data-mark]', '::before');
    assert.strictEqual(before.content, '" [highlight start] "');
    assert.strictEqual(css('[data-mark]', '::after').content, '" [highlight end] "');
    assertHidden(assert, before, 'help text');
    assert.strictEqual(css('[data-quiet]', '::before').content, 'none');

    const root = el('[data-highlight]');
    assert.dom('mark', root).exists({ count: 2 });
    state.search = ['pie', 'PEAR'];
    await settled();
    assert.strictEqual(el('[data-highlight]'), root, 'same element');
    assert.deepEqual(
      [...root.querySelectorAll('mark')].map((m) => m.textContent),
      ['pie', 'pear'],
      'an array highlights several terms'
    );
    assert.dom(root).hasText('Apple and apple pie, pear');
    assert.dom('[data-first] mark').exists({ count: 1 }).hasText('Apple');
    assert.strictEqual(css('[data-first] mark', '::before').content, 'none', 'passes hasScreenReaderHelpText');
  });

  test('EuiCode inline styles: code font, inline colors and transparent background', async function (assert) {
    await render(
      <template>
        <p style="font-size: 20px"><EuiCode @language="js" data-code>const a = 1;</EuiCode></p>
        <EuiCode @transparentBackground={{true}} data-transparent>plain</EuiCode>
      </template>
    );
    await waitUntil(() => document.querySelector('[data-code] .token'));

    const code = css('[data-code]');
    assert.true(code.fontFamily.includes('Roboto Mono'), 'code font family');
    assert.strictEqual(code.fontSize, '18px', '0.9em of the surrounding text');
    assert.strictEqual(code.fontWeight, String(light.font.weight.bold));
    assert.strictEqual(code.backgroundColor, rgb(light.components.codeInlineBackground));
    assert.strictEqual(code.color, rgb(light.components.codeInlineColor));
    assert.strictEqual(code.paddingLeft, '9px', '0.5em inline padding');
    assert.strictEqual(code.borderTopLeftRadius, light.border.radius.inline);
    assert.strictEqual(css('[data-transparent]').backgroundColor, 'rgba(0, 0, 0, 0)');
    assert.dom('[data-code] .token.keyword').hasText('const', 'syntax highlighting hooks unchanged');
  });

  test('EuiImage: sizes, shadow, margins, caption and full screen semantics', async function (assert) {
    const url = 'data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="400" height="200"></svg>';
    const calls: boolean[] = [];
    const onFullScreen = (value: boolean) => calls.push(value);
    await render(
      <template>
        <EuiImage @url={{url}} @alt="Small" @size="s" @wrapperProps={{hash data-small=true}} />
        <EuiImage @src={{url}} @alt="Custom" @size={{120}} @hasShadow={{true}} @margin="m" @wrapperProps={{hash data-custom=true}} />
        <EuiImage @url={{url}} @alt="Percent" @size="50%" @wrapperProps={{hash data-percent=true}} />
        <EuiImage @url={{url}} @alt="Original" @caption="A caption" @wrapperProps={{hash data-original=true}} />
        <EuiImage @url={{url}} @alt="Zoom" @caption="Zoomable" @allowFullScreen={{true}} @onFullScreen={{onFullScreen}} @wrapperProps={{hash data-zoom=true}} />
      </template>
    );

    assert.dom('[data-small]').hasTagName('figure').hasClass('euiImageWrapper');
    assert.strictEqual(css('[data-small]').marginTop, '0px', 'scoped figure reset');
    assert.strictEqual(css('[data-small] img').width, '100px');
    assert.dom('[data-small] img').hasClass('euiImage').hasAttribute('alt', 'Small');
    assert.strictEqual(css('[data-small] img').boxShadow, 'none', 'no shadow by default (upstream)');
    assert.strictEqual(css('[data-custom] img').maxWidth, '120px');
    assert.strictEqual(css('[data-custom] img').maxHeight, '120px');
    assert.notStrictEqual(css('[data-custom] img').boxShadow, 'none', '@hasShadow');
    assert.strictEqual(css('[data-custom]').marginTop, light.size.base, 'margin m');
    assert.strictEqual(css('[data-percent] img').maxWidth, '50%', 'CSS lengths are kept');
    assert.dom('[data-original]').hasAria('label', 'A caption');
    assert.dom('[data-original] figcaption').hasClass('euiImageCaption').hasText('A caption');
    assert.strictEqual(css('[data-original] figcaption').marginTop, light.size.xs);

    assert.dom('[data-zoom] button[data-test-subj="activateFullScreenButton"] img').exists();
    assert.dom('[data-zoom] button').includesText('Click to open this image in fullscreen mode');
    assert.strictEqual(css('[data-zoom] button').backgroundColor, 'rgba(0, 0, 0, 0)', 'scoped button reset');
    assert.strictEqual(css('[data-zoom] .euiImageButton__icon').opacity, '0', 'icon shows on hover/focus only');

    await click('[data-zoom] button');
    assert.deepEqual(calls, [true]);
    const overlay = el('[data-test-subj="fullScreenOverlayMask"]');
    assert.dom(overlay).hasClass('euiOverlayMask');
    assert.dom('figure.euiImageFullScreenWrapper', overlay).hasAria('label', 'Zoomable');
    assert.dom('[data-test-subj="deactivateFullScreenButton"]', overlay).includesText('Press Escape or click to close image fullscreen mode');
    assert.dom('figcaption', overlay).hasText('Zoomable');
    assert.strictEqual(getComputedStyle(el('figcaption', overlay)).color, rgb(light.colors.textGhost), 'caption on the mask');
    assert.true(
      Math.abs(parseFloat(getComputedStyle(el('img', overlay)).maxHeight) - window.innerHeight * 0.8) < 0.5,
      'full screen image is capped at 80vh'
    );
    await waitUntil(() => overlay.contains(document.activeElement));
    assert.true(overlay.contains(document.activeElement), 'focus is trapped in the full screen view');

    await triggerKeyEvent(el('[data-test-subj="deactivateFullScreenButton"]'), 'keydown', 'Escape');
    assert.dom('[data-test-subj="fullScreenOverlayMask"]').doesNotExist();
    assert.deepEqual(calls, [true, false]);
    assert.dom(document.body).doesNotHaveClass('euiBody-hasOverlayMask');
  });

  test('EuiAspectRatio keeps the ratio natively and updates in place', async function (assert) {
    const state = new State();
    await render(
      <template>
        <div style="width: 320px">
          <EuiAspectRatio @width={{state.width}} @height={{state.height}} data-ratio><iframe title="Video"></iframe></EuiAspectRatio>
          <EuiAspectRatio @width={{1}} @height={{1}} @maxWidth={{200}} data-square><div></div></EuiAspectRatio>
          <EuiAspectRatio @width={{2}} @height={{1}} @maxWidth="50%" data-half><div></div></EuiAspectRatio>
        </div>
      </template>
    );

    const ratio = el('[data-ratio]');
    assert.dom(ratio).hasClass('euiAspectRatio').doesNotHaveAttribute('style');
    // offset sizes: the test container may be zoomed, which scales client rects
    assert.deepEqual([ratio.offsetWidth, ratio.offsetHeight], [320, 180]);
    const frame = el('[data-ratio] iframe');
    assert.deepEqual([frame.offsetWidth, frame.offsetHeight], [320, 180], 'content fills the box');
    assert.deepEqual([el('[data-square]').offsetWidth, el('[data-square]').offsetHeight], [200, 200]);
    assert.deepEqual([el('[data-half]').offsetWidth, el('[data-half]').offsetHeight], [160, 80]);

    state.width = 4;
    state.height = 3;
    await settled();
    assert.strictEqual(el('[data-ratio]'), ratio, 'same element');
    assert.strictEqual(ratio.offsetHeight, 240);
  });

  test('EuiShowFor / EuiHideFor read breakpoints from the nearest theme', async function (assert) {
    const width = window.innerWidth;
    const current = (['xl', 'l', 'm', 's', 'xs'] as const).find((key) => light.breakpoint[key] <= width)!;
    const overrides: EuiBorealisOverrides = { breakpoint: { xs: 0, s: 1, m: 2, l: 3, xl: width + 1 } };
    await render(
      <template>
        <EuiShowFor @sizes={{array current}}><span data-default-show>a</span></EuiShowFor>
        <EuiEmotionProvider @borealisOverrides={{overrides}}>
          <EuiShowFor @sizes={{array current}}><span data-override-show>b</span></EuiShowFor>
          <EuiShowFor @sizes={{array "l"}}><span data-override-l>c</span></EuiShowFor>
          <EuiHideFor @sizes={{array "l"}}><span data-override-hide>d</span></EuiHideFor>
        </EuiEmotionProvider>
      </template>
    );

    assert.dom('[data-default-show]').exists(`default Borealis breakpoints put ${width}px in ${current}`);
    if (current !== 'l') assert.dom('[data-override-show]').doesNotExist('overridden breakpoints move the window to l');
    assert.dom('[data-override-l]').exists();
    assert.dom('[data-override-hide]').doesNotExist();
    await triggerEvent(window as unknown as Element, 'resize');
    assert.dom('[data-override-l]').exists('resize keeps the computed breakpoint');
  });

  test('light/dark nearest provider, sibling isolation and JS-object overrides', async function (assert) {
    const state = new State();
    state.mode = 'dark';
    const overrides: EuiBorealisOverrides = {
      colors: { LIGHT: { primary: '#663399' }, DARK: { primary: '#aa77dd' } },
      components: { LIGHT: { markBackground: '#ffee00' }, DARK: { markBackground: '#665500' } }
    };
    await render(
      <template>
        <EuiEmotionProvider @colorMode={{state.mode}} @borealisOverrides={{state.overrides}}>
          <EuiMark data-dark-mark>dark</EuiMark>
          <EuiCode data-dark-code>x</EuiCode>
          <EuiProgress @color="primary" data-dark-progress />
          <EuiLoadingChart data-dark-chart />
        </EuiEmotionProvider>
        <EuiEmotionProvider @colorMode="light">
          <EuiMark data-light-mark>light</EuiMark>
          <EuiProgress @color="primary" data-light-progress />
        </EuiEmotionProvider>
      </template>
    );

    assert.strictEqual(css('[data-dark-mark]').backgroundColor, rgb(dark.components.markBackground));
    assert.strictEqual(css('[data-dark-mark]').color, rgb(dark.colors.textParagraph));
    assert.strictEqual(css('[data-dark-code]').color, rgb(dark.components.codeInlineColor));
    assert.strictEqual(css('[data-dark-progress]').backgroundColor, rgb(dark.colors.lightShade));
    assert.strictEqual(css('[data-dark-chart] .euiLoadingChart__bar').backgroundColor, rgb(dark.components.loadingChartMonoBackground0));
    assert.strictEqual(css('[data-light-mark]').backgroundColor, rgb(light.components.markBackground), 'sibling stays light');
    assert.strictEqual(css('[data-light-progress]', '::before').backgroundColor, rgb(light.colors.primary));

    const mark = el('[data-dark-mark]');
    state.mode = 'light';
    state.overrides = overrides;
    await settled();
    assert.strictEqual(el('[data-dark-mark]'), mark, 'same element after mode/override change');
    assert.strictEqual(css('[data-dark-mark]').backgroundColor, 'rgb(255, 238, 0)', 'native component token override');
    assert.strictEqual(css('[data-dark-progress]', '::before').backgroundColor, 'rgb(102, 51, 153)', 'native color override');
    state.mode = 'dark';
    await settled();
    assert.strictEqual(css('[data-dark-mark]').backgroundColor, 'rgb(102, 85, 0)', 'mode-specific override');
    assert.strictEqual(css('[data-light-mark]').backgroundColor, rgb(light.components.markBackground), 'sibling unaffected');
  });

  test('high contrast modes reach the utilities', async function (assert) {
    const state = new State();
    state.contrast = 'preferred';
    await render(
      <template>
        <EuiEmotionProvider @highContrastMode={{state.contrast}}>
          <EuiMark data-mark>m</EuiMark>
          <EuiProgress @size="xs" data-progress />
          <EuiProgress @max={{10}} @value={{5}} data-native />
          <EuiCode data-code>c</EuiCode>
          <EuiLoadingChart data-chart />
        </EuiEmotionProvider>
      </template>
    );

    const hc = resolveBorealisTheme('light', {}, 'preferred').euiTheme;
    assert.strictEqual(css('[data-mark]').backgroundColor, rgb(hc.colors.backgroundFilledPrimary), 'filled mark');
    assert.strictEqual(css('[data-mark]').color, rgb(hc.colors.emptyShade));
    assert.strictEqual(css('[data-progress]').height, hc.size.xs, 'xs grows in high contrast');
    assert.strictEqual(css('[data-progress]').backgroundColor, rgb(hc.colors.emptyShade), 'high contrast track');
    assert.strictEqual(css('[data-native]').borderTopStyle, 'solid', 'native bar gets a border');
    assert.strictEqual(css('[data-chart] .euiLoadingChart__bar').backgroundColor, rgb(hc.colors.darkShade));

    state.contrast = 'forced';
    await settled();
    const forced = resolveBorealisTheme('light', {}, 'forced').euiTheme;
    assert.strictEqual(css('[data-code]').borderTopStyle, 'solid', 'forced contrast code border');
    assert.strictEqual(css('[data-chart] .euiLoadingChart__bar').backgroundColor, rgb(forced.colors.fullShade));
    assert.strictEqual(css('[data-progress]', '::before').borderTopStyle, 'solid', 'indeterminate bar uses a border');
  });
});
