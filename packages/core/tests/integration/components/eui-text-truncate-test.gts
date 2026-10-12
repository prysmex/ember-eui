import { tracked } from '@glimmer/tracking';
import { hash } from '@ember/helper';
import { htmlSafe } from '@ember/template';
import {
  clearRender,
  find,
  render,
  settled,
  triggerEvent,
  waitUntil
} from '@ember/test-helpers';
import { setupRenderingTest } from 'ember-qunit';
import { module, test } from 'qunit';

import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import EuiTextBlockTruncate from '#src/components/eui-text-block-truncate.gts';
import EuiTextTruncate from '#src/components/eui-text-truncate.gts';
import { TruncationUtils } from '#src/utils/eui/styles.generated.ts';
import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';

import type { EuiTextTruncationTypes } from '#src/components/eui-text-truncate.gts';
import type { EuiBorealisHighContrastMode } from '#src/utils/eui/theme.ts';

const light = resolveBorealisTheme('light').euiTheme;
const dark = resolveBorealisTheme('dark').euiTheme;

function el(root: Element | Document, selector: string): HTMLElement {
  const element = root.querySelector<HTMLElement>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
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

const TEXT = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit';
const FONT = htmlSafe('font-family: monospace; font-size: 14px;');

/** What upstream's TruncationUtils yields for the rendered container. */
function expected(
  container: HTMLElement,
  width: number,
  truncation: EuiTextTruncationTypes,
  options: { offset?: number; position?: number; ellipsis?: string; text?: string } = {}
): string {
  const fullText = options.text ?? TEXT;
  const utils = new (TruncationUtils as any)({
    fullText,
    ellipsis: options.ellipsis ?? '…',
    container,
    availableWidth: width
  });
  if (utils.checkIfTruncationIsNeeded() === false) return fullText;
  if (utils.checkSufficientEllipsisWidth(truncation) === false) return '';
  if (truncation === 'start') return utils.truncateStart(options.offset ?? 0);
  if (truncation === 'middle') return utils.truncateMiddle();
  if (truncation === 'startEnd')
    return options.position == null
      ? utils.truncateStartEndAtMiddle()
      : utils.truncateStartEndAtPosition(options.position);
  return utils.truncateEnd(options.offset ?? 0);
}

/** Resolves when the next ResizeObserver round and render are done. */
async function layoutSettled() {
  for (let frame = 0; frame < 3; frame++)
    await new Promise((resolve) => requestAnimationFrame(resolve));
  await settled();
}

module('Integration | Component | Borealis text truncate', function (hooks) {
  setupRenderingTest(hooks);

  test('text truncate: each truncation type at a given width matches upstream and fits', async function (assert) {
    class State {
      @tracked truncation: EuiTextTruncationTypes = 'end';
      @tracked width = 150;
      @tracked offset: number | undefined = undefined;
      @tracked position: number | undefined = undefined;
      @tracked ellipsis: string | undefined = undefined;
    }
    const state = new State();
    await render(
      <template>
        <EuiTextTruncate
          @text={{TEXT}}
          @truncation={{state.truncation}}
          @width={{state.width}}
          @truncationOffset={{state.offset}}
          @truncationPosition={{state.position}}
          @ellipsis={{state.ellipsis}}
          style={{FONT}}
          data-truncate
        />
      </template>
    );
    const root = el(this.element, '[data-truncate]');
    assert.dom(root).hasTagName('div').hasClass('euiTextTruncate').doesNotHaveAttribute('data-resize-observer', 'no observer with @width');
    const shown = () => el(root, '[data-test-subj="truncatedText"]').textContent!;
    const fits = (label: string) => {
      const span = el(root, '[data-test-subj="truncatedText"]');
      // Layout width (the test container is scaled); canvas and DOM differ by subpixels
      assert.true(span.offsetWidth <= state.width + 1, `${label}: ${span.offsetWidth}px fits ${state.width}px`);
    };

    let text = shown();
    assert.strictEqual(text, expected(root, 150, 'end'), 'end');
    assert.true(text.endsWith('…') && TEXT.startsWith(text.slice(0, -1)), `end: "${text}"`);
    assert.true(text.length < TEXT.length);
    fits('end');
    assert.dom('[data-test-subj="fullText"]', root).hasText(TEXT, 'full text kept for selection/copy');

    state.truncation = 'start';
    await settled();
    assert.strictEqual(el(this.element, '[data-truncate]'), root, 'root kept');
    text = shown();
    assert.strictEqual(text, expected(root, 150, 'start'), 'start');
    assert.true(text.startsWith('…') && TEXT.endsWith(text.slice(1)), `start: "${text}"`);
    fits('start');

    state.truncation = 'middle';
    await settled();
    text = shown();
    assert.strictEqual(text, expected(root, 150, 'middle'), 'middle');
    const [head, tail] = text.split('…') as [string, string];
    assert.true(head.length > 0 && tail.length > 0 && TEXT.startsWith(head) && TEXT.endsWith(tail), `middle: "${text}"`);
    fits('middle');

    state.truncation = 'startEnd';
    await settled();
    text = shown();
    assert.strictEqual(text, expected(root, 150, 'startEnd'), 'startEnd at the middle');
    assert.true(text.startsWith('…') && text.endsWith('…') && TEXT.includes(text.slice(1, -1)), `startEnd: "${text}"`);
    fits('startEnd');

    state.position = TEXT.indexOf('adipiscing');
    await settled();
    text = shown();
    assert.strictEqual(text, expected(root, 150, 'startEnd', { position: state.position }), 'startEnd at a position');
    assert.true(text.includes('adipisc'), `anchored on the position: "${text}"`);

    state.position = 0;
    await settled();
    assert.strictEqual(shown(), expected(root, 150, 'end'), 'position <= 0 truncates the end');
    state.position = TEXT.length;
    await settled();
    assert.strictEqual(shown(), expected(root, 150, 'start'), 'position >= length truncates the start');

    state.position = undefined;
    state.truncation = 'end';
    state.offset = 5;
    await settled();
    text = shown();
    assert.strictEqual(text, expected(root, 150, 'end', { offset: 5 }));
    assert.true(text.endsWith(`…${TEXT.slice(-5)}`), `end offset keeps the last 5 characters: "${text}"`);

    state.truncation = 'start';
    state.offset = 6;
    await settled();
    text = shown();
    assert.strictEqual(text, expected(root, 150, 'start', { offset: 6 }));
    assert.true(text.startsWith(`${TEXT.slice(0, 6)}…`), `start offset keeps the first 6 characters: "${text}"`);

    state.offset = TEXT.length;
    await settled();
    assert.strictEqual(shown(), expected(root, 150, 'start'), 'an offset >= length is ignored');

    state.offset = undefined;
    state.ellipsis = ' [...] ';
    await settled();
    text = shown();
    assert.true(text.startsWith(' [...] '), `custom ellipsis: "${text}"`);
    assert.strictEqual(text, expected(root, 150, 'start', { ellipsis: ' [...] ' }));

    state.ellipsis = undefined;
    state.width = 2000;
    await settled();
    assert.dom('[data-test-subj="truncatedText"]', root).doesNotExist('wide enough: no truncation');
    assert.dom('[data-test-subj="fullText"]', root).hasText(TEXT).doesNotHaveAttribute('aria-hidden');

    const originalError = console.error;
    const errors: unknown[] = [];
    console.error = (...args: unknown[]) => errors.push(args[0]);
    try {
      state.width = 8;
      await settled();
      assert.strictEqual(shown(), '', 'no room for the ellipsis: nothing rendered (upstream)');
      assert.true(errors.length > 0, 'upstream logs why');
    } finally {
      console.error = originalError;
    }
  });

  test('text truncate: structure, styles, a11y, render-prop block and tooltip', async function (assert) {
    await render(
      <template>
        <EuiTextTruncate
          @text={{TEXT}}
          @width={{120}}
          @css={{hash maxWidth="300px"}}
          @toolTipProps={{hash position="bottom"}}
          style={{FONT}}
          data-truncate
          as |text|
        ><mark data-mark>{{text}}</mark></EuiTextTruncate>
        <EuiTextTruncate @text="short" @width={{500}} data-short as |text|><mark data-short-mark>{{text}}</mark></EuiTextTruncate>
      </template>
    );
    const root = el(this.element, '[data-truncate]');
    const rootStyle = getComputedStyle(root);
    assert.strictEqual(rootStyle.position, 'relative');
    assert.strictEqual(rootStyle.overflow, 'hidden');
    assert.strictEqual(rootStyle.whiteSpace, 'nowrap');
    assert.strictEqual(rootStyle.maxWidth, '300px', '@css composed last');

    const truncated = el(root, '[data-test-subj="truncatedText"]');
    assert.dom(truncated).hasTagName('span').hasClass('euiTextTruncate__truncatedText').hasAttribute('aria-hidden', 'true');
    assert.strictEqual(getComputedStyle(truncated).userSelect, 'none');
    assert.strictEqual(getComputedStyle(truncated).pointerEvents, 'none');
    assert.dom('[data-mark]', truncated).hasText(expected(root, 120, 'end'), 'block renders the truncated text');

    const full = el(root, '[data-test-subj="fullText"]');
    assert.dom(full).hasClass('euiTextTruncate__fullText').hasText(TEXT).doesNotHaveAttribute('aria-hidden');
    assert.dom('mark', full).doesNotExist('full text is plain');
    const fullStyle = getComputedStyle(full);
    assert.strictEqual(fullStyle.position, 'absolute');
    assert.strictEqual(fullStyle.inset, '0px');
    assert.strictEqual(fullStyle.overflow, 'hidden');
    assert.strictEqual(fullStyle.color, 'rgba(0, 0, 0, 0)', 'invisible but selectable on top');
    assert.strictEqual(root.textContent!.replace(/\s+/g, ' ').includes(TEXT), true, 'full text in the accessible content');

    const short = el(this.element, '[data-short]');
    assert.dom('[data-test-subj="truncatedText"]', short).doesNotExist();
    const shortFull = el(short, '[data-test-subj="fullText"]');
    assert.strictEqual(shortFull.className, 'euiTextTruncate__fullText', 'no overlay styles when not truncating');
    assert.dom('[data-short-mark]', shortFull).hasText('short', 'block receives the full text');

    // Tooltip with the full text while truncating (not announced twice)
    await triggerEvent(root, 'mousemove');
    await waitUntil(() => document.querySelector('[role="tooltip"]'));
    const tip = document.querySelector('[role="tooltip"]')!;
    assert.dom(tip).hasText(TEXT).hasClass('euiToolTip');
    assert.dom(root).doesNotHaveAttribute('aria-describedby', 'disableScreenReaderOutput');
    await triggerEvent(root, 'mouseout', { relatedTarget: document.body });
    assert.dom('[role="tooltip"]').doesNotExist();

    await triggerEvent(short, 'mousemove');
    assert.dom('[role="tooltip"]').doesNotExist('no tooltip without truncation');
  });

  test('text truncate: resize observer measures, recalculates and calls @onResize; cleaned up on teardown', async function (assert) {
    const Original = window.ResizeObserver;
    const live = new Set<ResizeObserver>();
    class Counting extends Original {
      observe(target: Element, options?: ResizeObserverOptions) {
        if (target.classList.contains('euiTextTruncate')) live.add(this);
        super.observe(target, options);
      }
      disconnect() {
        live.delete(this);
        super.disconnect();
      }
    }
    window.ResizeObserver = Counting;
    try {
      class State {
        @tracked width: number | undefined = undefined;
      }
      const state = new State();
      const widths: number[] = [];
      const onResize = (width: number) => widths.push(width);
      await render(
        <template>
          <div style="width: 240px" data-wrapper>
            <EuiTextTruncate @text={{TEXT}} @width={{state.width}} @onResize={{onResize}} style={{FONT}} data-truncate />
          </div>
        </template>
      );
      const wrapper = el(this.element, '[data-wrapper]');
      const root = el(this.element, '[data-truncate]');
      assert.dom(root).hasAttribute('data-resize-observer', 'true');
      assert.deepEqual(widths, [240], 'measured on mount');
      assert.strictEqual(live.size, 1, 'one observer');
      assert.dom('[data-test-subj="truncatedText"]', root).hasText(expected(root, 240, 'end'));

      wrapper.style.width = '120px';
      await waitUntil(() => widths.length === 2);
      await settled();
      assert.deepEqual(widths, [240, 120], 'resize reported');
      assert.strictEqual(el(this.element, '[data-truncate]'), root, 'root kept');
      assert.dom('[data-test-subj="truncatedText"]', root).hasText(expected(root, 120, 'end'), 'recalculated');

      wrapper.style.width = '2000px';
      await waitUntil(() => widths.length === 3);
      await settled();
      assert.dom('[data-test-subj="truncatedText"]', root).doesNotExist('wide again: full text only');

      state.width = 100;
      await settled();
      assert.strictEqual(live.size, 0, '@width disconnects the observer');
      assert.dom(root).doesNotHaveAttribute('data-resize-observer');
      assert.dom('[data-test-subj="truncatedText"]', root).hasText(expected(root, 100, 'end'));
      wrapper.style.width = '300px';
      await layoutSettled();
      assert.strictEqual(widths.length, 3, 'no @onResize with @width');

      state.width = undefined;
      await settled();
      assert.strictEqual(live.size, 1, 'observing again');
      assert.dom('[data-test-subj="truncatedText"]', root).hasText(expected(root, 300, 'end'));

      await clearRender();
      assert.strictEqual(live.size, 0, 'observer disconnected on teardown');
    } finally {
      window.ResizeObserver = Original;
    }
  });

  test('text truncate: calculationDelayMs shows the full text until the delay passes; RTL', async function (assert) {
    const rendering = render(
      <template>
        <EuiTextTruncate @text={{TEXT}} @width={{120}} @calculationDelayMs={{150}} style={{FONT}} data-delayed />
        <div dir="rtl">
          <EuiTextTruncate @text={{TEXT}} @width={{120}} @truncation="start" style={{FONT}} data-rtl />
        </div>
      </template>
    );
    await waitUntil(() => find('[data-delayed] [data-test-subj="fullText"]'));
    assert.dom('[data-delayed] [data-test-subj="truncatedText"]').doesNotExist('not truncated before the delay');
    assert.dom('[data-delayed] [data-test-subj="fullText"]').hasText(TEXT);
    await rendering;
    const delayed = el(this.element, '[data-delayed]');
    assert.dom('[data-test-subj="truncatedText"]', delayed).hasText(expected(delayed, 120, 'end'), 'truncated after the delay');

    const rtl = el(this.element, '[data-rtl]');
    const text = el(rtl, '[data-test-subj="truncatedText"]').textContent!;
    assert.strictEqual(text, expected(rtl, 120, 'start'));
    assert.true(text.startsWith('…'), 'logical start in the text');
    const full = el(rtl, '[data-test-subj="fullText"]');
    assert.strictEqual(full.offsetWidth, rtl.offsetWidth, 'overlay covers the box (inset)');
    assert.true(el(rtl, '[data-test-subj="truncatedText"]').offsetWidth <= 121);
  });

  // ---------------------------------------------------- Text block truncate

  test('text block truncate: clamps lines (wrapper and cloned element), reactive without replacement', async function (assert) {
    class State {
      @tracked lines = 2;
      @tracked css: Record<string, string> = { marginTop: '0px' };
    }
    const state = new State();
    const long = `${TEXT}. ${TEXT}. ${TEXT}. ${TEXT}.`;
    await render(
      <template>
        <div style="width: 200px; font-size: 14px; line-height: 20px">
          <EuiTextBlockTruncate @lines={{state.lines}} style="color: rgb(1, 2, 3)" data-block>{{long}}</EuiTextBlockTruncate>
          <EuiTextBlockTruncate @lines={{state.lines}} @cloneElement={{true}} @css={{state.css}} as |clamp|>
            <p class="own" {{clamp}} data-cloned>{{long}}</p>
          </EuiTextBlockTruncate>
          <EuiTextBlockTruncate @lines={{3}} data-short>Short text</EuiTextBlockTruncate>
        </div>
      </template>
    );
    const block = el(this.element, '[data-block]');
    assert.dom(block).hasTagName('div').hasClass('euiTextBlockTruncate');
    const style = getComputedStyle(block);
    // Chromium 130+ computes line-clamped `-webkit-box` as `flow-root`
    assert.true(['-webkit-box', 'flow-root'].includes(style.display), `display ${style.display}`);
    assert.strictEqual(style.webkitBoxOrient, 'vertical');
    assert.strictEqual(style.overflow, 'hidden');
    assert.strictEqual(style.webkitLineClamp, '2');
    assert.strictEqual(block.style.getPropertyValue('-webkit-line-clamp'), '2', 'inline, like upstream');
    assert.strictEqual(style.color, 'rgb(1, 2, 3)', 'caller style kept');
    assert.strictEqual(block.offsetHeight, 40, '2 lines tall');
    assert.true(block.scrollHeight > 40, 'the rest is clipped');

    const cloned = el(this.element, '[data-cloned]');
    assert.dom(cloned).hasTagName('p').hasClass('own').hasClass('euiTextBlockTruncate');
    assert.strictEqual(cloned.parentElement!.tagName, 'DIV', 'no wrapper: the p sits in the test container');
    assert.dom('[data-cloned]').exists({ count: 1 });
    assert.strictEqual(getComputedStyle(cloned).webkitLineClamp, '2');
    assert.strictEqual(getComputedStyle(cloned).marginTop, '0px', '@css composed into the clone class');
    assert.strictEqual(cloned.offsetHeight, 40);

    state.lines = 3;
    await settled();
    assert.strictEqual(el(this.element, '[data-block]'), block, 'wrapper kept');
    assert.strictEqual(el(this.element, '[data-cloned]'), cloned, 'clone kept');
    assert.strictEqual(getComputedStyle(block).webkitLineClamp, '3');
    assert.strictEqual(block.offsetHeight, 60, '3 lines tall');
    assert.strictEqual(cloned.offsetHeight, 60);
    assert.dom(cloned).hasClass('own').hasClass('euiTextBlockTruncate', 'classes kept after the swap');
    const classCount = cloned.classList.length;

    state.css = { marginTop: '3px' };
    await settled();
    assert.strictEqual(el(this.element, '[data-cloned]'), cloned, 'clone kept on @css change');
    assert.strictEqual(getComputedStyle(cloned).marginTop, '3px', 'new @css applied');
    assert.strictEqual(cloned.classList.length, classCount, 'the old Emotion class was swapped, not accumulated');
    assert.strictEqual(getComputedStyle(cloned).webkitLineClamp, '3');

    assert.strictEqual(el(this.element, '[data-short]').offsetHeight, 20, 'short text: one line');

    await clearRender();
    assert.dom('.euiTextBlockTruncate').doesNotExist('teardown');
  });
  // ------------------------------------------------------------- Providers

  test('providers: text follows the nearest provider, overlay stays invisible, forced contrast, sibling isolation', async function (assert) {
    class State {
      @tracked contrast: EuiBorealisHighContrastMode = false;
    }
    const state = new State();
    await render(
      <template>
        <EuiEmotionProvider @highContrastMode={{state.contrast}}>
          <EuiTextTruncate @text={{TEXT}} @width={{120}} style={{FONT}} data-light />
          <EuiTextBlockTruncate @lines={{1}} data-light-block>{{TEXT}}</EuiTextBlockTruncate>
          <EuiEmotionProvider @colorMode="dark">
            <EuiTextTruncate @text={{TEXT}} @width={{120}} style={{FONT}} data-dark />
          </EuiEmotionProvider>
        </EuiEmotionProvider>
        <EuiEmotionProvider @colorMode="dark">
          <EuiTextTruncate @text={{TEXT}} @width={{120}} style={{FONT}} data-sibling />
        </EuiEmotionProvider>
      </template>
    );
    const part = (root: string, name: string) =>
      el(this.element, `[${root}] [data-test-subj="${name}"]`);
    assert.strictEqual(getComputedStyle(part('data-light', 'truncatedText')).color, rgb(light.colors.textParagraph), 'light paragraph color');
    assert.strictEqual(getComputedStyle(part('data-dark', 'truncatedText')).color, rgb(dark.colors.textParagraph), 'nested dark provider wins');
    assert.strictEqual(getComputedStyle(el(this.element, '[data-light-block]')).color, rgb(light.colors.textParagraph));
    for (const root of ['data-light', 'data-dark']) {
      assert.strictEqual(getComputedStyle(part(root, 'fullText')).color, 'rgba(0, 0, 0, 0)', `${root}: overlay transparent`);
      assert.strictEqual(getComputedStyle(part(root, 'fullText')).forcedColorAdjust, 'auto', `${root}: no forced-color opt-out by default`);
    }

    const lightRoot = el(this.element, '[data-light]');
    state.contrast = 'forced';
    await settled();
    assert.strictEqual(el(this.element, '[data-light]'), lightRoot, 'root kept');
    assert.strictEqual(
      getComputedStyle(part('data-light', 'fullText')).forcedColorAdjust,
      'none',
      'forced contrast keeps the overlay transparent (upstream preventForcedColors)'
    );
    assert.strictEqual(
      getComputedStyle(part('data-dark', 'fullText')).forcedColorAdjust,
      'none',
      'nested provider inherits the contrast mode'
    );
    assert.strictEqual(
      getComputedStyle(part('data-sibling', 'fullText')).forcedColorAdjust,
      'auto',
      'sibling provider isolated'
    );
    assert.strictEqual(getComputedStyle(part('data-sibling', 'truncatedText')).color, rgb(dark.colors.textParagraph));
  });
});
