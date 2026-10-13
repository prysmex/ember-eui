import { tracked } from '@glimmer/tracking';
import {
  clearRender,
  click,
  findAll,
  focus,
  render,
  settled,
  triggerEvent,
  triggerKeyEvent,
  waitUntil
} from '@ember/test-helpers';
import { setupRenderingTest } from 'ember-qunit';
import { module, test } from 'qunit';

import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import EuiMarkdownEditor from '#src/components/eui-markdown-editor.gts';
import EuiMarkdownEditorFooter from '#src/components/eui-markdown-editor-footer.gts';
import EuiMarkdownFormat from '#src/components/eui-markdown-format.gts';
import { euiFormVariables } from '#src/utils/eui/styles.generated.ts';
import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';

import type { EuiColorMode } from '#src/utils/emotion/theme.ts';
import type {
  EuiBorealisHighContrastMode,
  EuiBorealisOverrides
} from '#src/utils/eui/theme.ts';
import type {
  EuiMarkdownAstNodePosition,
  EuiMarkdownDropHandler,
  EuiMarkdownParseError
} from '#src/utils/markdown/markdown-types';

const lightTheme = resolveBorealisTheme('light');
const light = lightTheme.euiTheme;
const dark = resolveBorealisTheme('dark').euiTheme;

function el(selector: string, root: ParentNode = document): HTMLElement {
  const element = root.querySelector<HTMLElement>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

function style(selector: string, root: ParentNode = document) {
  return getComputedStyle(el(selector, root));
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

function px(value: string) {
  return parseFloat(value);
}

const content = [
  '# Heading one',
  '',
  '## Heading two',
  '',
  'A paragraph with a [link](https://elastic.co "Elastic") and `inline code`.',
  '',
  '- one',
  '- two',
  '',
  '1. first',
  '',
  '> A quote',
  '',
  '| a | b |',
  '| - | - |',
  '| 1 | 2 |',
  '',
  '---',
  '',
  '```js',
  'const x = 1;',
  '```',
  '',
  'The end.'
].join('\n');

class EditorState {
  @tracked value = 'Some **bold** text';
  changes: string[] = [];

  onChange = (value: string) => {
    this.changes.push(value);
    this.value = value;
  };
}

const pngHandler: EuiMarkdownDropHandler = {
  supportedFiles: ['.png'],
  accepts: (type: string) => type === 'image/png',
  getFormattingForItem: (file: File) => ({
    text: `![${file.name}](blob:${file.name})`,
    config: { block: true }
  })
};

function dragEvent(type: string, files: File[]) {
  const dataTransfer = new DataTransfer();
  files.forEach((file) => dataTransfer.items.add(file));
  return new DragEvent(type, {
    bubbles: true,
    cancelable: true,
    dataTransfer
  });
}

const png = () => new File(['png'], 'cat.png', { type: 'image/png' });
const txt = () => new File(['txt'], 'notes.txt', { type: 'text/plain' });

const tooltip = () => document.querySelector('.euiToolTip');

module('Integration | Component | Borealis markdown family', function (hooks) {
  setupRenderingTest(hooks);

  test('the editor is measured to upstream: toolbar, divider, textarea, footer and radii', async function (assert) {
    const state = new EditorState();
    await render(
      <template>
        <div style="width: 600px">
          <EuiMarkdownEditor
            @value={{state.value}}
            @onChange={{state.onChange}}
            @ariaLabel="Notes"
          />
        </div>
      </template>
    );
    const radius = light.border.radius.panel;
    const thin = px(light.border.width.thin);

    const root = style('.euiMarkdownEditor');
    assert.strictEqual(root.display, 'flex');
    assert.strictEqual(root.flexDirection, 'column');
    assert.strictEqual(root.boxSizing, 'border-box');

    const toolbar = style('.euiMarkdownEditorToolbar');
    assert.strictEqual(toolbar.display, 'flex');
    assert.strictEqual(toolbar.flexWrap, 'wrap');
    assert.strictEqual(toolbar.paddingTop, light.size.xs);
    assert.strictEqual(toolbar.paddingInlineStart, light.size.xs);
    assert.strictEqual(toolbar.backgroundColor, rgb(light.colors.lightestShade));
    assert.strictEqual(px(toolbar.borderTopWidth), thin);
    assert.strictEqual(toolbar.borderTopColor, rgb(light.border.color));
    assert.strictEqual(toolbar.borderBottomStyle, 'none', 'no bottom border');
    assert.strictEqual(toolbar.borderTopLeftRadius, radius);
    assert.strictEqual(toolbar.borderTopRightRadius, radius);
    assert.strictEqual(toolbar.borderBottomLeftRadius, '0px');

    const buttons = style('.euiMarkdownEditorToolbar__buttons');
    assert.strictEqual(buttons.display, 'flex');
    assert.strictEqual(buttons.columnGap, light.size.xs);
    assert.strictEqual(buttons.alignItems, 'center');
    assert.strictEqual(buttons.flexGrow, '1');

    const divider = style('.euiMarkdownEditorToolbar__divider');
    assert.strictEqual(divider.display, 'block');
    assert.strictEqual(divider.height, light.size.l);
    assert.strictEqual(divider.marginInlineStart, light.size.xs);
    assert.strictEqual(divider.paddingInlineEnd, light.size.xs);
    assert.strictEqual(px(divider.borderLeftWidth), thin);
    assert.strictEqual(divider.borderLeftColor, rgb(light.border.color));

    const textarea = el('textarea.euiMarkdownEditorTextArea');
    const area = getComputedStyle(textarea);
    assert.strictEqual(area.boxSizing, 'border-box');
    assert.strictEqual(area.minHeight, '150px');
    assert.strictEqual(area.paddingTop, light.size.m);
    assert.strictEqual(area.paddingInlineStart, light.size.m);
    assert.strictEqual(area.resize, 'vertical');
    assert.strictEqual(area.marginTop, '0px');
    assert.true(area.fontFamily.includes('Inter'), 'form control font');
    assert.strictEqual(
      px(area.lineHeight) / px(area.fontSize),
      light.font.lineHeightMultiplier,
      'line height multiplier'
    );
    assert.strictEqual(area.color, rgb(euiFormVariables(lightTheme).textColor));
    assert.strictEqual(px(area.borderTopWidth), thin);
    assert.strictEqual(area.borderBottomStyle, 'none');
    assert.strictEqual(area.boxShadow, 'none');
    assert.strictEqual(
      textarea.getBoundingClientRect().width,
      el('.euiMarkdownEditorDropZone').getBoundingClientRect().width,
      'full width'
    );

    const zone = style('.euiMarkdownEditorDropZone');
    assert.strictEqual(zone.position, 'relative');
    assert.strictEqual(zone.display, 'flex');
    assert.strictEqual(zone.flexDirection, 'column');
    assert.strictEqual(zone.minHeight, '150px');

    const footerElement = el('.euiMarkdownEditorFooter');
    const footer = getComputedStyle(footerElement);
    // upstream inline-flex, blockified as a flex item of the drop zone
    assert.strictEqual(footer.display, 'flex');
    assert.strictEqual(footer.alignItems, 'center');
    assert.strictEqual(footer.paddingTop, light.size.xs);
    assert.strictEqual(footer.backgroundColor, rgb(light.colors.lightestShade));
    assert.strictEqual(px(footer.borderBottomWidth), thin);
    assert.strictEqual(footer.borderBottomLeftRadius, radius);
    assert.strictEqual(footer.borderBottomRightRadius, radius);
    assert.strictEqual(footer.borderTopLeftRadius, '0px');
    assert.strictEqual(style('.euiMarkdownEditorFooter__actions').flexGrow, '1');
    assert.strictEqual(style('.euiMarkdownEditorFooter__actions').gap, light.size.xs);

    // The textarea makes room for the measured footer (upstream height math)
    // offsetHeight: the test container is transform-scaled
    await waitUntil(
      () => textarea.offsetHeight + footerElement.offsetHeight === 250
    );
    assert.true(true, 'textarea + footer = @height (250px)');
    assert.strictEqual(
      el('.euiMarkdownEditor__toggleContainer').style.height,
      `calc(100% - ${el('.euiMarkdownEditorToolbar').offsetHeight}px)`,
      'toggle container subtracts the toolbar'
    );
    assert.dom('.euiMarkdownEditorToolbar').hasAttribute('data-test-subj', 'euiMarkdownEditorToolbar');
    assert.dom('.euiMarkdownEditorFooter').hasAttribute('data-test-subj', 'euiMarkdownEditorFooter');
    assert.dom('textarea').hasAttribute('data-test-subj', 'euiMarkdownEditorTextArea').hasAttribute('rows', '6');
    assert.dom('.euiMarkdownEditor--fullHeight, .euiMarkdownEditor--isPreviewing').doesNotExist('no legacy modifiers');
  });

  test('toolbar buttons, cursor highlighting and the editor/preview switch', async function (assert) {
    const state = new EditorState();
    await render(
      <template>
        <EuiMarkdownEditor @value={{state.value}} @onChange={{state.onChange}} />
      </template>
    );
    const labels = findAll('.euiMarkdownEditorToolbar__buttons button').map((b) => b.getAttribute('aria-label'));
    assert.deepEqual(labels, [
      'Bold',
      'Italic',
      'Unordered list',
      'Ordered list',
      'Task list',
      'Quote',
      'Code',
      'Link',
      'Tooltip'
    ]);
    assert.dom('.euiMarkdownEditorToolbar__divider').exists({ count: 3 }, 'groups + plugins');
    assert.dom('.euiMarkdownEditorToolbar__buttons .euiButtonIcon').exists({ count: 9 });
    assert.dom('[aria-label="Task list"] svg').exists('custom checkmark icon');

    // The node under the cursor highlights its button (upstream)
    const textarea = el('textarea') as HTMLTextAreaElement;
    textarea.focus();
    textarea.setSelectionRange(7, 7);
    await triggerKeyEvent(textarea, 'keyup', 'ArrowRight');
    const bold = el('[aria-label="Bold"]');
    assert.strictEqual(bold.getAttribute('data-test-subj'), 'euiMarkdownEditorToolbarButton pressed');
    assert.strictEqual(bold.style.background.replace(/\s/g, '').slice(0, 20), 'rgba(0,0,0,0.15)');
    assert.strictEqual(el('[aria-label="Italic"]').getAttribute('data-test-subj'), 'euiMarkdownEditorToolbarButton');

    // Switch to the preview
    const toggleContainer = el('.euiMarkdownEditor__toggleContainer');
    assert.dom('[data-test-subj="markdown_editor_edit_button"]').hasText('Preview');
    await click('[data-test-subj="markdown_editor_edit_button"]');
    assert.dom('.euiMarkdownEditor').hasClass('euiMarkdownEditor-isPreviewing');
    assert.strictEqual(getComputedStyle(toggleContainer).display, 'none', 'textarea kept but hidden');
    assert.strictEqual(el('.euiMarkdownEditor__toggleContainer'), toggleContainer, 'not re-rendered');
    assert.dom('[data-test-subj="markdown_editor_preview_button"]').hasText('Editor');
    findAll('.euiMarkdownEditorToolbar__buttons button').forEach((button) => assert.dom(button).isDisabled());

    const preview = style('.euiMarkdownEditorPreview');
    assert.strictEqual(preview.paddingTop, light.size.m);
    assert.strictEqual(preview.backgroundColor, rgb(light.colors.emptyShade));
    assert.strictEqual(px(preview.borderTopWidth), px(light.border.width.thin));
    assert.strictEqual(preview.minHeight, '150px');
    assert.strictEqual(preview.overflowY, 'auto');
    assert.strictEqual(preview.borderBottomLeftRadius, light.border.radius.panel);
    assert.strictEqual(preview.borderTopLeftRadius, '0px');
    assert.dom('.euiMarkdownEditorPreview .euiMarkdownFormat strong').hasText('bold');

    await click('[data-test-subj="markdown_editor_preview_button"]');
    assert.dom('.euiMarkdownEditorPreview').doesNotExist();
    assert.notStrictEqual(getComputedStyle(toggleContainer).display, 'none');
    assert.dom('[aria-label="Bold"]').isNotDisabled();

    // Formatting through a toolbar button
    textarea.focus();
    textarea.setSelectionRange(0, 4);
    await click('[aria-label="Italic"]');
    await waitUntil(() => state.value.startsWith('_Some_'), { timeout: 1000 });
    assert.strictEqual(state.value, '_Some_ **bold** text');
  });

  test('text area height modes: fixed, maxHeight, full and the auto-expanding preview', async function (assert) {
    class State {
      @tracked height: number | string = 300;
      @tracked value = 'short';
    }
    const state = new State();
    const noop = () => {};
    await render(
      <template>
        <div style="height: 700px; width: 500px" data-container>
          <EuiMarkdownEditor
            @value={{state.value}}
            @onChange={{noop}}
            @height={{state.height}}
            @maxHeight={{450}}
          />
        </div>
      </template>
    );
    const textarea = el('textarea');
    const footer = el('.euiMarkdownEditorFooter');
    await waitUntil(() => textarea.offsetHeight + footer.offsetHeight === 300);
    assert.strictEqual(
      textarea.style.maxHeight,
      `${450 - footer.offsetHeight}px`,
      'max height leaves room for the footer'
    );
    assert.strictEqual(getComputedStyle(textarea).resize, 'vertical');

    state.height = 'full';
    await settled();
    assert.strictEqual(el('textarea'), textarea, 'same textarea');
    assert.strictEqual(el('.euiMarkdownEditor').offsetHeight, 700, 'fills the container');
    assert.strictEqual(getComputedStyle(textarea).resize, 'none');
    assert.strictEqual(textarea.style.height, '100%');
    assert.strictEqual(textarea.style.maxHeight, '', 'no max height when full');
    assert.strictEqual(style('.euiMarkdownEditorDropZone').height, el('.euiMarkdownEditor__toggleContainer').offsetHeight + 'px');

    state.height = 200;
    state.value = Array.from({ length: 40 }, (_, i) => `Line ${i}`).join('\n\n');
    await settled();
    await click('[data-test-subj="markdown_editor_edit_button"]');
    const preview = el('.euiMarkdownEditorPreview');
    await waitUntil(() => preview.offsetHeight > 200);
    assert.true(
      Math.abs(preview.offsetHeight - (preview.scrollHeight + 2)) <= 2,
      'autoExpandPreview grows the preview to its content'
    );
  });

  test('footer: syntax help modal, help popover without plugin help and the errors popover', async function (assert) {
    class State {
      @tracked errors: EuiMarkdownParseError[] = [];
    }
    const state = new State();
    const editor = new EditorState();
    const noPlugins: unknown[] = [];
    await render(
      <template>
        <EuiMarkdownEditor
          @value={{editor.value}}
          @onChange={{editor.onChange}}
          @errors={{state.errors}}
        />
        <div data-bare-footer>
          <EuiMarkdownEditorFooter @uiPlugins={{noPlugins}} />
        </div>
      </template>
    );
    const help = '.euiMarkdownEditor .euiMarkdownEditorFooter__helpButton';
    assert.dom(help).hasAttribute('aria-label', 'Show markdown help');
    assert.dom(`${help} svg`).exists('markdown logo');
    assert.strictEqual(style(`${help} .euiIcon`).width, '26px', 'upstream help icon width via @css');

    await click(help);
    const modal = el('.euiModal');
    const titleId = modal.getAttribute('aria-labelledby')!;
    assert.dom(`#${titleId}`, document.body).hasTagName('h1').hasText('Syntax help');
    assert.dom(modal).containsText('This editor uses GitHub flavored markdown');
    assert.dom(modal).containsText('You can also utilize these additional syntax plugins');
    assert.dom('a.euiLink', modal).hasAttribute('href', 'https://guides.github.com/features/mastering-markdown/').hasAttribute('target', '_blank');
    assert.dom(modal).containsText('tooltipPlugin', 'plugin with help text listed');
    assert.dom('.euiMarkdownFormat code', modal).exists('help text rendered as markdown');
    await click(el('.euiModalFooter .euiButton'));
    assert.dom('.euiModal', document.body).doesNotExist('Close button closes');

    // Without plugin help text upstream shows a popover
    await click('[data-bare-footer] .euiMarkdownEditorFooter__helpButton');
    assert.dom('.euiPopover__panel', document.body).containsText('This editor uses GitHub flavored markdown');
    assert.dom('.euiModal', document.body).doesNotExist();

    // Errors
    assert.dom('.euiMarkdownEditor [aria-label="Show errors"]').doesNotExist();
    const textarea = el('textarea');
    assert.strictEqual(getComputedStyle(textarea).outlineStyle, 'none');
    state.errors = ['First problem', new Error('Second problem')];
    await settled();
    assert.dom('[aria-label="Show errors"]').hasText('2').hasClass('euiButtonEmpty');
    assert.strictEqual(style('[aria-label="Show errors"]').color, rgb(light.colors.textDanger));
    const invalid = getComputedStyle(textarea);
    assert.strictEqual(invalid.outlineStyle, 'solid', 'errors mark the textarea invalid');
    assert.strictEqual(invalid.outlineColor, rgb(euiFormVariables(lightTheme).borderInvalid));
    await click('[aria-label="Show errors"]');
    const panel = el('.euiMarkdownEditorFooter__popover');
    assert.strictEqual(getComputedStyle(panel).width, '300px');
    assert.dom('.euiPopoverTitle', panel).hasText('Errors');
    assert.deepEqual(
      Array.from(panel.querySelectorAll('.euiText')).map((e) => e.textContent!.trim()),
      ['First problem', 'Error: Second problem']
    );
  });

  test('drop zone: drag states, unsupported files, uploads and the hidden file input', async function (assert) {
    const state = new EditorState();
    state.value = 'Intro';
    const handlers = [pngHandler];
    await render(
      <template>
        <EuiMarkdownEditor
          @value={{state.value}}
          @onChange={{state.onChange}}
          @dropHandlers={{handlers}}
        />
        <div data-no-handlers>
          <EuiMarkdownEditor @value={{state.value}} @onChange={{state.onChange}} />
        </div>
      </template>
    );
    const zone = el('.euiMarkdownEditorDropZone');
    const textarea = el('textarea');
    const restBackground = getComputedStyle(textarea).backgroundColor;
    assert.dom('[aria-label="Open upload files modal"]').exists('upload button with handlers');
    assert.dom('[data-no-handlers] [aria-label="Open upload files modal"]').doesNotExist();
    assert.dom('input[type="file"]', zone).exists().hasAttribute('multiple').hasAttribute('tabindex', '-1');
    assert.strictEqual(style('input[type="file"]', zone).display, 'none');
    assert.dom(zone).doesNotHaveAttribute('role', 'the zone itself is not a button (upstream)');

    zone.dispatchEvent(dragEvent('dragover', [png()]));
    await settled();
    const primary = rgb(light.colors.backgroundBasePrimary);
    assert.strictEqual(getComputedStyle(textarea).backgroundColor, primary, 'dragging: primary background');
    assert.strictEqual(style('.euiMarkdownEditorFooter').backgroundColor, primary);

    zone.dispatchEvent(new DragEvent('dragleave', { bubbles: true, relatedTarget: document.body }));
    await settled();
    assert.strictEqual(getComputedStyle(textarea).backgroundColor, restBackground, 'leaving resets');

    zone.dispatchEvent(dragEvent('dragenter', [txt()]));
    await settled();
    assert.strictEqual(
      getComputedStyle(textarea).backgroundColor,
      rgb(light.colors.backgroundBaseDanger),
      'unsupported drag: danger background'
    );
    assert.dom('.euiMarkdownEditorFooter__uploadError').hasText('File type not supported');
    assert.dom('.euiMarkdownEditorFooter__uploadError').hasAttribute(
      'aria-label',
      'File type not supported. Supported files: .png. Click to upload files'
    );
    assert.strictEqual(getComputedStyle(textarea).outlineStyle, 'solid', 'unaccepted items mark the textarea invalid');

    zone.dispatchEvent(dragEvent('drop', [txt()]));
    await settled();
    assert.strictEqual(state.changes.length, 0, 'unsupported drop inserts nothing');
    assert.dom('.euiMarkdownEditorFooter__uploadError').exists();

    await focus(textarea);
    assert.dom('.euiMarkdownEditorFooter__uploadError').doesNotExist('focusing the textarea clears the error');

    (textarea as HTMLTextAreaElement).setSelectionRange(5, 5);
    zone.dispatchEvent(dragEvent('drop', [png()]));
    await waitUntil(() => state.value.includes('cat.png'), { timeout: 2000 });
    assert.strictEqual(state.value, 'Intro\n\n![cat.png](blob:cat.png)', 'block result padded with new lines');
    await settled();
    assert.dom('[aria-label="Open upload files modal"]').exists('upload finished');
    assert.strictEqual(getComputedStyle(textarea).backgroundColor, restBackground);

    // Without handlers dropping is disabled
    const other = el('[data-no-handlers] .euiMarkdownEditorDropZone');
    const event = dragEvent('dragover', [png()]);
    other.dispatchEvent(event);
    assert.false(event.defaultPrevented, 'no handlers: drops are not accepted');
  });

  test('markdown format renders through EuiText: sizes, typography and migrated components, no legacy classes', async function (assert) {
    class State {
      @tracked textSize: 'xs' | 's' | 'm' | 'relative' = 'm';
    }
    const state = new State();
    await render(
      <template>
        <div style="font-size: 20px">
          <EuiMarkdownFormat
            @value={{content}}
            @textSize={{state.textSize}}
            data-test-subj="format"
            aria-label="Rendered"
          />
        </div>
      </template>
    );
    const root = el('.euiMarkdownFormat');
    assert.dom(root).hasClass('euiText').hasAttribute('data-test-subj', 'format').hasAttribute('aria-label', 'Rendered');
    assert.strictEqual(root.className.match(/euiText--|euiLink--/), null, 'no legacy modifier classes');
    assert.strictEqual(root.querySelector('[class*="euiLink--"]'), null);

    const rootStyle = getComputedStyle(root);
    const m = px(rootStyle.fontSize);
    assert.strictEqual(rootStyle.color, rgb(light.colors.textParagraph), 'color default');
    assert.true(rootStyle.fontFamily.includes('Inter'));
    assert.true(px(style('h1', root).fontSize) > px(style('h2', root).fontSize));
    assert.true(px(style('h2', root).fontSize) > m);
    assert.strictEqual(style('h1', root).fontWeight, String(light.font.weight.bold));
    assert.strictEqual(style('ul', root).listStyleType, 'disc');
    assert.strictEqual(style('ol', root).listStyleType, 'decimal');
    assert.true(px(style('ul', root).marginInlineStart) > 0, 'lists are indented');

    // Link via EuiLink
    const link = el('a', root);
    assert.dom(link).hasClass('euiLink').hasAttribute('href', 'https://elastic.co').hasAttribute('title', 'Elastic').hasAttribute('rel', 'noreferrer').hasText('link');
    assert.strictEqual(getComputedStyle(link).color, rgb(light.colors.textParagraph), 'upstream link color text');
    assert.strictEqual(getComputedStyle(link).fontWeight, String(light.font.weight.medium));
    assert.dom(link.parentElement!).hasClass('component').doesNotHaveAttribute('href', 'wrapper gets no attributes');

    // Code, code block wrapper, quote, table and rule
    assert.dom('code.euiCode', root).hasText('inline code');
    const wrapper = style('.euiMarkdownFormat__codeblockWrapper', root);
    assert.strictEqual(px(wrapper.marginBlockEnd), m, 'code block margin = font size');
    assert.dom('.euiMarkdownFormat__codeblockWrapper .euiCodeBlock', root).exists('rendered by EuiCodeBlock');
    const quote = style('blockquote.euiMarkdownFormat__blockquote', root);
    assert.strictEqual(quote.borderLeftStyle, 'solid');
    assert.strictEqual(quote.borderLeftColor, rgb(light.components.markdownFormatTableBorderColor));
    assert.strictEqual(quote.color, rgb(light.colors.textParagraph), 'markdown quotes keep the text color');
    const table = style('table.euiMarkdownFormat__table', root);
    assert.strictEqual(table.display, 'block');
    assert.strictEqual(table.borderCollapse, 'collapse');
    assert.strictEqual(table.overflow, 'auto');
    assert.strictEqual(px(table.marginBlockEnd), m);
    const th = style('th', root);
    assert.strictEqual(px(th.paddingTop), m / 4);
    assert.strictEqual(px(th.paddingInlineStart), m / 2);
    assert.strictEqual(th.borderTopColor, rgb(light.components.markdownFormatTableBorderColor));
    const hr = style('.euiHorizontalRule', root);
    assert.strictEqual(hr.backgroundColor, rgb(light.components.markdownFormatTableBorderColor), 'rule tinted by the format');

    // Sizes change in place
    const nodes = Array.from(root.childNodes);
    state.textSize = 's';
    await settled();
    const s = px(getComputedStyle(root).fontSize);
    state.textSize = 'xs';
    await settled();
    const xs = px(getComputedStyle(root).fontSize);
    assert.true(m > s && s > xs, 'm > s > xs');
    assert.strictEqual(px(style('th', root).paddingTop), xs / 4, 'table padding scales');
    state.textSize = 'relative';
    await settled();
    assert.strictEqual(px(getComputedStyle(root).fontSize), 20, 'relative follows the parent (1em)');
    assert.strictEqual(px(style('th', root).paddingTop), 5, 'relative padding in em');
    assert.strictEqual(el('.euiMarkdownFormat'), root, 'same root');
    assert.deepEqual(Array.from(root.childNodes), nodes, 'content not re-rendered');
  });

  test('markdown format colors tint text and borders; shouldIncludeDefaultRootClasses and rootClasses', async function (assert) {
    class State {
      @tracked color = 'subdued';
    }
    const state = new State();
    const value = '> quote\n\n---\n\n| a |\n| - |\n| 1 |';
    const classes = ['one', 'two'];
    await render(
      <template>
        <EuiMarkdownFormat @value={{value}} @color={{state.color}} data-colored />
        <EuiMarkdownFormat @value={{value}} @rootClasses="custom extra" data-plain-classes />
        <EuiMarkdownFormat @value={{value}} @rootClasses={{classes}} @shouldIncludeDefaultRootClasses={{false}} data-no-text />
      </template>
    );
    const root = el('[data-colored]');
    const check = (color: string, border: string, message: string) => {
      assert.strictEqual(getComputedStyle(root).color, rgb(color), `${message}: text`);
      assert.strictEqual(style('blockquote', root).borderLeftColor, rgb(border), `${message}: quote`);
      assert.strictEqual(style('td', root).borderTopColor, rgb(border), `${message}: table`);
      assert.strictEqual(style('.euiHorizontalRule', root).backgroundColor, rgb(border), `${message}: rule`);
    };
    check(light.colors.textSubdued, light.colors.textSubdued, 'subdued');
    state.color = 'danger';
    await settled();
    check(light.colors.textDanger, light.colors.danger, 'danger');
    state.color = 'accentSecondary';
    await settled();
    check(light.colors.textAccentSecondary, light.colors.accentSecondary, 'accentSecondary');
    state.color = '#336699';
    await settled();
    check('#336699', '#336699', 'custom color uses currentColor borders');
    assert.strictEqual(el('[data-colored]'), root);

    assert.dom('[data-plain-classes]').hasClass('euiMarkdownFormat').hasClass('euiText').hasClass('custom').hasClass('extra');
    const bare = el('[data-no-text]');
    assert.dom(bare).hasClass('euiMarkdownFormat').hasClass('one').hasClass('two').doesNotHaveClass('euiText');
    assert.strictEqual(style('blockquote', bare).borderLeftColor, rgb(light.components.markdownFormatTableBorderColor), 'markdown border colors kept');
    assert.notStrictEqual(getComputedStyle(bare).fontFamily, getComputedStyle(el('[data-plain-classes]')).fontFamily, 'no EuiText typography');
  });

  test('task list checkboxes toggle through replaceNode, in the editor preview, and stay put when read-only', async function (assert) {
    const replaced: [EuiMarkdownAstNodePosition, string][] = [];
    const replaceNode = (position: EuiMarkdownAstNodePosition, next: string) => replaced.push([position, next]);
    const list = '- [x] done\n- [ ] todo\n\nAfter';
    const state = new EditorState();
    state.value = '- [ ] task';
    class ReadOnly {
      @tracked readOnly = true;
    }
    const ro = new ReadOnly();
    await render(
      <template>
        <div data-format>
          <EuiMarkdownFormat @value={{list}} @replaceNode={{replaceNode}} />
        </div>
        <div data-editor>
          <EuiMarkdownEditor @value={{state.value}} @onChange={{state.onChange}} @initialViewMode="viewing" />
        </div>
        <div data-readonly>
          <EuiMarkdownFormat @value={{list}} @replaceNode={{replaceNode}} @readOnly={{ro.readOnly}} />
        </div>
      </template>
    );
    const format = el('[data-format] .euiMarkdownFormat');
    const boxes = findAll('[data-format] input[type="checkbox"]') as HTMLInputElement[];
    assert.deepEqual(boxes.map((b) => b.checked), [true, false]);
    assert.deepEqual(findAll('[data-format] .euiCheckbox__label').map((l) => l.textContent!.trim()), ['done', 'todo']);
    boxes.forEach((box) => assert.strictEqual(box.labels?.[0]?.textContent?.trim(), box.checked ? 'done' : 'todo', 'label is linked'));

    const wrappers = Array.from(format.querySelectorAll('.euiMarkdownFormat__checkbox'));
    assert.strictEqual(wrappers.length, 2);
    assert.strictEqual(getComputedStyle(wrappers[0]!).display, 'block');
    assert.strictEqual(getComputedStyle(wrappers[0]!).marginBlockEnd, '0px');
    assert.strictEqual(
      px(getComputedStyle(wrappers[1]!).marginBlockEnd),
      px(getComputedStyle(format).fontSize),
      'last task item gets 1em (upstream :has(+ :not(.euiCheckbox)))'
    );

    await click(boxes[1]!);
    await click(boxes[0]!);
    assert.deepEqual(replaced.map(([, next]) => next), ['- [x] todo', '- [ ] done']);
    assert.deepEqual(replaced[0]![0].start.offset, 11);

    // Editor preview: toggling edits the value and re-renders
    await click('[data-editor] input[type="checkbox"]');
    assert.strictEqual(state.value, '- [x] task');
    assert.dom('[data-editor] input[type="checkbox"]').isChecked();

    // Read-only
    const before = replaced.length;
    const readOnlyBox = el('[data-readonly] input[type="checkbox"]') as HTMLInputElement;
    assert.dom(readOnlyBox).hasAttribute('readonly');
    await click(readOnlyBox);
    assert.true(readOnlyBox.checked, 'click does not toggle');
    assert.strictEqual(replaced.length, before, 'replaceNode not called');
    ro.readOnly = false;
    await settled();
    await click(readOnlyBox);
    assert.strictEqual(replaced.length, before + 1, 'toggles again once editable');
  });

  test('tooltip plugin renders an EuiToolTip with the offset question icon', async function (assert) {
    const value = 'Hover !{tooltip[the anchor](Helpful description)} here';
    await render(<template><EuiMarkdownFormat @value={{value}} /></template>);
    const anchor = el('.euiMarkdownFormat .euiToolTipAnchor');
    assert.dom('strong', anchor).hasText('the anchor');
    const icon = el('.euiIcon', anchor);
    assert.strictEqual(getComputedStyle(icon).transform, 'matrix(1, 0, 0, 1, 0, -1)', 'translateY(-1px) via @css');
    assert.strictEqual(tooltip(), null);
    await triggerEvent(anchor, 'mouseover');
    await waitUntil(tooltip);
    assert.dom('.euiToolTip', document.body).hasText('Helpful description').hasAttribute('role', 'tooltip');
    assert.true(
      (anchor.firstElementChild!.getAttribute('aria-describedby') ?? '').includes(tooltip()!.id),
      'anchor described by the tooltip'
    );
    await triggerEvent(anchor, 'mouseout');
    await waitUntil(() => !tooltip());
  });

  test('editor args are reactive without replacing elements; read-only and a11y attributes', async function (assert) {
    class State {
      @tracked readOnly = false;
      @tracked isInvalid = false;
      @tracked height = 250;
    }
    const state = new State();
    const editor = new EditorState();
    const handlers = [pngHandler];
    await render(
      <template>
        <span id="label">Label</span><span id="help">Help</span>
        <EuiMarkdownEditor
          @value={{editor.value}}
          @onChange={{editor.onChange}}
          @readOnly={{state.readOnly}}
          @isInvalid={{state.isInvalid}}
          @height={{state.height}}
          @dropHandlers={{handlers}}
          @ariaLabelledBy="label"
          @ariaDescribedBy="help"
          @editorId="my-editor"
          placeholder="Write here"
          name="notes"
        />
      </template>
    );
    const textarea = el('textarea') as HTMLTextAreaElement;
    const root = el('.euiMarkdownEditor');
    assert.dom(textarea).hasAttribute('id', 'my-editor').hasAttribute('aria-labelledby', 'label').hasAttribute('aria-describedby', 'help').hasAttribute('placeholder', 'Write here').hasAttribute('name', 'notes').doesNotHaveAttribute('aria-invalid').doesNotHaveAttribute('readonly');

    await focus(textarea);
    const focused = getComputedStyle(textarea);
    assert.strictEqual(focused.outlineStyle, 'solid', 'focus ring');
    assert.strictEqual(focused.outlineColor, rgb(euiFormVariables(lightTheme).borderFocused));
    assert.strictEqual(px(focused.outlineWidth), px(light.border.width.thick));
    textarea.blur();

    state.isInvalid = true;
    await settled();
    assert.dom(textarea).hasAttribute('aria-invalid', 'true');
    assert.false(textarea.validity.valid);
    assert.strictEqual(getComputedStyle(textarea).outlineColor, rgb(euiFormVariables(lightTheme).borderInvalid));

    state.readOnly = true;
    state.isInvalid = false;
    await settled();
    assert.strictEqual(el('textarea'), textarea, 'same textarea');
    assert.strictEqual(el('.euiMarkdownEditor'), root, 'same root');
    assert.dom(textarea).hasAttribute('readonly').hasClass('euiMarkdownEditorTextArea-isReadOnly');
    assert.strictEqual(getComputedStyle(textarea).backgroundColor, rgb(light.colors.emptyShade));
    assert.strictEqual(getComputedStyle(textarea).cursor, 'default');
    await focus(textarea);
    assert.strictEqual(getComputedStyle(textarea).outlineStyle, 'none', 'read-only: no focus ring');
    findAll('.euiMarkdownEditorToolbar button').forEach((b) => assert.dom(b).isDisabled());
    assert.dom('[aria-label="Open upload files modal"]').isDisabled();
    assert.dom('.euiMarkdownEditorFooter__helpButton').isDisabled();
    const drag = dragEvent('dragover', [png()]);
    el('.euiMarkdownEditorDropZone').dispatchEvent(drag);
    assert.false(drag.defaultPrevented, 'read-only ignores drops');

    state.readOnly = false;
    state.height = 320;
    await settled();
    const footer = el('.euiMarkdownEditorFooter');
    assert.strictEqual(textarea.style.height, `calc(${320 - footer.offsetHeight}px)`);
    assert.dom('.euiMarkdownEditorToolbar button[aria-label="Bold"]').isNotDisabled();
  });

  test('light/dark follow the nearest provider with sibling isolation', async function (assert) {
    class State {
      @tracked mode: EuiColorMode = 'dark';
    }
    const state = new State();
    const editor = new EditorState();
    const value = '> quote';
    await render(
      <template>
        <EuiEmotionProvider @colorMode={{state.mode}}>
          <div data-dark>
            <EuiMarkdownEditor @value={{editor.value}} @onChange={{editor.onChange}} />
            <EuiMarkdownFormat @value={{value}} />
          </div>
          <EuiEmotionProvider @colorMode="light">
            <div data-island><EuiMarkdownEditor @value={{editor.value}} @onChange={{editor.onChange}} /></div>
          </EuiEmotionProvider>
        </EuiEmotionProvider>
        <EuiEmotionProvider @colorMode="light">
          <div data-sibling><EuiMarkdownFormat @value={{value}} /></div>
        </EuiEmotionProvider>
      </template>
    );
    const darkToolbar = el('[data-dark] .euiMarkdownEditorToolbar');
    assert.strictEqual(getComputedStyle(darkToolbar).backgroundColor, rgb(dark.colors.lightestShade));
    assert.strictEqual(style('[data-dark] .euiMarkdownEditorFooter').backgroundColor, rgb(dark.colors.lightestShade));
    assert.strictEqual(style('[data-dark] textarea').color, rgb(euiFormVariables(resolveBorealisTheme('dark')).textColor));
    assert.strictEqual(style('[data-dark] .euiMarkdownFormat').color, rgb(dark.colors.textParagraph));
    assert.strictEqual(style('[data-dark] blockquote').borderLeftColor, rgb(dark.components.markdownFormatTableBorderColor));
    assert.strictEqual(style('[data-island] .euiMarkdownEditorToolbar').backgroundColor, rgb(light.colors.lightestShade), 'light island');
    assert.strictEqual(style('[data-sibling] .euiMarkdownFormat').color, rgb(light.colors.textParagraph), 'sibling isolated');

    state.mode = 'light';
    await settled();
    assert.strictEqual(el('[data-dark] .euiMarkdownEditorToolbar'), darkToolbar, 'same element');
    assert.strictEqual(getComputedStyle(darkToolbar).backgroundColor, rgb(light.colors.lightestShade));
    assert.strictEqual(style('[data-dark] .euiMarkdownFormat').color, rgb(light.colors.textParagraph));

    await clearRender();
    assert.dom('.euiMarkdownEditor, .euiMarkdownFormat').doesNotExist('teardown');
  });

  test('native JS-object overrides and high contrast reach the markdown factories', async function (assert) {
    class State {
      @tracked overrides: EuiBorealisOverrides = {};
      @tracked contrast: EuiBorealisHighContrastMode = false;
    }
    const state = new State();
    const editor = new EditorState();
    const value = '> quote\n\n| a |\n| - |\n| 1 |';
    const nested: EuiBorealisOverrides = { colors: { LIGHT: { lightestShade: '#00aa00' } } };
    await render(
      <template>
        <EuiEmotionProvider @borealisOverrides={{state.overrides}} @highContrastMode={{state.contrast}}>
          <div data-main>
            <EuiMarkdownEditor @value={{editor.value}} @onChange={{editor.onChange}} />
            <EuiMarkdownFormat @value={{value}} />
          </div>
          <EuiEmotionProvider @borealisOverrides={{nested}}>
            <div data-nested><EuiMarkdownEditor @value={{editor.value}} @onChange={{editor.onChange}} /></div>
          </EuiEmotionProvider>
        </EuiEmotionProvider>
        <div data-outside><EuiMarkdownEditor @value={{editor.value}} @onChange={{editor.onChange}} /></div>
      </template>
    );
    state.overrides = {
      border: { radius: { panel: '13px' } },
      colors: { LIGHT: { lightestShade: '#123456' } }
    };
    await settled();
    const toolbar = style('[data-main] .euiMarkdownEditorToolbar');
    assert.strictEqual(toolbar.backgroundColor, 'rgb(18, 52, 86)');
    assert.strictEqual(toolbar.borderTopLeftRadius, '13px');
    assert.strictEqual(style('[data-main] .euiMarkdownEditorFooter').borderBottomRightRadius, '13px');
    assert.strictEqual(style('[data-nested] .euiMarkdownEditorToolbar').backgroundColor, 'rgb(0, 170, 0)', 'nearest override wins');
    assert.strictEqual(style('[data-outside] .euiMarkdownEditorToolbar').backgroundColor, rgb(light.colors.lightestShade), 'scoped');
    assert.strictEqual(style('[data-outside] .euiMarkdownEditorToolbar').borderTopLeftRadius, light.border.radius.panel);

    assert.strictEqual(style('[data-main] blockquote').borderLeftColor, rgb(light.components.markdownFormatTableBorderColor));
    state.contrast = 'preferred';
    await settled();
    const contrast = resolveBorealisTheme('light', state.overrides, 'preferred').euiTheme;
    assert.strictEqual(style('[data-main] blockquote').borderLeftColor, rgb(contrast.border.color), 'preferred contrast: border color');
    assert.strictEqual(style('[data-main] td').borderTopColor, rgb(contrast.border.color));
    assert.strictEqual(style('[data-outside] .euiMarkdownEditorToolbar').backgroundColor, rgb(light.colors.lightestShade), 'standard contrast outside');
  });

  test('RTL flips logical borders, padding and alignment', async function (assert) {
    const editor = new EditorState();
    const value = '> quote\n\n- item\n\n| a | b |\n| - | - |\n| 1 | 2 |';
    await render(
      <template>
        <div dir="rtl" data-rtl>
          <EuiMarkdownEditor @value={{editor.value}} @onChange={{editor.onChange}} />
          <EuiMarkdownFormat @value={{value}} />
        </div>
      </template>
    );
    const thin = px(light.border.width.thin);
    const divider = style('[data-rtl] .euiMarkdownEditorToolbar__divider');
    assert.strictEqual(px(divider.borderRightWidth), thin, 'divider border on the right');
    assert.strictEqual(px(divider.borderLeftWidth), 0);
    assert.strictEqual(px(divider.marginRight), px(light.size.xs));
    const quote = style('[data-rtl] blockquote');
    assert.true(px(quote.borderRightWidth) > 0, 'quote border on the right');
    assert.strictEqual(px(quote.borderLeftWidth), 0);
    assert.true(px(style('[data-rtl] ul').marginRight) > 0, 'list indent on the right');
    const lastCell = style('[data-rtl] tr td:last-child');
    assert.strictEqual(px(lastCell.borderLeftWidth), thin, 'table end border on the left');
    const buttons = findAll('[data-rtl] .euiMarkdownEditorToolbar__buttons button');
    assert.true(
      buttons[0]!.getBoundingClientRect().left > buttons[1]!.getBoundingClientRect().left,
      'toolbar flows right to left'
    );
  });
});
