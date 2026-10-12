import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import {
  click,
  find,
  focus,
  render,
  settled,
  triggerKeyEvent,
  waitFor,
  waitUntil
} from '@ember/test-helpers';

import EuiCodeBlock from '#src/components/eui-code-block.gts';
import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import { euiFontSize } from '#src/utils/eui/styles.generated.ts';
import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';

import type { EuiBorealisHighContrastMode, EuiBorealisOverrides } from '#src/utils/eui/theme.ts';
import type { EuiColorMode } from '#src/utils/emotion/theme.ts';

const lightContext = resolveBorealisTheme('light');
const light = lightContext.euiTheme;
const dark = resolveBorealisTheme('dark').euiTheme;

const JS = "const a = 'x'; // note\nfunction f(n) {\n  return 42;\n}";
const LONG = Array.from({ length: 60 }, (_, i) => `const line${i} = ${i};`).join('\n');
const HL1 = { highlight: '1' };
const JS_TOKENS = "class A {}\nconst a = 'x'; // note\nfunction f(n) { return n > 42 ? true : false; }";
const CSS_TOKENS = '@media screen { .title #main { color: red !important; } }';
const HTML_TOKENS = '<!-- hi --><div class="x">hi</div>';
const JSON_TOKENS = '{"key": 1, "name": "x", "on": true}';
const HUGE = Array.from({ length: 500 }, (_, i) => `const line${i} = ${i};`).join('\n');

