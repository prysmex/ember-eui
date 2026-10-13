import { tracked } from '@glimmer/tracking';
import {
  click,
  fillIn,
  focus,
  render,
  settled,
  triggerEvent,
  triggerKeyEvent
} from '@ember/test-helpers';
import { setupRenderingTest } from 'ember-qunit';
import { module, test } from 'qunit';

import EuiDualRange from '#src/components/eui-dual-range.gts';
import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import EuiRange from '#src/components/eui-range.gts';
import EuiRangeThumb from '#src/components/eui-range-thumb.gts';
import { euiFontSize } from '#src/utils/eui/styles.generated.ts';
import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';

import type { EuiColorMode } from '#src/utils/emotion/context.ts';
import type { EuiBorealisOverrides } from '#src/utils/eui/theme.ts';

const light = resolveBorealisTheme('light').euiTheme;
const dark = resolveBorealisTheme('dark').euiTheme;
const hcLight = resolveBorealisTheme('light', {}, 'preferred').euiTheme;
const TRANSPARENT = 'rgba(0, 0, 0, 0)';
const XS_FONT = euiFontSize(resolveBorealisTheme('light'), 'xs').fontSize as string;
const noop = () => {};
const LEVELS = [
  { min: 0, max: 20, color: 'danger' },
  { min: 20, max: 60, color: 'warning' },
  { min: 60, max: 100, color: 'success' }
];
const CUSTOM_LEVELS = [
  { min: 0, max: 50, color: '#123456', className: 'custom-level' },
  { min: 50, max: 100, color: 'primary' }
];
const TICKS = [
  { label: '0kb', value: 0 },
  { label: '50kb', value: 50 },
  { label: '100 kilobytes', value: 100, accessibleLabel: 'one hundred' }
];

