import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { tracked } from '@glimmer/tracking';
import {
  click,
  render,
  settled,
  triggerKeyEvent,
  waitFor,
  waitUntil
} from '@ember/test-helpers';

import EuiCodeBlock, { isRichCodeContent } from '#src/components/eui-code-block.gts';
import EuiIcon from '#src/components/eui-icon.gts';
import EuiMarkdownFormat from '#src/components/eui-markdown-format.gts';
import EuiTitle from '#src/components/eui-title.gts';

const JS = "const a = 'x';\n\nfunction f(n) {\n  return 42;\n}";
const JSON_LINES = Array.from({ length: 40 }, (_, i) => `"key${i}": ${i},`).join('\n');

function el(selector: string, root: ParentNode = document): HTMLElement {
  const element = root.querySelector<HTMLElement>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

function rootOf(selector: string) {
  return el(selector).closest<HTMLElement>('.euiCodeBlock')!;
}

/** Records what EuiCopy copies (it selects the text and runs `copy`). */
function stubCopy() {
  const copied: string[] = [];
  const original = document.execCommand.bind(document);
  document.execCommand = ((command: string) => {
    if (command === 'copy') copied.push(window.getSelection()?.toString() ?? '');
    return true;
  }) as typeof document.execCommand;
  return { copied, restore: () => (document.execCommand = original) };
}

function fragment(html: string) {
  const div = document.createElement('div');
  div.innerHTML = html;
  return div;
}

class State {
  @tracked rich = false;
}

module('Integration | Component | eui-code-block rich content', function (hooks) {
  setupRenderingTest(hooks);

  test('isRichCodeContent: text, pre/code wrappers around text, anything else is rich', function (assert) {
    assert.false(isRichCodeContent(fragment('')), 'empty');
    assert.false(isRichCodeContent(fragment('const a = 1;')), 'text');
    assert.false(isRichCodeContent(fragment('<!-- c -->a<!-- d -->b')), 'text and comments');
    assert.false(isRichCodeContent(fragment('<code>a</code>')), '<code>');
    assert.false(isRichCodeContent(fragment('<pre>a</pre>')), '<pre>');
    assert.false(isRichCodeContent(fragment('\n  <pre><code class="language-js">a &lt;b&gt;</code></pre>\n')), 'docfy <pre><code> with whitespace around');
    assert.true(isRichCodeContent(fragment('<span>a</span>')), 'a span');
    assert.true(isRichCodeContent(fragment('<b>a</b> b')), 'inline markup');
    assert.true(isRichCodeContent(fragment('a <code>b</code>')), 'text beside a wrapper');
    assert.true(isRichCodeContent(fragment('<code>a</code><code>b</code>')), 'two wrappers');
    assert.true(isRichCodeContent(fragment('<code><pre>a</pre></code>')), 'pre inside code');
    assert.true(isRichCodeContent(fragment('<pre><code><span class="token">a</span></code></pre>')), 'pre-highlighted markup');
    assert.true(isRichCodeContent(fragment('<svg></svg>')), 'an icon');
  });

  test('text: a string is highlighted with line numbers and copies its source', async function (assert) {
    const copy = stubCopy();
    try {
      await render(
        <template>
          <EuiCodeBlock @language="js" @lineNumbers={{true}} @isCopyable={{true}} data-text>{{JS}}</EuiCodeBlock>
        </template>
      );
      await waitFor('[data-text] .token');

      assert.dom('[data-text] .euiCodeBlock__lineNumber').exists({ count: 5 });
      await click(el('[data-test-subj="euiCodeBlockCopy"]', rootOf('[data-text]')));
      assert.deepEqual(copy.copied, [JS], 'the source, blank line kept');
    } finally {
      copy.restore();
    }
  });

  test('text: docfy-shaped <pre><code class="language-x"> is still highlighted', async function (assert) {
    const copy = stubCopy();
    try {
      await render(
        <template>
          <EuiCodeBlock @language="js" @lineNumbers={{true}} @isCopyable={{true}} data-docfy>
            <pre><code class="language-js">const a = 'x';
function f(n) {
  return 42;
}
</code></pre>
          </EuiCodeBlock>
        </template>
      );
      await waitFor('[data-docfy] .token.keyword');

      const docfy = el("[data-docfy]");
      assert.dom('pre', docfy).doesNotExist('the wrapper is not rendered');
      assert.dom('.language-js', docfy).doesNotExist();
      assert.dom('.euiCodeBlock__lineNumber', docfy).exists({ count: 4 });
      assert.strictEqual(docfy.textContent, "const a = 'x';\nfunction f(n) {\n  return 42;\n}");

      await click(el('[data-test-subj="euiCodeBlockCopy"]', rootOf('[data-docfy]')));
      assert.deepEqual(copy.copied, ["const a = 'x';\nfunction f(n) {\n  return 42;\n}"]);
    } finally {
      copy.restore();
    }
  });

  test('text: markdown code is still highlighted', async function (assert) {
    const markdown = '```js\nconst a = 1;\n```';
    await render(<template><EuiMarkdownFormat @value={{markdown}} /></template>);
    await waitFor('.euiCodeBlock .token.keyword');

    assert.dom('.euiCodeBlock code.euiCodeBlock__code').hasText('const a = 1;');
    assert.dom('.euiCodeBlock code pre').doesNotExist();
  });

  test('rich: rendered as-is, without highlighting, line numbers or virtualization', async function (assert) {
    const lineNumbers = { highlight: '1', annotations: { 1: 'note' } };
    await render(
      <template>
        <EuiCodeBlock @language="js" @lineNumbers={{lineNumbers}} data-rich><b class="kw">const</b> a = 1;<EuiIcon @type="copy" class="rich-icon" /></EuiCodeBlock>
        <EuiCodeBlock @language="js" @isVirtualized={{true}} @overflowHeight={{100}} data-rich-virtual><span class="rich-span">const</span> b = 2;</EuiCodeBlock>
      </template>
    );
    await waitFor('[data-rich] .kw');
    await waitFor('[data-rich-virtual] .rich-span');

    const code = el('[data-rich]');
    assert.dom(code).hasTagName('code').hasClass('euiCodeBlock__code').hasAttribute('data-code-language', 'js');
    assert.strictEqual(code.parentElement?.tagName, 'PRE');
    assert.dom('.kw', code).hasText('const', 'markup kept');
    assert.dom('.rich-icon', code).exists('components rendered');
    assert.dom('.token', code).doesNotExist('not highlighted');
    assert.dom('.euiCodeBlock__line', code).doesNotExist('no lines');
    assert.dom('.euiCodeBlock__lineNumber', code).doesNotExist('no line numbers');
    assert.dom('[data-test-subj="euiCodeBlockAnnotationIcon"]', code).doesNotExist('no annotations');
    assert.dom('.kw').exists({ count: 1 }, 'rendered once (the detection copy is gone)');

    const virtual = el('[data-rich-virtual]');
    assert.dom('.rich-span', virtual).hasText('const');
    assert.dom(virtual).doesNotHaveClass(/isVirtualized/, 'not virtualized');
    assert.strictEqual(getComputedStyle(virtual.parentElement!).whiteSpace, 'pre-wrap', 'default white space');
  });

  test('rich: copy uses the rendered text; full screen and overflow work', async function (assert) {
    const copy = stubCopy();
    try {
      await render(
        <template>
          <EuiCodeBlock @isCopyable={{true}} @overflowHeight={{60}} data-rich><b>line one</b>


line two
line three
line four
line five</EuiCodeBlock>
        </template>
      );
      await waitFor('[data-rich] b');
      const root = rootOf('[data-rich]');
      const pre = el('pre', root);

      await waitUntil(() => pre.getAttribute('tabindex') === '0');
      assert.dom(pre).hasAttribute('tabindex', '0', 'overflowing rich content is focusable');

      await click(el('[data-test-subj="euiCodeBlockCopy"]', root));
      assert.deepEqual(
        copy.copied,
        ['line one\nline two\nline three\nline four\nline five'],
        'innerText, blank lines collapsed (upstream)'
      );

      await click(el('.euiCodeBlock__fullScreenButton', root));
      await waitUntil(() => document.querySelector('.euiCodeBlockFullScreen code b'));
      const dialog = el('.euiCodeBlockFullScreen');
      assert.dom(dialog.querySelector('code b')).hasText('line one', 'rich content in full screen');
      assert.notOk(dialog.querySelector('.token'));
      await triggerKeyEvent(el('pre', dialog), 'keydown', 'Escape');
      assert.notOk(document.querySelector('.euiCodeBlockFullScreen'));
      assert.dom('[data-rich] b').hasText('line one', 'inline content kept');
    } finally {
      copy.restore();
    }
  });

  test('switching between text and rich content updates in place', async function (assert) {
    const state = new State();
    await render(
      <template>
        <EuiCodeBlock @language="js" data-switch>{{#if state.rich}}<span class="rich">const</span> a{{else}}const a = 1;{{/if}}</EuiCodeBlock>
      </template>
    );
    await waitFor('[data-switch] .token');

    state.rich = true;
    await waitFor('[data-switch] .rich');
    await settled();
    assert.dom('[data-switch] .token').doesNotExist();
    assert.dom('[data-switch]').hasText('const a');

    state.rich = false;
    await waitFor('[data-switch] .token');
    await settled();
    assert.dom('[data-switch] .rich').doesNotExist();
    assert.dom('[data-switch]').hasText('const a = 1;');
  });

  test('the error message title is rendered inside the code block', async function (assert) {
    await render(
      <template>
        <EuiCodeBlock data-error><EuiTitle @size="xs"><p>Error</p></EuiTitle>Error: boom</EuiCodeBlock>
      </template>
    );
    await waitFor('[data-error] .euiTitle');
    assert.dom('[data-error] .euiTitle').hasText('Error');
    assert.dom('[data-error]').hasText('Error Error: boom');
  });

  test('virtualized: annotations render in the rows and in full screen (upstream)', async function (assert) {
    const Note = <template><span data-test-subj="annotation1">Annotation <a href="#">1</a></span></template>;
    const lineNumbers = { start: 32, highlight: '33-42', annotations: { 35: Note, 70: 'Annotation 2' } };
    await render(
      <template>
        <div data-virtual-block><EuiCodeBlock @language="json" @isVirtualized={{true}} @overflowHeight={{200}} @lineNumbers={{lineNumbers}} >{{JSON_LINES}}</EuiCodeBlock></div>
      </template>
    );
    await waitFor('[data-virtual-block] code [data-test-subj="euiCodeBlockAnnotationIcon"]');

    const code = el('[data-virtual-block] code');
    assert.dom(code).hasClass(/isVirtualized/);
    const icon = el('[data-test-subj="euiCodeBlockAnnotationIcon"]', code);
    assert.strictEqual(icon.closest('.euiCodeBlock__line')?.querySelector('[data-line-number]')?.getAttribute('data-line-number'), '35');
    assert.dom(icon).hasAria('label', 'Click to view a code annotation for line 35');

    await click(icon);
    await waitUntil(() => document.querySelector('[data-test-subj="annotation1"]'));
    assert.dom(document.querySelector('[data-test-subj="annotation1"]')).hasText('Annotation 1', 'component note');
    await triggerKeyEvent(document.activeElement!, 'keydown', 'Escape');

    const root = el('[data-virtual-block] .euiCodeBlock');
    const pre = el('pre', root);
    pre.scrollTop = pre.scrollHeight;
    await waitUntil(() => code.querySelector('[data-line-number="70"]'), { timeout: 5000 });
    const last = el('[data-line-number="70"]', code).closest<HTMLElement>('.euiCodeBlock__line')!;
    await waitUntil(() => last.querySelector('[data-test-subj="euiCodeBlockAnnotationIcon"]'));
    await click(el('[data-test-subj="euiCodeBlockAnnotationIcon"]', last));
    await waitUntil(() =>
      Array.from(document.querySelectorAll('[data-test-subj="euiCodeBlockAnnotationPopover"]')).some((p) => p.textContent?.includes('Annotation 2'))
    );
    assert.ok(true, 'a row scrolled into view gets its annotation');
    await triggerKeyEvent(document.activeElement!, 'keydown', 'Escape');

    await click(el('.euiCodeBlock__fullScreenButton', root));
    await waitUntil(() => document.querySelector('.euiCodeBlockFullScreen [data-test-subj="euiCodeBlockAnnotationIcon"]'));
    const fullScreenIcon = document.querySelector<HTMLElement>('.euiCodeBlockFullScreen [data-test-subj="euiCodeBlockAnnotationIcon"]')!;
    assert.dom(fullScreenIcon).hasAria('label', 'Click to view a code annotation for line 35');
    await click(fullScreenIcon);
    await waitUntil(() =>
      Array.from(document.querySelectorAll('[data-test-subj="euiCodeBlockAnnotationPopover"]')).some((p) => p.querySelector('[data-test-subj="annotation1"]'))
    );
    assert.ok(true, 'annotations open in full screen');
  });
});