function el(selector: string, root: ParentNode = document): HTMLElement {
  const element = root.querySelector<HTMLElement>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

function css(target: string | Element, pseudo?: string) {
  return getComputedStyle(typeof target === 'string' ? el(target) : target, pseudo);
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

/** A rem value in px for the current root font size. */
function remPx(value: string) {
  return parseFloat(value) * parseFloat(getComputedStyle(document.documentElement).fontSize);
}

function fontSizeFor(size: 'xs' | 's' | 'm') {
  return remPx((euiFontSize(lightContext, size) as { fontSize: string }).fontSize);
}

/** Computed px lengths match within rounding. */
function near(actual: string, expected: number) {
  return Math.abs(parseFloat(actual) - expected) < 0.05;
}

/** Portaled content lives outside the test container. */
function inDocument(selector: string) {
  return document.querySelector<HTMLElement>(selector);
}

async function highlighted(root: string) {
  await waitUntil(() => document.querySelector(`${root} .token`), { timeout: 5000 });
}

class State {
  @tracked fontSize: 's' | 'm' | 'l' = 's';
  @tracked paddingSize: 'none' | 's' | 'm' | 'l' = 'l';
  @tracked transparent = false;
  @tracked whiteSpace: 'pre' | 'pre-wrap' = 'pre-wrap';
  @tracked language = 'js';
  @tracked code = JS;
  @tracked lineNumbers: boolean | { start?: number; highlight?: string } = false;
  @tracked mode: EuiColorMode = 'dark';
  @tracked overrides: EuiBorealisOverrides = {};
  @tracked contrast: EuiBorealisHighContrastMode = false;
}

module('Integration | Component | Borealis code block family', function (hooks) {
  setupRenderingTest(hooks);

  test('default structure, upstream surface styles, label and attributes', async function (assert) {
    await render(
      <template>
        <EuiCodeBlock @language="js" @className="custom-root" data-code class="extra">{{JS}}</EuiCodeBlock>
      </template>
    );
    await highlighted('[data-code]');

    const root = el('.euiCodeBlock');
    const pre = el('pre.euiCodeBlock__pre', root);
    const code = el('code.euiCodeBlock__code', pre);
    assert.dom(root).hasTagName('div').hasClass('custom-root', '@className goes on the root');
    assert.dom(code).hasAttribute('data-code').hasClass('extra', '...attributes go on <code>').hasAttribute('data-code-language', 'js');
    assert.dom(root).doesNotHaveClass('euiCodeBlock--fontSmall').doesNotHaveClass('euiCodeBlock--paddingLarge');

    const rootStyle = css(root);
    assert.strictEqual(rootStyle.display, 'block');
    assert.strictEqual(rootStyle.position, 'relative');
    assert.strictEqual(rootStyle.maxWidth, '100%');
    assert.strictEqual(rootStyle.borderTopLeftRadius, light.border.radius.control);
    assert.strictEqual(rootStyle.backgroundColor, rgb(light.components.codeBackground));
    assert.true(near(rootStyle.fontSize, fontSizeFor('xs')), `default font size s = euiFontSize xs (${rootStyle.fontSize})`);

    const codeStyle = css(code);
    assert.true(codeStyle.fontFamily.includes('Roboto Mono'), 'code font family');
    assert.strictEqual(codeStyle.fontSize, rootStyle.fontSize, 'code inherits the font size');
    assert.strictEqual(codeStyle.color, rgb(light.colors.textParagraph));
    assert.strictEqual(codeStyle.display, 'block');

    const preStyle = css(pre);
    assert.strictEqual(preStyle.paddingTop, light.size.l, 'default padding l');
    assert.strictEqual(preStyle.paddingInlineEnd, light.size.l, 'no controls offset without controls');
    assert.strictEqual(preStyle.whiteSpace, 'pre-wrap', 'default white space');
    assert.strictEqual(preStyle.overflow, 'auto');
    assert.strictEqual(preStyle.marginTop, '0px');

    // upstream: pre tags can't take aria-label, a hidden label precedes the code
    const label = el('.euiScreenReaderOnly', pre);
    assert.dom(label).hasText('js code block:');
    assert.strictEqual(css(label).position, 'absolute');
    assert.strictEqual(pre.firstElementChild, label, 'label comes first');
    assert.dom(pre).hasAttribute('tabindex', '-1', 'not focusable when nothing overflows');
    assert.dom('.euiCodeBlock__controls').doesNotExist('no controls by default');
    assert.dom(code).hasText(JS.replace(/\n\s*/g, ' ').replace(/\s+/g, ' '));
  });

  test('font sizes and padding sizes are measured and update in place', async function (assert) {
    const state = new State();
    await render(
      <template>
        <EuiCodeBlock
          @language="js"
          @fontSize={{state.fontSize}}
          @paddingSize={{state.paddingSize}}
          @transparentBackground={{state.transparent}}
          @whiteSpace={{state.whiteSpace}}
          data-code
        >{{state.code}}</EuiCodeBlock>
      </template>
    );
    await highlighted('[data-code]');
    const root = el('.euiCodeBlock');
    const pre = el('pre', root);
    const code = el('code', root);

    for (const [size, scale] of [['m', 's'], ['l', 'm'], ['s', 'xs']] as const) {
      state.fontSize = size;
      await settled();
      assert.true(near(css(root).fontSize, fontSizeFor(scale)), `font ${size}: ${css(root).fontSize}`);
      assert.true(near(css(root).lineHeight, remPx((euiFontSize(lightContext, scale) as { lineHeight: string }).lineHeight)), `line height ${size}: ${css(root).lineHeight}`);
    }

    for (const [size, padding] of [['none', '0px'], ['s', light.size.s], ['m', light.size.base], ['l', light.size.l]] as const) {
      state.paddingSize = size;
      await settled();
      assert.strictEqual(css(pre).paddingTop, padding, `padding ${size}`);
      assert.strictEqual(css(pre).paddingInlineStart, padding, `inline padding ${size}`);
    }

    state.transparent = true;
    state.whiteSpace = 'pre';
    await settled();
    assert.strictEqual(css(root).backgroundColor, 'rgba(0, 0, 0, 0)', 'transparent background');
    assert.strictEqual(css(pre).whiteSpace, 'pre');

    state.code = 'let changed = true;';
    await waitUntil(() => code.textContent === 'let changed = true;');
    assert.strictEqual(el('.euiCodeBlock'), root, 'same root element');
    assert.strictEqual(el('.euiCodeBlock pre'), pre, 'same pre element');
    assert.strictEqual(el('.euiCodeBlock code'), code, 'same code element');
    assert.dom('.token.keyword', code).hasText('let', 're-highlighted');
  });

  test('syntax token colors follow the theme for several languages', async function (assert) {
    await render(
      <template>
        <EuiCodeBlock @language="js" data-js>{{JS_TOKENS}}</EuiCodeBlock>
        <EuiCodeBlock @language="css" data-css>{{CSS_TOKENS}}</EuiCodeBlock>
        <EuiCodeBlock @language="html" data-html>{{HTML_TOKENS}}</EuiCodeBlock>
        <EuiCodeBlock @language="json" data-json>{{JSON_TOKENS}}</EuiCodeBlock>
      </template>
    );
    await highlighted('[data-js]');
    await highlighted('[data-css]');
    await highlighted('[data-html]');
    await highlighted('[data-json]');
    const c = light.components;
    const color = (selector: string) => css(selector).color;
    const text = rgb(light.colors.textParagraph);
    // Borealis leaves some token colors as `inherit` (the code color)
    const token = (value: string) => (value === 'inherit' ? text : rgb(value));

    assert.strictEqual(color('[data-js] .token.keyword'), rgb(c.codeKeywordColor), 'js keyword');
    assert.strictEqual(color('[data-js] .token.string'), rgb(c.codeStringColor), 'js string');
    assert.strictEqual(color('[data-js] .token.number'), rgb(c.codeNumberColor), 'js number');
    assert.strictEqual(color('[data-js] .token.boolean'), rgb(c.codeNumberColor), 'js boolean');
    assert.strictEqual(color('[data-js] .token.class-name'), rgb(c.codeTypeColor), 'js class name');
    assert.strictEqual(color('[data-js] .token.function'), token(c.codeFunctionTitleColor), 'js function');
    assert.strictEqual(color('[data-js] .token.comment'), rgb(c.codeCommentColor), 'js comment');
    assert.strictEqual(css('[data-js] .token.comment').fontStyle, 'italic');
    assert.strictEqual(css('[data-js] .token.punctuation').opacity, '0.7', 'punctuation is dimmed');
    assert.notStrictEqual(rgb(c.codeKeywordColor), rgb(c.codeStringColor), 'distinct token colors');

    assert.strictEqual(color('[data-css] .token.atrule .token.rule'), rgb(c.codeKeywordColor), 'css at-rule');
    assert.strictEqual(color('[data-css] .token.selector'), token(c.codeSelectorColor), 'css selector');
    assert.strictEqual(color('[data-css] .token.property'), token(c.codeAttributeColor), 'css property');
    assert.strictEqual(color('[data-css] .token.important'), rgb(c.codeMetaColor), 'css !important');
    assert.strictEqual(css('[data-css] .token.important').fontWeight, String(light.font.weight.bold));

    assert.strictEqual(color('[data-html] .token.tag'), rgb(c.codeTagColor), 'html tag');
    assert.strictEqual(color('[data-html] .token.attr-name'), rgb(c.codeNumberColor), 'html attribute name');
    assert.strictEqual(color('[data-html] .token.attr-value'), rgb(c.codeStringColor), 'html attribute value');
    assert.strictEqual(color('[data-html] .token.comment'), rgb(c.codeCommentColor), 'html comment');

    assert.dom('[data-json]').hasAttribute('data-code-language', 'json');
    assert.strictEqual(color('[data-json] .token.property'), token(c.codeAttributeColor), 'json property');
    assert.strictEqual(color('[data-json] .token.string'), rgb(c.codeStringColor), 'json string');
    assert.strictEqual(color('[data-json] .token.number'), rgb(c.codeNumberColor), 'json number');
    assert.strictEqual(color('[data-json] .token.boolean'), rgb(c.codeNumberColor), 'json boolean');
  });

  test('line numbers: start, highlight ranges, number column and annotations', async function (assert) {
    const state = new State();
    state.lineNumbers = { start: 9, highlight: '10-11' };
    await render(
      <template>
        <EuiCodeBlock @language="js" @lineNumbers={{state.lineNumbers}} data-lines>{{JS}}</EuiCodeBlock>
        <EuiCodeBlock @language="js" @lineNumbers={{true}} data-plain>a;</EuiCodeBlock>
      </template>
    );
    await highlighted('[data-lines]');

    const lines = [...document.querySelectorAll<HTMLElement>('[data-lines] .euiCodeBlock__line')];
    assert.strictEqual(lines.length, 4);
    assert.deepEqual(
      lines.map((line) => el('.euiCodeBlock__lineNumber', line).getAttribute('data-line-number')),
      ['9', '10', '11', '12'],
      'numbering starts at `start`'
    );
    const [first, second, third] = lines as [HTMLElement, HTMLElement, HTMLElement];
    assert.strictEqual(css(first).display, 'flex', 'line with numbers is a flex row');
    assert.strictEqual(css(first).userSelect, 'none');

    const number = el('.euiCodeBlock__lineNumber', first);
    assert.dom(number).hasAttribute('aria-hidden', 'true').hasText('', 'number is drawn by CSS (not copied)');
    assert.strictEqual(css(number, '::before').content, '"9"', 'content: attr(data-line-number)');
    assert.strictEqual(css(number).color, rgb(light.colors.textSubdued));
    assert.strictEqual(css(number).textAlign, 'end');
    const wrapper = el('.euiCodeBlock__lineNumberWrapper', first);
    assert.strictEqual(css(wrapper).width, '16px', 'two digits × 8px');
    assert.strictEqual(css(wrapper).paddingInlineEnd, light.size.m);

    const text = el('.euiCodeBlock__lineText', first);
    assert.strictEqual(css(text).userSelect, 'text', 'only the code is selectable');
    assert.strictEqual(css(text).borderLeftWidth, light.border.width.thin);
    assert.strictEqual(css(text).borderLeftColor, rgb(light.border.color));
    assert.strictEqual(css(text).paddingLeft, light.size.m);
    assert.strictEqual(css(text).backgroundColor, 'rgba(0, 0, 0, 0)', 'line 9 is not highlighted');

    for (const line of [second, third]) {
      const highlightedText = css(el('.euiCodeBlock__lineText', line));
      assert.strictEqual(highlightedText.backgroundColor, rgb(light.colors.backgroundBasePrimary), 'highlight background');
      assert.strictEqual(highlightedText.borderLeftColor, rgb(light.colors.primary));
      assert.strictEqual(highlightedText.borderLeftWidth, light.border.width.thick);
      assert.strictEqual(highlightedText.paddingLeft, '11px', 'm + thin - thick keeps the text aligned');
    }
    assert.dom('[data-lines] .euiCodeBlock__line--isHighlighted').doesNotExist('legacy highlight class is gone');
    assert.strictEqual(el('.euiCodeBlock__lineNumberWrapper', document.querySelector('[data-plain]')!.closest('.euiCodeBlock')!).style.inlineSize, '8px', 'one digit');

    state.lineNumbers = false;
    await waitUntil(() => !document.querySelector('[data-lines] .euiCodeBlock__lineNumber'));
    assert.strictEqual(css(el('[data-lines] .euiCodeBlock__line')).display, 'block', 'plain lines are blocks');
  });

  test('line annotations open a popover from an accessible button', async function (assert) {
    const lineNumbers = { annotations: { 2: 'Defines f' } };
    await render(
      <template>
        <EuiCodeBlock @language="js" @lineNumbers={{lineNumbers}} data-annotated>{{JS}}</EuiCodeBlock>
      </template>
    );
    await waitFor('[data-test-subj="euiCodeBlockAnnotationIcon"]');

    const buttons = document.querySelectorAll('[data-test-subj="euiCodeBlockAnnotationIcon"]');
    assert.strictEqual(buttons.length, 1, 'one annotation');
    const button = buttons[0] as HTMLElement;
    assert.dom(button).hasTagName('button').hasAria('label', 'Click to view a code annotation for line 2');
    assert.strictEqual(button.closest('.euiCodeBlock__line')?.querySelector('.euiCodeBlock__lineNumber')?.getAttribute('data-line-number'), '2');
    assert.strictEqual(css(button).backgroundColor, rgb(light.colors.primary), 'round primary button');
    assert.strictEqual(css(button).borderTopLeftRadius, '50%');
    assert.strictEqual(css(button).width, '14.5px', 'base − 1.5px');
    assert.strictEqual(css(button).borderTopStyle, 'none', 'scoped button reset');
    assert.strictEqual(css(button).paddingTop, '0px');
    assert.dom('svg', button).exists('info glyph');
    assert.strictEqual(css(button.closest('.euiCodeBlock__lineAnnotation')!).position, 'absolute', 'annotation popover root is positioned (upstream css)');

    await click(button);
    await waitUntil(() => inDocument('[data-test-subj="euiCodeBlockAnnotationPopover"]'));
    const popover = inDocument('[data-test-subj="euiCodeBlockAnnotationPopover"]')!;
    assert.dom(popover).hasText('Defines f');
    const panel = popover.closest<HTMLElement>('.euiPopover__panel')!;
    assert.strictEqual(css(panel).zIndex, String(Number(light.levels.mask) + 1), 'above a full screen mask');

    await triggerKeyEvent(panel, 'keydown', 'Escape');
    await waitUntil(() => !inDocument('[data-test-subj="euiCodeBlockAnnotationPopover"]'));
    assert.notOk(inDocument('[data-test-subj="euiCodeBlockAnnotationPopover"]'), 'Escape closes the popover');
  });

  test('overflow height: scroll region, focusability and control offsets', async function (assert) {
    await render(
      <template>
        <EuiCodeBlock @language="js" @overflowHeight={{120}} @isCopyable={{true}} data-overflow>{{LONG}}</EuiCodeBlock>
        <EuiCodeBlock @language="js" @overflowHeight="80px" @paddingSize="s" @whiteSpace="pre" data-string>{{LONG}}</EuiCodeBlock>
      </template>
    );
    await highlighted('[data-overflow]');
    const root = el('[data-overflow]').closest<HTMLElement>('.euiCodeBlock')!;
    const pre = el('pre', root);

    assert.strictEqual(root.style.maxBlockSize, '120px', 'numbers set max-block-size');
    assert.strictEqual(pre.style.maxBlockSize, '120px');
    assert.true(pre.scrollHeight > pre.clientHeight, 'the pre scrolls');
    await waitUntil(() => pre.getAttribute('tabindex') === '0');
    assert.dom(pre).hasAttribute('tabindex', '0', 'scrollable region is keyboard focusable');

    const controls = el('.euiCodeBlock__controls', root);
    assert.strictEqual(css(controls).position, 'absolute');
    assert.strictEqual(css(controls).top, light.size.l, 'offset by padding l');
    assert.strictEqual(css(controls).right, light.size.l);
    assert.strictEqual(css(controls).rowGap, light.size.xs);
    assert.strictEqual(css(controls).backgroundColor, rgb(light.components.codeBackground));
    assert.dom('.euiCodeBlock__fullScreenButton', controls).hasAria('label', 'Expand');
    assert.dom('[data-test-subj="euiCodeBlockCopy"]', controls).hasAria('label', 'Copy');
    assert.strictEqual(css(root).minHeight, '100px', 'both controls: 2 × 24 + 4 + 2 × 24');
    assert.strictEqual(css(pre).paddingInlineEnd, '52px', 'pre-wrap: room for the controls');

    const other = el('[data-string]').closest<HTMLElement>('.euiCodeBlock')!;
    assert.strictEqual(other.style.blockSize, '80px', 'strings set block-size');
    assert.strictEqual(css(other).minHeight, '40px', 'one control with padding s: 24 + 2 × 8');
    assert.strictEqual(css(el('pre', other)).marginInlineEnd, '36px', 'pre: margin for the controls');
    assert.strictEqual(css(el('.euiCodeBlock__controls', other)).top, light.size.s);
  });

  test('copy button copies the source text and is hidden without text', async function (assert) {
    const copied: string[] = [];
    const original = document.execCommand.bind(document);
    document.execCommand = ((command: string) => {
      if (command === 'copy') copied.push(window.getSelection()?.toString() ?? '');
      return true;
    }) as typeof document.execCommand;

    try {
      const code = 'line one\n\nline three';
      await render(
        <template>
          <EuiCodeBlock @isCopyable={{true}} @lineNumbers={{true}} data-copy>{{code}}</EuiCodeBlock>
          <EuiCodeBlock @isCopyable={{true}} @copyAriaLabel="Copy snippet" data-labelled>x</EuiCodeBlock>
          <EuiCodeBlock @isCopyable={{true}} data-empty></EuiCodeBlock>
        </template>
      );
      await waitFor('[data-test-subj="euiCodeBlockCopy"]');

      const root = el('[data-copy]').closest<HTMLElement>('.euiCodeBlock')!;
      const button = el('[data-test-subj="euiCodeBlockCopy"]', root);
      assert.dom(button.parentElement?.closest('.euiCodeBlock__copyButton')).exists();
      assert.strictEqual(css(root).minHeight, '72px', 'one control: 24 + 2 × 24');
      assert.dom('[data-test-subj="euiCodeBlockCopy"]', el('[data-labelled]').closest('.euiCodeBlock')!).hasAria('label', 'Copy snippet');
      assert.dom('.euiCodeBlock__controls', el('[data-empty]').closest('.euiCodeBlock')!).doesNotExist('nothing to copy');

      await click(button);
      assert.deepEqual(copied, ['line one\n\nline three'], 'copies the source (no line numbers or label, blank lines kept)');
    } finally {
      document.execCommand = original;
    }
  });

  test('full screen: dialog semantics, large font, xl padding, Escape and focus return', async function (assert) {
    await render(
      <template>
        <EuiEmotionProvider>
          <EuiCodeBlock @language="js" @overflowHeight={{100}} @fontSize="s" @paddingSize="s" data-fs>{{LONG}}</EuiCodeBlock>
        </EuiEmotionProvider>
      </template>
    );
    await highlighted('[data-fs]');
    const expand = el('.euiCodeBlock__fullScreenButton');
    await click(expand);
    await waitUntil(() => inDocument('.euiCodeBlockFullScreen code .token'));

    const dialog = inDocument('.euiCodeBlockFullScreen')!;
    assert.dom(dialog).hasAttribute('role', 'dialog').hasAria('modal', 'true').hasAria('label', 'Expanded code block');
    assert.true(dialog.parentElement!.classList.contains('euiOverlayMask'), 'rendered in an overlay mask');
    assert.strictEqual(css(dialog).position, 'fixed');
    assert.deepEqual([css(dialog).top, css(dialog).left, css(dialog).right, css(dialog).bottom], ['0px', '0px', '0px', '0px'], 'covers the viewport');
    assert.true(near(css(dialog).fontSize, fontSizeFor('m')), `forced large font (${css(dialog).fontSize})`);
    assert.strictEqual(css(dialog).backgroundColor, rgb(light.components.codeBackground));
    const pre = el('pre', dialog);
    assert.strictEqual(css(pre).paddingTop, light.size.xl, 'forced xl padding');
    assert.strictEqual(css(pre).paddingInlineEnd, '60px', 'xl + 4 + 24 controls offset');
    assert.dom(pre).hasAttribute('tabindex', '0');
    assert.strictEqual(css(el('.euiCodeBlock__controls', dialog)).top, light.size.l, 'controls offset l');
    assert.dom('code', dialog).hasText(el('[data-fs]').textContent!, 'same highlighted code');
    assert.strictEqual(css(el('.token.keyword', dialog)).color, rgb(light.components.codeKeywordColor), 'tokens colored in the portal');

    await waitUntil(() => dialog.contains(document.activeElement));
    assert.true(dialog.contains(document.activeElement), 'focus moves into the dialog');
    await waitUntil(() => inDocument('.euiCodeBlockFullScreen .euiCodeBlock__fullScreenButton'));
    assert.dom(inDocument('.euiCodeBlockFullScreen .euiCodeBlock__fullScreenButton')).hasAria('label', 'Collapse');

    await triggerKeyEvent(pre, 'keydown', 'Escape');
    assert.notOk(inDocument('.euiCodeBlockFullScreen'), 'Escape closes');
    assert.dom(document.body).doesNotHaveClass('euiBody-hasOverlayMask');
    assert.strictEqual(document.activeElement, el('.euiCodeBlock__fullScreenButton'), 'focus returns to the expand button');

    await click('.euiCodeBlock__fullScreenButton');
    await waitUntil(() => inDocument('.euiCodeBlockFullScreen .euiCodeBlock__fullScreenButton'));
    await click(inDocument('.euiCodeBlockFullScreen .euiCodeBlock__fullScreenButton')!);
    assert.notOk(inDocument('.euiCodeBlockFullScreen'), 'collapse button closes');
    assert.strictEqual(document.activeElement, el('.euiCodeBlock__fullScreenButton'), 'focus returns again');
  });

  test('virtualized: renders a window of rows with upstream row styles', async function (assert) {
    await render(
      <template>
        <EuiCodeBlock @language="js" @isVirtualized={{true}} @overflowHeight={{200}} @fontSize="m" @lineNumbers={{true}} data-virtual>{{HUGE}}</EuiCodeBlock>
      </template>
    );
    await waitFor('code.euiCodeBlock__code[data-code-language="js"] > span.euiCodeBlock__line');

    const root = el('.euiCodeBlock');
    const pre = el('pre.euiCodeBlock__pre', root);
    const code = el('code.euiCodeBlock__code', pre);
    const rows = code.querySelectorAll<HTMLElement>(':scope > span.euiCodeBlock__line');
    assert.true(rows.length > 0 && rows.length < 500, `renders a window (${rows.length} rows)`);
    assert.dom(pre).hasAttribute('tabindex', '0', 'virtualized pre is always focusable');
    assert.strictEqual(css(pre).whiteSpace, 'pre', 'virtualized forces white-space pre');
    assert.strictEqual(css(pre).height, '200px', 'numeric overflow height fixes the list height');
    assert.strictEqual(css(code).position, 'relative', 'code is the rows\' containing block');
    assert.dom('.euiScreenReaderOnly', pre).hasText('js code block:');

    const second = rows[1]!;
    assert.strictEqual(css(second).position, 'absolute');
    assert.strictEqual(second.style.blockSize, '21px', 'row height for font m');
    assert.strictEqual(second.style.insetBlockStart, '21px');
    assert.strictEqual(css(second).display, 'flex', 'line number styles apply to virtual rows');
    assert.strictEqual(el('.euiCodeBlock__lineNumber', second).getAttribute('data-line-number'), '2');

    await click(el('.euiCodeBlock__fullScreenButton', root));
    await waitUntil(() => inDocument('.euiCodeBlockFullScreen code > span.euiCodeBlock__line'));
    const fullScreenRow = document.querySelectorAll<HTMLElement>('.euiCodeBlockFullScreen code > span.euiCodeBlock__line')[1]!;
    assert.strictEqual(fullScreenRow.style.blockSize, '24px', 'full screen rows use the large row height');
    assert.strictEqual(css(inDocument('.euiCodeBlockFullScreen pre')!).paddingTop, light.size.xl);
    await triggerKeyEvent(inDocument('.euiCodeBlockFullScreen pre')!, 'keydown', 'Escape');
    assert.notOk(inDocument('.euiCodeBlockFullScreen'), 'Escape closes the virtualized full screen view');
  });

  test('light/dark: nearest provider, sibling isolation, JS overrides, in place', async function (assert) {
    const state = new State();
    await render(
      <template>
        <EuiEmotionProvider @colorMode={{state.mode}} @borealisOverrides={{state.overrides}} @globalStyles={{false}}>
          <EuiCodeBlock @language="js" @lineNumbers={{true}} data-themed>{{JS}}</EuiCodeBlock>
        </EuiEmotionProvider>
        <EuiEmotionProvider @colorMode="light" @globalStyles={{false}}>
          <EuiCodeBlock @language="js" data-sibling>{{JS}}</EuiCodeBlock>
        </EuiEmotionProvider>
      </template>
    );
    await highlighted('[data-themed]');
    await highlighted('[data-sibling]');
    const root = el('[data-themed]').closest<HTMLElement>('.euiCodeBlock')!;
    const sibling = el('[data-sibling]').closest<HTMLElement>('.euiCodeBlock')!;

    assert.strictEqual(css(root).backgroundColor, rgb(dark.components.codeBackground), 'dark background');
    assert.strictEqual(css(el('[data-themed]')).color, rgb(dark.colors.textParagraph), 'dark text');
    assert.strictEqual(css(el('[data-themed] .token.keyword')).color, rgb(dark.components.codeKeywordColor), 'dark keyword');
    assert.strictEqual(css(el('[data-themed] .euiCodeBlock__lineNumber')).color, rgb(dark.colors.textSubdued), 'dark line numbers');
    assert.strictEqual(css(sibling).backgroundColor, rgb(light.components.codeBackground), 'sibling stays light');
    assert.strictEqual(css(el('[data-sibling] .token.keyword')).color, rgb(light.components.codeKeywordColor));

    const code = el('[data-themed]');
    state.overrides = {
      border: { radius: { control: '20px' } },
      components: {
        LIGHT: { codeBackground: '#ffee00', codeKeywordColor: '#112233' },
        DARK: { codeBackground: '#665500', codeKeywordColor: '#aabbcc' }
      }
    };
    await settled();
    await waitUntil(() => css(el('[data-themed] .token.keyword')).color === 'rgb(170, 187, 204)');
    assert.strictEqual(el('[data-themed]'), code, 'same code element');
    assert.strictEqual(el('[data-themed]').closest('.euiCodeBlock'), root, 'same root element');
    assert.strictEqual(css(root).backgroundColor, 'rgb(102, 85, 0)', 'mode-specific background override');
    assert.strictEqual(css(root).borderTopLeftRadius, '20px', 'radius override');
    assert.strictEqual(css(el('[data-themed] .token.keyword')).color, 'rgb(170, 187, 204)', 'token override');

    state.mode = 'light';
    await settled();
    await waitUntil(() => css(el('[data-themed] .token.keyword')).color === 'rgb(17, 34, 51)');
    assert.strictEqual(css(root).backgroundColor, 'rgb(255, 238, 0)', 'light override');
    assert.strictEqual(css(el('[data-themed] .euiCodeBlock__lineNumber')).color, rgb(light.colors.textSubdued), 'line classes follow the theme');
    assert.strictEqual(css(sibling).backgroundColor, rgb(light.components.codeBackground), 'sibling unaffected');
  });

  test('RTL: controls, padding and line borders are logical', async function (assert) {
    await render(
      <template>
        <div dir="rtl">
          <EuiCodeBlock @language="js" @isCopyable={{true}} @lineNumbers={{HL1}} data-rtl>{{JS}}</EuiCodeBlock>
        </div>
      </template>
    );
    await highlighted('[data-rtl]');
    const root = el('[data-rtl]').closest<HTMLElement>('.euiCodeBlock')!;
    const controls = el('.euiCodeBlock__controls', root);
    assert.strictEqual(css(controls).left, light.size.l, 'controls sit at the inline end (left)');
    assert.strictEqual(css(el('pre', root)).paddingLeft, '52px', 'controls offset on the left');
    const lineText = el('.euiCodeBlock__lineText', root);
    assert.strictEqual(css(lineText).borderRightWidth, light.border.width.thick, 'highlight border on the right');
    assert.strictEqual(css(lineText).borderLeftWidth, '0px');
    const rootBox = root.getBoundingClientRect();
    const number = el('.euiCodeBlock__lineNumberWrapper', root).getBoundingClientRect();
    assert.true(number.right > rootBox.right - 60, 'line numbers start on the right');
  });

  test('high contrast: border, opaque punctuation and wider highlights', async function (assert) {
    const state = new State();
    await render(
      <template>
        <EuiEmotionProvider @highContrastMode={{state.contrast}} @globalStyles={{false}}>
          <EuiCodeBlock @language="js" @lineNumbers={{HL1}} data-hc>{{JS}}</EuiCodeBlock>
        </EuiEmotionProvider>
      </template>
    );
    await highlighted('[data-hc]');
    const root = el('[data-hc]').closest<HTMLElement>('.euiCodeBlock')!;
    assert.strictEqual(css(root).borderTopStyle, 'none', 'no border by default');
    assert.strictEqual(css(el('[data-hc] .token.punctuation')).opacity, '0.7');

    state.contrast = 'preferred';
    await settled();
    await waitUntil(() => css(el('[data-hc] .euiCodeBlock__lineText')).borderLeftWidth === '3px');
    const hc = resolveBorealisTheme('light', {}, 'preferred').euiTheme;
    assert.strictEqual(css(root).borderTopWidth, hc.border.width.thin, 'thin border');
    assert.strictEqual(css(root).borderTopColor, rgb(hc.border.color));
    assert.strictEqual(css(el('[data-hc] .token.punctuation')).opacity, '1', 'punctuation is not dimmed');
    assert.strictEqual(css(el('[data-hc] .euiCodeBlock__lineText')).borderLeftWidth, '3px', 'thick × 1.5 highlight');
    assert.strictEqual(css(el('[data-hc] .euiCodeBlock__lineText')).paddingLeft, '10px', 'm + thin − 3px');
  });

  test('language label, aria label prefix and unsupported languages', async function (assert) {
    await render(
      <template>
        <EuiCodeBlock @language="not-a-language" @ariaLabel="Install script" data-unknown>echo hi</EuiCodeBlock>
      </template>
    );
    await waitUntil(() => el('[data-unknown]').textContent === 'echo hi');
    assert.dom('[data-unknown]').hasAttribute('data-code-language', 'text', 'falls back to text');
    assert.dom('.euiCodeBlock .euiScreenReaderOnly').hasText('Install script, text code block:');
    assert.dom('[data-unknown] .token').doesNotExist();
    assert.ok(find('[data-unknown]'));
    await focus(el('.euiCodeBlock pre'));
    assert.strictEqual(document.activeElement, el('.euiCodeBlock pre'), 'pre takes programmatic focus');
  });
});