function el(root: Element | Document, selector: string) {
  const element = root.querySelector<HTMLElement>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

function all(root: Element | Document, selector: string) {
  return [...root.querySelectorAll<HTMLElement>(selector)];
}

function css(element: Element, pseudo?: string) {
  return getComputedStyle(element, pseudo);
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

/** Layout box relative to the track, in CSS pixels (ignores the test scale). */
function offsetBox(element: HTMLElement, container: HTMLElement) {
  const a = element.getBoundingClientRect();
  const b = container.getBoundingClientRect();
  const factor = b.width / container.offsetWidth || 1;
  const round = (value: number) => Math.round((value / factor) * 10) / 10;
  return {
    left: round(a.left - b.left),
    right: round(b.right - a.right),
    width: round(a.width),
    height: round(a.height)
  };
}

/**
 * Declarations of the inserted rules targeting `pseudo` (e.g. the native
 * `::-webkit-slider-thumb`) on `element`, in insertion order (later wins).
 */
function pseudoRules(element: Element, pseudo: string, state = '') {
  const result: Record<string, string> = {};
  const visit = (rules: CSSRuleList) => {
    for (const rule of rules) {
      if (rule instanceof CSSStyleRule) {
        const matches = rule.selectorText.split(',').some((selector) => {
          if (!selector.includes(pseudo) || !selector.includes(state)) return false;
          try {
            const plain = selector.replace(pseudo, '').split(state).join('').trim();
            return element.matches(plain);
          } catch {
            return false;
          }
        });
        if (!matches) continue;
        for (const property of rule.style) {
          result[property] = rule.style.getPropertyValue(property);
        }
        const text = rule.cssText;
        for (const shorthand of ['border', 'outline']) {
          const found = new RegExp(`(?:^|[;{ ])${shorthand}: ([^;]+);`).exec(text);
          if (found) result[shorthand] = found[1]!.trim();
        }
      } else if ('cssRules' in rule) {
        visit((rule as CSSGroupingRule).cssRules);
      }
    }
  };
  for (const sheet of document.styleSheets) {
    try {
      visit(sheet.cssRules);
    } catch {
      // cross-origin sheet
    }
  }
  return result;
}

function remPx(rem: string) {
  return (
    parseFloat(rem) * parseFloat(getComputedStyle(document.documentElement).fontSize)
  );
}

function near(assert: Assert, actual: number, expected: number, label: string, tolerance = 0.6) {
  assert.true(
    Math.abs(actual - expected) <= tolerance,
    `${label}: ${actual} ≈ ${expected}`
  );
}

module('Integration | Component | Borealis range family', function (hooks) {
  setupRenderingTest(hooks);

  test('EuiRange wrapper, track line and native slider use upstream sizes and colors', async function (assert) {
    await render(
      <template>
        <div style="width: 600px">
          <EuiRange @value={{40}} @onChange={{noop}} data-r="slider" />
        </div>
      </template>
    );
    const wrapper = el(this.element, '.euiRangeWrapper');
    assert.dom(wrapper).hasClass('euiRange');
    const ws = css(wrapper);
    assert.strictEqual(ws.display, 'flex');
    assert.strictEqual(ws.alignItems, 'center');
    assert.strictEqual(ws.height, '40px', 'form control height');
    assert.strictEqual(ws.maxWidth, '400px', 'form width');
    assert.strictEqual(wrapper.offsetWidth, 400);

    const track = el(this.element, '.euiRangeTrack');
    const ts = css(track);
    assert.strictEqual(ts.position, 'relative');
    assert.strictEqual(ts.flexGrow, '1');
    assert.strictEqual(ts.height, '40px', 'track fills the wrapper');
    const line = css(track, '::after');
    assert.strictEqual(line.content, '""');
    assert.strictEqual(line.position, 'absolute');
    assert.strictEqual(line.height, '6px');
    assert.strictEqual(line.top, '17px', 'calc(50% - 3px)');
    assert.strictEqual(line.width, '400px');
    assert.strictEqual(line.backgroundColor, rgb(light.colors.lightShade));
    assert.strictEqual(line.borderTopLeftRadius, light.border.radius.inline);

    const slider = el(this.element, '[data-r="slider"]');
    assert.dom(slider).hasClass('euiRangeSlider').hasAttribute('type', 'range');
    const ss = css(slider);
    assert.strictEqual(ss.appearance, 'none');
    assert.strictEqual(ss.backgroundColor, TRANSPARENT);
    assert.strictEqual(ss.width, '400px');
    assert.strictEqual(ss.height, '40px');
    assert.strictEqual(ss.marginLeft, '0px', 'scoped input reset');
    assert.strictEqual(ss.cursor, 'pointer');
    assert.strictEqual(ss.zIndex, '3', 'thumb z-index');
    assert.strictEqual(ss.position, 'relative');
    // Chrome exposes no computed style for vendor pseudo-elements: read the
    // matching inserted rules instead (Chrome drops the `::-moz-` copies)
    for (const pseudo of ['::-webkit-slider-thumb']) {
      const thumb = pseudoRules(slider, pseudo);
      assert.strictEqual(thumb['inline-size'], '16px', `${pseudo}: base size`);
      assert.strictEqual(thumb['block-size'], '16px');
      assert.strictEqual(thumb['border-top-left-radius'], '50%');
      assert.strictEqual(thumb['box-sizing'], 'border-box');
      assert.strictEqual(
        thumb['background-color'],
        `var(--euiRangeThumbColor, ${light.colors.darkShade})`,
        `${pseudo}: highlight color unless a level color is set`
      );
      assert.true(thumb['border']?.startsWith('2px solid'), `${pseudo}: thick border`);
    }
    assert.strictEqual(pseudoRules(slider, '::-webkit-slider-thumb')['appearance'], 'none');
    // Chrome's :focus-visible heuristic depends on earlier interactions in the
    // session, so read the `:focus-visible` rules rather than focusing
    const focused = pseudoRules(slider, '::-webkit-slider-thumb', ':focus-visible');
    assert.strictEqual(focused['background-color'], `var(--euiRangeThumbColor, ${light.colors.primary})`, 'focus-visible thumb');
    assert.strictEqual(focused['outline'], `2px solid var(--euiRangeThumbColor, ${light.colors.primary})`);
  });

  test('compressed, fullWidth and disabled', async function (assert) {
    await render(
      <template>
        <div style="width: 700px">
          <EuiRange @compressed={{true}} @value={{1}} @onChange={{noop}} data-r="c" />
          <EuiRange @fullWidth={{true}} @value={{1}} @onChange={{noop}} data-r="f" />
          <EuiRange @disabled={{true}} @showLabels={{true}} @value={{1}} @onChange={{noop}} data-r="d" />
        </div>
      </template>
    );
    const wrapperOf = (key: string) =>
      el(this.element, `[data-r="${key}"]`).closest<HTMLElement>('.euiRangeWrapper')!;
    assert.strictEqual(css(wrapperOf('c')).height, '32px', 'compressed height');
    assert.strictEqual(wrapperOf('f').offsetWidth, 700, 'full width');
    assert.strictEqual(css(wrapperOf('f')).maxWidth, '100%');
    const disabled = el(this.element, '[data-r="d"]');
    assert.true((disabled as HTMLInputElement).disabled);
    assert.strictEqual(css(disabled).cursor, 'not-allowed');
    assert.strictEqual(css(disabled.closest('.euiRangeTrack')!).opacity, '0.5');
    for (const label of all(wrapperOf('d'), '.euiRangeLabel')) {
      assert.strictEqual(css(label).opacity, '0.5', 'disabled label');
    }
  });

  test('min/max labels: xs text, gap towards the track, logical padding in RTL', async function (assert) {
    await render(
      <template>
        <EuiRange @showLabels={{true}} @min={{-10}} @max={{10}} @value={{0}} @onChange={{noop}} />
        <div dir="rtl">
          <EuiRange @showLabels={{true}} @value={{0}} @onChange={{noop}} data-r="rtl" />
        </div>
      </template>
    );
    const [min, max] = all(this.element, '.euiRangeLabel');
    assert.dom(min).hasText('-10');
    assert.dom(max).hasText('10');
    assert.strictEqual(min!.tagName, 'LABEL');
    near(assert, parseFloat(css(min!).fontSize), remPx(XS_FONT), 'xs font size', 0.1);
    assert.strictEqual(css(min!).paddingRight, '8px', 'min label gap before the track');
    assert.strictEqual(css(min!).paddingLeft, '0px');
    assert.strictEqual(css(max!).paddingLeft, '8px', 'max label gap after the track');
    const rtl = el(this.element, '[data-r="rtl"]').closest('.euiRangeWrapper')!;
    const [rtlMin] = all(rtl, '.euiRangeLabel');
    assert.strictEqual(css(rtlMin!).paddingLeft, '8px', 'RTL: inline-end is the left');
    assert.strictEqual(css(rtlMin!).paddingRight, '0px');
  });

  test('ticks: positions, labels, tick marks, selected tick and click', async function (assert) {
    const changes: string[] = [];
    const onChange = (e: Event) => changes.push((e.currentTarget as HTMLInputElement).value);
    await render(
      <template>
        <div style="width: 432px">
          <EuiRange
            @min={{0}}
            @max={{100}}
            @step={{25}}
            @value={{50}}
            @showTicks={{true}}
            @fullWidth={{true}}
            @onChange={{onChange}}
          />
        </div>
      </template>
    );
    const track = el(this.element, '.euiRangeTrack');
    assert.strictEqual(css(track).marginLeft, `${parseFloat(css(track).fontSize)}px`, 'track reserves 1em for labels');
    assert.strictEqual(css(track).marginRight, css(track).marginLeft);
    assert.strictEqual(css(track, '::after').top, '5px', 'line at (thumb - track) / 2 with ticks');
    assert.strictEqual(css(el(this.element, '.euiRangeSlider')).height, '16px', 'thumb-height slider');

    const ticksRoot = el(this.element, '.euiRangeTicks');
    assert.strictEqual(css(ticksRoot).position, 'absolute');
    assert.strictEqual(css(ticksRoot).display, 'flex');
    assert.strictEqual(css(ticksRoot).top, '16px', 'below the thumb');
    assert.strictEqual(css(ticksRoot).height, '24px', 'control height - thumb');

    const ticks = all(this.element, '.euiRangeTick');
    assert.deepEqual(ticks.map((t) => t.textContent!.trim()), ['0', '25', '50', '75', '100']);
    assert.deepEqual(ticks.map((t) => t.getAttribute('title')), ['0', '25', '50', '75', '100']);
    const width = track.clientWidth;
    const centers = ticks.map((tick) => {
      const box = offsetBox(tick, track);
      return box.left + box.width / 2;
    });
    // Tick centers follow the thumb centers: 8px + value% of (width - 16px)
    ticks.forEach((_, i) => near(assert, centers[i]!, 8 + (i * 25 * (width - 16)) / 100, `tick ${i} center`, 1));
    for (const tick of ticks) {
      const ts = css(tick);
      assert.strictEqual(ts.position, 'absolute');
      assert.strictEqual(ts.paddingTop, '12px', 'regular tick padding (m)');
      assert.strictEqual(ts.backgroundColor, TRANSPARENT, 'scoped button reset');
      const mark = css(tick, '::before');
      assert.strictEqual(mark.width, '4px', 'tick mark width xs');
      assert.strictEqual(mark.height, '6px', 'tick mark height = track');
      assert.strictEqual(mark.backgroundColor, rgb(light.colors.lightShade));
      assert.strictEqual(tick.tabIndex, -1);
    }
    const selected = css(ticks[2]!);
    assert.strictEqual(selected.fontWeight, String(light.font.weight.medium));
    assert.strictEqual(selected.color, rgb(light.colors.primary));
    assert.notStrictEqual(css(ticks[1]!).fontWeight, String(light.font.weight.medium));

    await click(ticks[4]!);
    assert.deepEqual(changes, ['100']);
  });

  test('custom ticks: shifted long labels, pseudo tick marks and aria-valuetext', async function (assert) {
    await render(
      <template>
        <div style="width: 432px">
          <EuiRange
            @min={{0}}
            @max={{100}}
            @step={{50}}
            @value={{100}}
            @showTicks={{true}}
            @ticks={{TICKS}}
            @fullWidth={{true}}
            @onChange={{noop}}
          />
        </div>
      </template>
    );
    const ticks = all(this.element, '.euiRangeTick');
    assert.deepEqual(ticks.map((t) => t.textContent!.trim()), ['0kb', '50kb', '100 kilobytes']);
    assert.strictEqual(css(el(this.element, '.euiRangeTicks')).left, '2px', 'custom ticks inset thumb / 8');
    // '100 kilobytes' is a long max label: shifted 1.25em into the margin with a real tick node
    const last = ticks[2]!;
    assert.dom(last.querySelector('.euiRangeTick__pseudo')).exists().hasAttribute('aria-hidden', 'true');
    assert.strictEqual(css(last, '::before').content, 'none', 'no ::before mark when a pseudo node exists');
    assert.true(/inset-inline-end: 0%/.test(last.getAttribute('style')!));
    assert.true(/margin-inline-end: -1.25em/.test(last.getAttribute('style')!));
    assert.strictEqual(css(last).transform, 'matrix(1, 0, 0, 1, 0, 0)', 'isMax: translateX(0), no centering');
    assert.strictEqual(css(last).overflowX, 'hidden', 'custom labels truncate');
    const pseudo = css(last.querySelector('.euiRangeTick__pseudo')!);
    assert.strictEqual(pseudo.width, '4px');
    assert.strictEqual(pseudo.right, '0px', 'pseudo mark at the max end');
    // '50kb' (4 chars) is not min/max: normal mark
    assert.strictEqual(css(ticks[1]!, '::before').content, '""');
    assert.strictEqual(css(ticks[1]!).maxWidth, 'none', 'custom ticks have no max width');
    assert.dom('.euiRangeSlider').hasAttribute('aria-valuetext', '100, (one hundred)');
  });

  test('ticks mirror in RTL and compressed ticks use the compressed spacing', async function (assert) {
    await render(
      <template>
        <div dir="rtl" style="width: 432px">
          <EuiRange
            @min={{0}}
            @max={{100}}
            @step={{50}}
            @value={{0}}
            @showTicks={{true}}
            @showRange={{true}}
            @compressed={{true}}
            @fullWidth={{true}}
            @onChange={{noop}}
          />
        </div>
      </template>
    );
    const track = el(this.element, '.euiRangeTrack');
    const ticks = all(this.element, '.euiRangeTick');
    const first = offsetBox(ticks[0]!, track);
    const last = offsetBox(ticks[2]!, track);
    assert.true(first.left > last.left, 'the min tick is on the right in RTL');
    // Upstream positions with `inset-inline-start` but centers with a physical
    // translateX(-50%), so in RTL the tick's right edge sits half its width
    // past the thumb center (upstream parity, not corrected here).
    near(assert, first.right - first.width / 2, 8, 'min tick anchored at the right thumb position', 1);
    assert.strictEqual(css(ticks[0]!).paddingTop, '8px', 'compressed tick padding (s)');
    assert.strictEqual(css(ticks[0]!, '::before').marginTop, '2px', 'compressed mark offset (xxs)');
    const root = css(el(this.element, '.euiRangeTicks'));
    assert.strictEqual(root.top, '11px', 'compressed ticks start below the track');
    assert.strictEqual(root.height, '21px', 'compressed height - track bottom');
  });

  test('levels: named and custom colors, positions and stripes with a range', async function (assert) {
    await render(
      <template>
        <div style="width: 416px">
          <EuiRange @levels={{LEVELS}} @value={{10}} @fullWidth={{true}} @onChange={{noop}} data-r="named" />
          <EuiRange @levels={{CUSTOM_LEVELS}} @showRange={{true}} @value={{80}} @fullWidth={{true}} @onChange={{noop}} data-r="custom" />
        </div>
      </template>
    );
    const named = el(this.element, '[data-r="named"]').closest<HTMLElement>('.euiRangeTrack')!;
    const levelsRoot = el(named, '.euiRangeLevels');
    const rs = css(levelsRoot);
    assert.strictEqual(rs.position, 'absolute');
    assert.strictEqual(rs.display, 'flex');
    assert.strictEqual(rs.top, '17px');
    assert.strictEqual(rs.zIndex, '1');
    const levels = all(levelsRoot, '.euiRangeLevel');
    assert.deepEqual(
      levels.map((l) => css(l).backgroundColor),
      [rgb(light.colors.danger), rgb(light.colors.warning), rgb(light.colors.success)]
    );
    assert.strictEqual(css(levels[0]!).height, '6px');
    assert.strictEqual(css(levels[0]!).borderTopLeftRadius, light.border.radius.inline, 'first level rounded start');
    assert.strictEqual(css(levels[0]!).borderTopRightRadius, '0px');
    assert.strictEqual(css(levels[2]!).borderTopRightRadius, light.border.radius.inline, 'last level rounded end');
    const first = offsetBox(levels[0]!, named);
    const last = offsetBox(levels[2]!, named);
    assert.strictEqual(first.left, 0, 'first level starts at the track start');
    assert.strictEqual(last.right, 0, 'last level ends at the track end');
    assert.true(first.width < last.width, 'levels are proportional');
    // The thumb takes the color of the level the value is in
    assert.true(
      el(this.element, '[data-r="named"]').getAttribute('style')!.includes(`--euiRangeThumbColor: ${light.colors.danger}`)
    );

    const custom = el(this.element, '[data-r="custom"]').closest<HTMLElement>('.euiRangeTrack')!;
    const trackLevels = el(custom, ':scope > .euiRangeLevels');
    const [c0, c1] = all(trackLevels, '.euiRangeLevel');
    assert.dom(c0).hasClass('custom-level');
    assert.strictEqual(css(c0!).backgroundColor, rgb('#123456'), 'custom color inline');
    assert.strictEqual(css(c1!).backgroundColor, rgb(light.colors.primary));
    const stripes = css(trackLevels, '::after');
    assert.true(stripes.backgroundImage.startsWith('repeating-linear-gradient'), 'striped levels with showRange');
    assert.strictEqual(stripes.height, '6px');
    // The highlight shows the levels in the selected part only
    const highlight = el(custom, '.euiRangeHighlight');
    assert.dom(highlight.querySelector('.euiRangeHighlight__progress')).doesNotExist();
    const wrapper = highlight.firstElementChild as HTMLElement;
    assert.strictEqual(css(wrapper).overflow, 'hidden');
    near(assert, offsetBox(wrapper, custom).width, 416 * 0.8, 'levels wrapper spans the selected range');
    const inner = el(highlight, '.euiRangeLevels');
    assert.strictEqual(css(inner).backgroundColor, TRANSPARENT);
    assert.strictEqual(css(inner).top, '0px');
  });

  test('highlight: geometry, color, focus color and RTL mirroring', async function (assert) {
    await render(
      <template>
        <div style="width: 400px">
          <EuiRange @showRange={{true}} @value={{25}} @onChange={{noop}} data-r="ltr" />
        </div>
        <div dir="rtl" style="width: 400px">
          <EuiRange @showRange={{true}} @value={{25}} @onChange={{noop}} data-r="rtl" />
        </div>
      </template>
    );
    const ltrTrack = el(this.element, '[data-r="ltr"]').closest<HTMLElement>('.euiRangeTrack')!;
    const highlight = el(ltrTrack, '.euiRangeHighlight');
    const hs = css(highlight);
    assert.strictEqual(hs.position, 'absolute');
    assert.strictEqual(hs.height, '6px');
    assert.strictEqual(hs.top, '17px');
    assert.strictEqual(hs.zIndex, '2');
    assert.strictEqual(hs.pointerEvents, 'none');
    const progress = el(ltrTrack, '.euiRangeHighlight__progress');
    assert.dom(progress).hasAttribute('data-test-subj', 'euiRangeHighlightProgress');
    assert.strictEqual(css(progress).backgroundColor, rgb(light.colors.darkShade));
    assert.strictEqual(css(progress).borderTopLeftRadius, light.border.radius.inline);
    const box = offsetBox(progress, ltrTrack);
    assert.strictEqual(box.left, 0);
    assert.strictEqual(box.width, 100, '25% of the track');
    // The highlight follows the slider in the DOM, so sibling focus selectors apply
    assert.dom(highlight.previousElementSibling).hasClass('euiRangeSlider');
    assert.strictEqual(
      rgb(pseudoRules(progress, '', ':focus-visible')['background-color']!),
      rgb(light.colors.primary),
      'primary while the slider has :focus-visible'
    );

    const rtlTrack = el(this.element, '[data-r="rtl"]').closest<HTMLElement>('.euiRangeTrack')!;
    const rtlBox = offsetBox(el(rtlTrack, '.euiRangeHighlight__progress'), rtlTrack);
    assert.strictEqual(rtlBox.right, 0, 'RTL: starts at the right');
    assert.strictEqual(rtlBox.width, 100);
  });

  test('value tooltip: colors, arrow side, position and append/prepend', async function (assert) {
    await render(
      <template>
        <div style="width: 400px">
          <EuiRange @showValue={{true}} @value={{20}} @valueAppend="kb" @name="low" @onChange={{noop}} data-r="low" />
          <EuiRange @showValue={{true}} @value={{80}} @valuePrepend="$" @showTicks={{true}} @onChange={{noop}} data-r="high" />
        </div>
      </template>
    );
    const lowTrack = el(this.element, '[data-r="low"]').closest<HTMLElement>('.euiRangeTrack')!;
    const tooltip = el(lowTrack, '.euiRangeTooltip');
    const ts = css(tooltip);
    assert.strictEqual(ts.position, 'absolute');
    assert.strictEqual(ts.pointerEvents, 'none');
    assert.strictEqual(ts.marginLeft, '8px', 'half a thumb');
    assert.strictEqual(ts.width, '384px', '100% - thumb');
    const value = el(lowTrack, 'output.euiRangeTooltip__value');
    assert.dom(value).hasText('20kb').hasAttribute('for', 'low');
    const vs = css(value);
    assert.strictEqual(vs.backgroundColor, rgb(light.components.tooltipBackground));
    assert.strictEqual(vs.color, rgb(light.colors.textGhost));
    assert.strictEqual(vs.borderTopLeftRadius, light.border.radius.control);
    assert.strictEqual(vs.borderTopColor, TRANSPARENT, 'light: transparent border');
    assert.strictEqual(vs.paddingLeft, '8px');
    assert.strictEqual(vs.paddingTop, '2px');
    assert.strictEqual(vs.marginLeft, '24px', 'right of the thumb below the midpoint');
    assert.true(/inset-inline-start: 20%/.test(value.getAttribute('style')!));
    assert.strictEqual(css(value, '::before').content, '""', 'arrow');
    assert.strictEqual(css(value, '::before').backgroundColor, vs.backgroundColor);

    const high = el(el(this.element, '[data-r="high"]').closest('.euiRangeTrack')!, '.euiRangeTooltip__value');
    assert.dom(high).hasText('$80');
    assert.strictEqual(css(high).marginRight, '24px', 'left of the thumb above the midpoint');
    const end = /inset-inline-end: ([\d.]+)%/.exec(high.getAttribute('style')!);
    near(assert, Number(end?.[1]), 20, 'positioned from the end', 0.001);
    assert.strictEqual(css(high).top, '8px', 'with ticks: half a thumb from the top');
  });

  test('showInput: number input sizing, spacer and input-driven changes', async function (assert) {
    const values: string[] = [];
    const onChange = (e: Event) => values.push((e.currentTarget as HTMLInputElement).value);
    await render(
      <template>
        <EuiRange @showInput={{true}} @value={{7}} @onChange={{onChange}} data-r="input" />
        <EuiRange @showInput={{true}} @showTicks={{true}} @step={{50}} @value={{50}} @onChange={{noop}} data-r="ticks" />
        <EuiRange @showInput={{true}} @isInvalid={{true}} @value={{7}} @onChange={{noop}} data-r="invalid" />
      </template>
    );
    const input = el(this.element, 'input.euiRangeInput[data-r="input"]');
    assert.dom(input).hasClass('euiRangeInput--max').hasClass('euiFieldNumber').hasValue('7');
    assert.strictEqual(css(input).minWidth, '56px', 'min-inline-size base * 3.5');
    assert.true(/inline-size: calc\(12px \+ 1ch \+ 2em \+ 0px\)/.test(input.getAttribute('style')!), 'auto size from the value');
    const spacer = el(this.element, '.euiRange__horizontalSpacer');
    assert.strictEqual(css(spacer).width, '16px');
    assert.strictEqual(css(el(this.element, '.euiRange__slimHorizontalSpacer')).width, '8px', 'slim spacer with ticks');
    assert.true(
      /\+ 22px\)/.test(el(this.element, 'input.euiRangeInput[data-r="invalid"]').getAttribute('style')!),
      'invalid icon width'
    );
    const slider = input.closest('.euiRangeWrapper')!.querySelector('input[type="range"]')!;
    assert.dom(slider).hasAttribute('aria-hidden', 'true').hasAttribute('tabindex', '-1').doesNotHaveAttribute('id');
    assert.dom(input).hasAttribute('id');
    assert.dom(el(this.element, '.euiRangeTrack')).hasAttribute('aria-hidden', 'true');

    await fillIn(input, '42');
    assert.deepEqual(values, ['42']);
  });

  test('inputWithPopover: loading spinner, read-only input and the range in a popover', async function (assert) {
    await render(
      <template>
        <EuiRange @showInput="inputWithPopover" @isLoading={{true}} @value={{30}} @onChange={{noop}} data-r="pop" />
        <EuiRange @showInput={{true}} @readOnly={{true}} @value={{30}} @onChange={{noop}} data-r="ro" />
      </template>
    );
    const input = el(this.element, 'input.euiRangeInput[data-r="pop"]');
    const layout = input.closest('.euiFormControlLayout')!;
    assert.dom(layout.querySelector('.euiFormControlLayoutIcons [role="progressbar"], .euiBorealisLoadingSpinner')).exists('isLoading spinner in the input');
    assert.dom('.euiRange__popover').exists();
    await focus(input);
    assert.dom('.euiRangeWrapper.euiRange').exists('range opens in the popover');
    const slider = el(document, '.euiRangeWrapper.euiRange input[type="range"]');
    assert.dom(slider).hasAttribute('tabindex', '-1').hasAttribute('aria-hidden', 'true');
    assert.dom(el(this.element, 'input.euiRangeInput[data-r="ro"]')).hasAttribute('readonly');
  });

  test('keyboard on the native slider and aria values', async function (assert) {
    class State {
      @tracked value = 5;
      change = (e: Event, valid: boolean) => {
        this.value = Number((e.currentTarget as HTMLInputElement).value);
        this.valid.push(valid);
      };
      valid: boolean[] = [];
    }
    const state = new State();
    await render(
      <template>
        <EuiRange @min={{0}} @max={{10}} @value={{state.value}} @onChange={{state.change}} aria-label="Volume" />
      </template>
    );
    const slider = el(this.element, 'input[type="range"]') as HTMLInputElement;
    assert.dom(slider).hasAttribute('min', '0').hasAttribute('max', '10').hasAria('label', 'Volume');
    assert.strictEqual(slider.tabIndex, 0, 'focusable');
    await focus(slider);
    assert.strictEqual(document.activeElement, slider);
    // Arrow keys are a browser default action: emulate the resulting input
    slider.stepUp();
    await triggerEvent(slider, 'input');
    assert.strictEqual(state.value, 6);
    assert.deepEqual(state.valid, [true]);
    assert.strictEqual(slider.value, '6');
  });

  test('reactive args update in place without replacing elements', async function (assert) {
    class State {
      @tracked compressed = false;
      @tracked fullWidth = false;
      @tracked disabled = false;
      @tracked showRange = false;
      @tracked value = 30;
    }
    const state = new State();
    await render(
      <template>
        <div style="width: 600px">
          <EuiRange
            @compressed={{state.compressed}}
            @fullWidth={{state.fullWidth}}
            @disabled={{state.disabled}}
            @showRange={{state.showRange}}
            @showTicks={{true}}
            @step={{10}}
            @value={{state.value}}
            @onChange={{noop}}
          />
        </div>
      </template>
    );
    const wrapper = el(this.element, '.euiRangeWrapper');
    const slider = el(this.element, '.euiRangeSlider');
    const tick = all(this.element, '.euiRangeTick')[3]!;
    assert.strictEqual(css(tick).fontWeight, String(light.font.weight.medium));

    state.compressed = true;
    state.fullWidth = true;
    state.disabled = true;
    state.showRange = true;
    state.value = 50;
    await settled();
    assert.strictEqual(el(this.element, '.euiRangeWrapper'), wrapper, 'same wrapper');
    assert.strictEqual(el(this.element, '.euiRangeSlider'), slider, 'same slider');
    assert.strictEqual(all(this.element, '.euiRangeTick')[3], tick, 'same tick');
    assert.strictEqual(css(wrapper).height, '32px');
    assert.strictEqual(wrapper.offsetWidth, 600);
    assert.strictEqual(css(el(this.element, '.euiRangeTrack')).opacity, '0.5');
    assert.true((slider as HTMLInputElement).disabled);
    assert.true(all(this.element, '.euiRangeTick').every((t) => (t as HTMLButtonElement).disabled));
    assert.strictEqual(css(tick).fontWeight, css(el(this.element, '.euiRangeTicks')).fontWeight, 'old tick deselected');
    assert.strictEqual(css(all(this.element, '.euiRangeTick')[5]!).fontWeight, String(light.font.weight.medium));
    assert.strictEqual(css(slider, '::-webkit-slider-runnable-track').backgroundColor, TRANSPARENT);
    assert.dom('.euiRangeHighlight__progress').exists();
    assert.strictEqual(css(el(this.element, '.euiRangeTrack')).marginLeft, `${parseFloat(css(el(this.element, '.euiRangeTrack')).fontSize)}px`);
  });

  test('EuiDualRange: thumbs, positions, colors, focus ring and highlight', async function (assert) {
    const value: [number, number] = [20, 80];
    await render(
      <template>
        <div style="width: 416px">
          <EuiDualRange
            @value={{value}}
            @fullWidth={{true}}
            @ariaLabel="Price"
            @onChange={{noop}}
          />
        </div>
      </template>
    );
    const wrapper = el(this.element, '.euiRangeWrapper');
    assert.dom(wrapper).hasClass('euiDualRange');
    const track = el(this.element, '.euiRangeTrack');
    const slider = el(this.element, '.euiDualRange__slider');
    assert.dom(slider).hasAttribute('aria-hidden', 'true').hasAttribute('tabindex', '-1');
    const thumbs = all(this.element, '.euiRangeThumb');
    assert.strictEqual(thumbs.length, 2);
    const [lower, upper] = thumbs as [HTMLElement, HTMLElement];
    assert.dom(lower).hasAttribute('role', 'slider').hasAria('valuemin', '0').hasAria('valuemax', '80').hasAria('valuenow', '20').hasAria('label', 'Price');
    assert.dom(upper).hasAria('valuemin', '20').hasAria('valuemax', '100').hasAria('valuenow', '80');
    assert.strictEqual(lower.tabIndex, 0);
    const ts = css(lower);
    assert.strictEqual(ts.position, 'absolute');
    assert.strictEqual(ts.width, '16px');
    assert.strictEqual(ts.height, '16px');
    assert.strictEqual(ts.borderTopLeftRadius, '50%');
    assert.strictEqual(ts.backgroundColor, rgb(light.colors.darkShade), 'highlight color');
    assert.strictEqual(ts.borderTopWidth, '2px');
    assert.strictEqual(ts.borderTopColor, rgb(light.colors.emptyShade));
    assert.strictEqual(ts.pointerEvents, 'none', 'clicks reach the slider');
    assert.strictEqual(ts.zIndex, '3');
    assert.true(ts.boxShadow.includes(rgb(light.colors.emptyShade)), 'thumb ring shadow');
    // Thumb positions: value% of (track - thumb)
    const width = track.clientWidth;
    near(assert, offsetBox(lower, track).left, 0.2 * (width - 16), 'lower thumb position');
    near(assert, offsetBox(upper, track).left, 0.8 * (width - 16), 'upper thumb position');
    near(assert, offsetBox(lower, track).height, 16, 'thumb size');

    // The highlight comes after the thumbs (sibling focus selectors) and spans 20-80%
    const highlight = el(track, '.euiRangeHighlight');
    assert.dom(highlight.previousElementSibling).hasClass('euiRangeThumb');
    const progress = el(highlight, '.euiRangeHighlight__progress');
    near(assert, offsetBox(progress, track).left, 0.2 * width, 'highlight start');
    near(assert, offsetBox(progress, track).width, 0.6 * width, 'highlight width');

    await focus(lower);
    const focused = css(lower);
    assert.strictEqual(focused.backgroundColor, rgb(light.colors.primary), 'focus background');
    assert.strictEqual(focused.outlineStyle, 'solid');
    assert.strictEqual(focused.outlineWidth, '2px');
    assert.strictEqual(focused.outlineColor, rgb(light.colors.primary));
    assert.strictEqual(
      rgb(pseudoRules(progress, '', ':focus-visible')['background-color']!),
      rgb(light.colors.primary),
      'highlight turns primary while a thumb has :focus-visible'
    );
  });

  test('EuiDualRange keyboard: arrows move each thumb by a step within bounds', async function (assert) {
    class State {
      @tracked value: [number | string, number | string] = [20, 30];
      changes: unknown[] = [];
      change = (values: [number | string, number | string], valid: boolean) => {
        this.value = values;
        this.changes.push([...values, valid]);
      };
    }
    const state = new State();
    await render(
      <template>
        <EuiDualRange @min={{0}} @max={{100}} @step={{10}} @value={{state.value}} @onChange={{state.change}} />
      </template>
    );
    const [lower, upper] = all(this.element, '.euiRangeThumb') as [HTMLElement, HTMLElement];
    await triggerKeyEvent(lower, 'keydown', 'ArrowLeft');
    assert.deepEqual(state.changes.at(-1), [10, 30, true]);
    assert.dom(lower).hasAria('valuenow', '10');
    assert.strictEqual(all(this.element, '.euiRangeThumb')[0], lower, 'thumb not replaced');
    await triggerKeyEvent(upper, 'keydown', 'ArrowUp');
    assert.deepEqual(state.changes.at(-1), [10, 40, true]);
    assert.dom(upper).hasAria('valuenow', '40').hasAria('valuemin', '10');
    assert.dom(lower).hasAria('valuemax', '40');
    const count = state.changes.length;
    await triggerKeyEvent(lower, 'keydown', 'ArrowLeft');
    await triggerKeyEvent(lower, 'keydown', 'ArrowLeft');
    assert.deepEqual(state.changes.at(-1), [0, 40, true]);
    assert.strictEqual(state.changes.length, count + 1, 'cannot go below min');
    await triggerKeyEvent(lower, 'keydown', 'Tab');
    assert.strictEqual(state.changes.length, count + 1, 'Tab is ignored');
    // Clicking the track moves the nearest thumb
    const slider = el(this.element, '.euiDualRange__slider') as HTMLInputElement;
    slider.value = '90';
    await triggerEvent(slider, 'input');
    assert.deepEqual(state.changes.at(-1), [0, 90, true]);
  });

  test('EuiDualRange draggable range: styles, aria and keyboard/mouse moves', async function (assert) {
    class State {
      @tracked value: [number | string, number | string] = [20, 40];
      change = (values: [number | string, number | string]) => {
        this.value = values;
      };
    }
    const state = new State();
    await render(
      <template>
        <div style="width: 416px">
          <EuiDualRange @isDraggable={{true}} @fullWidth={{true}} @step={{10}} @value={{state.value}} @onChange={{state.change}} />
        </div>
      </template>
    );
    const draggable = el(this.element, '.euiRangeDraggable');
    assert.dom(draggable).hasAttribute('role', 'slider').hasAria('valuenow', '20').hasAria('valuetext', '20, 40').hasAria('disabled', 'false');
    assert.strictEqual(draggable.tabIndex, 0);
    const ds = css(draggable);
    assert.strictEqual(ds.position, 'absolute');
    assert.strictEqual(ds.height, '20px', 'half the control height');
    assert.strictEqual(ds.top, '10px');
    assert.strictEqual(ds.pointerEvents, 'none');
    const inner = el(draggable, '.euiRangeDraggable__inner');
    assert.strictEqual(css(inner).cursor, 'grab');
    assert.strictEqual(css(inner).pointerEvents, 'all');
    assert.strictEqual(css(inner).left, '16px', 'inner leaves the thumbs free');

    await triggerKeyEvent(draggable, 'keydown', 'ArrowRight');
    assert.deepEqual(state.value, [30, 50], 'keyboard moves both values');
    assert.dom(draggable).hasAria('valuetext', '30, 50');
    await focus(draggable);
    assert.strictEqual(css(all(this.element, '.euiRangeThumb')[0]!).backgroundColor, rgb(light.colors.primary), 'focused draggable highlights the thumbs');

    // Upstream divides the pointer delta (clientX) by the slider width: a
    // delta of 25% of the width moves [30, 50] by 25 → nearest steps [60, 80]
    const track = el(this.element, '.euiDualRange__slider');
    const rect = inner.getBoundingClientRect();
    await triggerEvent(inner, 'mousedown', { clientX: rect.left + 1 });
    await triggerEvent(document, 'mousemove', { clientX: rect.left + 1 + 0.25 * track.clientWidth });
    await triggerEvent(document, 'mouseup');
    assert.deepEqual(state.value, [60, 80], 'mouse drag moves the whole range');
    await triggerEvent(document, 'mousemove', { clientX: rect.left - 200 });
    assert.deepEqual(state.value, [60, 80], 'mouseup ends the drag');
  });

  test('EuiDualRange inputs: non-popover inputs and the delimited popover layout', async function (assert) {
    const changes: unknown[] = [];
    const onChange = (values: unknown) => changes.push(values);
    const value: [number, number] = [2, 8];
    await render(
      <template>
        <EuiDualRange @min={{0}} @max={{10}} @value={{value}} @showInput={{true}} @name="r" @onChange={{onChange}} data-r="inline" />
        <EuiDualRange
          @min={{0}}
          @max={{10}}
          @value={{value}}
          @showInput="inputWithPopover"
          @isInvalid={{true}}
          @compressed={{true}}
          @onChange={{onChange}}
          data-r="popover"
        />
      </template>
    );
    const inline = all(this.element, 'input.euiRangeInput[data-r="inline"]');
    assert.strictEqual(inline.length, 2);
    assert.dom(inline[0]).hasClass('euiRangeInput--min').hasAttribute('name', 'r-minValue').hasAttribute('max', '8').hasValue('2');
    assert.dom(inline[1]).hasClass('euiRangeInput--max').hasAttribute('name', 'r-maxValue').hasAttribute('min', '2').hasValue('8');
    const wrapper = inline[0]!.closest('.euiRangeWrapper')!;
    assert.strictEqual(all(wrapper, '.euiRange__horizontalSpacer').length, 2);
    for (const thumb of all(wrapper, '.euiRangeThumb')) {
      assert.strictEqual(thumb.tabIndex, -1, 'inputs are the keyboard controls');
    }
    assert.dom(wrapper.querySelector('.euiRangeTrack')).hasAttribute('aria-hidden', 'true');
    await fillIn(inline[1]!, '9');
    assert.deepEqual(changes.at(-1), [2, '9']);

    const popover = all(this.element, 'input.euiRangeInput[data-r="popover"]');
    assert.strictEqual(popover.length, 2);
    const layout = popover[0]!.closest<HTMLElement>('.euiFormControlLayoutDelimited')!;
    assert.ok(layout, 'delimited layout');
    assert.dom(layout).hasClass('euiFormControlLayoutDelimited--isInvalid');
    assert.dom(popover[0]).hasClass('euiFormControlLayoutDelimited__input').hasAria('invalid', 'true');
    assert.strictEqual(css(layout).height, '32px', 'compressed delimited layout');
    assert.dom(layout.querySelector('.euiFormControlLayout__prepend')).doesNotExist('no empty side wrappers');
    assert.dom(layout.querySelector('.euiFormControlLayout__append')).doesNotExist();
    assert.dom('.euiDualRange__popover').exists();
    await focus(popover[0]!);
    assert.dom('.euiRangeWrapper.euiDualRange').exists('range opens in the popover');
  });

  test('EuiDualRange levels color each thumb; disabled thumbs are not focusable', async function (assert) {
    const value: [number, number] = [10, 90];
    await render(
      <template>
        <EuiDualRange @levels={{LEVELS}} @value={{value}} @onChange={{noop}} data-r="levels" />
        <EuiDualRange @disabled={{true}} @value={{value}} @onChange={{noop}} data-r="off" />
      </template>
    );
    const [lower, upper] = all(this.element, '.euiRangeThumb');
    assert.strictEqual(css(lower!).backgroundColor, rgb(light.colors.danger));
    assert.strictEqual(css(upper!).backgroundColor, rgb(light.colors.success));
    const disabled = all(el(this.element, '[data-r="off"]').closest('.euiRangeWrapper')!, '.euiRangeThumb');
    for (const thumb of disabled) {
      assert.dom(thumb).hasAria('disabled', 'true').isDisabled();
      assert.strictEqual(thumb.tabIndex, -1);
    }
  });

  test('EuiRangeThumb standalone: role, tabindex, @css and attributes', async function (assert) {
    const extra = { outline: '3px dashed rgb(1, 2, 3)' };
    await render(
      <template>
        <EuiRangeThumb @min={{0}} @max={{10}} @value="4" @tabIndex={{-1}} @css={{extra}} data-t="a" title="Drag" />
        <EuiRangeThumb @min={{0}} @max={{10}} @value={{5}} @showTicks={{true}} data-t="b" />
      </template>
    );
    const a = el(this.element, '[data-t="a"]');
    assert.dom(a).hasTagName('button').hasAttribute('type', 'button').hasAria('valuenow', '4').hasAttribute('title', 'Drag');
    assert.strictEqual(a.tabIndex, -1);
    assert.strictEqual(css(a).outlineStyle, 'dashed', '@css composed last');
    assert.strictEqual(css(a).marginTop, '-8px', 'centered on the track');
    assert.strictEqual(css(el(this.element, '[data-t="b"]')).marginTop, '0px', 'hasTicks');
    assert.strictEqual(css(el(this.element, '[data-t="b"]')).top, '0px');
  });

  test('nearest-provider light/dark, sibling isolation and JS-object token overrides', async function (assert) {
    class State {
      @tracked mode: EuiColorMode = 'light';
      @tracked overrides: EuiBorealisOverrides = {};
    }
    const state = new State();
    const own: EuiBorealisOverrides = { size: { xxl: '48px' } };
    await render(
      <template>
        <EuiEmotionProvider @colorMode={{state.mode}} @borealisOverrides={{state.overrides}}>
          <EuiRange @showRange={{true}} @showValue={{true}} @value={{50}} @onChange={{noop}} data-r="parent" />
          <EuiEmotionProvider @borealisOverrides={{own}}>
            <EuiRange @value={{50}} @onChange={{noop}} data-r="child" />
          </EuiEmotionProvider>
          <EuiEmotionProvider @colorMode="light">
            <EuiRange @showRange={{true}} @value={{50}} @onChange={{noop}} data-r="island" />
          </EuiEmotionProvider>
        </EuiEmotionProvider>
        <EuiEmotionProvider @colorMode="light">
          <EuiRange @showRange={{true}} @value={{50}} @onChange={{noop}} data-r="sibling" />
        </EuiEmotionProvider>
      </template>
    );
    const trackOf = (key: string) =>
      el(this.element, `[data-r="${key}"]`).closest<HTMLElement>('.euiRangeTrack')!;
    const line = (key: string) => css(trackOf(key), '::after').backgroundColor;
    const progress = (key: string) => css(el(trackOf(key), '.euiRangeHighlight__progress')).backgroundColor;
    const parentSlider = el(this.element, '[data-r="parent"]');
    assert.strictEqual(line('parent'), rgb(light.colors.lightShade));
    assert.strictEqual(progress('parent'), rgb(light.colors.darkShade));
    assert.strictEqual(
      css(el(this.element, '[data-r="child"]').closest('.euiRangeWrapper')!).height,
      '48px',
      'size override drives the wrapper height'
    );

    state.mode = 'dark';
    await settled();
    assert.strictEqual(el(this.element, '[data-r="parent"]'), parentSlider, 'no replacement');
    assert.strictEqual(line('parent'), rgb(dark.colors.lightShade));
    assert.strictEqual(progress('parent'), rgb(dark.colors.darkShade));
    const tooltip = css(el(trackOf('parent'), '.euiRangeTooltip__value'));
    assert.strictEqual(tooltip.backgroundColor, rgb(dark.components.tooltipBackground));
    assert.strictEqual(tooltip.borderTopColor, rgb(dark.border.color), 'dark: visible border');
    assert.strictEqual(line('child'), rgb(dark.colors.lightShade), 'child inherits the mode');
    assert.strictEqual(progress('island'), rgb(light.colors.darkShade), 'light island');
    assert.strictEqual(progress('sibling'), rgb(light.colors.darkShade), 'sibling isolated');

    state.mode = 'light';
    state.overrides = { colors: { LIGHT: { darkShade: '#aa0000', lightShade: '#00aa00' } } };
    await settled();
    assert.strictEqual(progress('parent'), rgb('#aa0000'), 'token override: highlight');
    assert.strictEqual(line('parent'), rgb('#00aa00'), 'token override: track');
    assert.strictEqual(progress('sibling'), rgb(light.colors.darkShade), 'sibling unaffected');
  });

  test('high contrast: thumb, highlight and tick colors', async function (assert) {
    const value: [number, number] = [20, 80];
    await render(
      <template>
        <EuiEmotionProvider @highContrastMode="preferred">
          <EuiDualRange @value={{value}} @onChange={{noop}} @showTicks={{true}} @step={{20}} data-r="hc" />
        </EuiEmotionProvider>
        <EuiDualRange @value={{value}} @onChange={{noop}} data-r="std" />
      </template>
    );
    const hc = el(this.element, '[data-r="hc"]').closest<HTMLElement>('.euiRangeWrapper')!;
    const thumb = css(el(hc, '.euiRangeThumb'));
    assert.strictEqual(thumb.backgroundColor, rgb(hcLight.colors.emptyShade), 'HC thumb background');
    assert.strictEqual(thumb.borderTopColor, rgb(hcLight.colors.fullShade), 'HC thumb border');
    assert.true(thumb.boxShadow.startsWith(rgb(hcLight.colors.emptyShade)) && thumb.boxShadow.includes('inset'), 'HC inset ring');
    assert.strictEqual(css(el(hc, '.euiRangeHighlight__progress')).backgroundColor, rgb(hcLight.colors.fullShade));
    assert.strictEqual(css(el(hc, '.euiRangeTick'), '::before').backgroundColor, rgb(hcLight.colors.darkShade), 'HC tick marks');
    const std = el(this.element, '[data-r="std"]').closest<HTMLElement>('.euiRangeWrapper')!;
    assert.strictEqual(css(el(std, '.euiRangeThumb')).backgroundColor, rgb(light.colors.darkShade), 'standard isolated');
    assert.strictEqual(css(el(std, '.euiRangeHighlight__progress')).backgroundColor, rgb(light.colors.darkShade));
  });

  test('RTL: dual range thumbs mirror', async function (assert) {
    const value: [number, number] = [0, 100];
    await render(
      <template>
        <div dir="rtl" style="width: 416px">
          <EuiDualRange @value={{value}} @fullWidth={{true}} @onChange={{noop}} />
        </div>
      </template>
    );
    const track = el(this.element, '.euiRangeTrack');
    const [lower, upper] = all(this.element, '.euiRangeThumb');
    assert.strictEqual(offsetBox(lower!, track).right, 0, 'min thumb on the right');
    assert.strictEqual(offsetBox(upper!, track).left, 0, 'max thumb on the left');
  });
});
