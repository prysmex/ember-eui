import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, fillIn, render, waitUntil } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import EuiMarkdownEditor from '#src/components/eui-markdown-editor.gts';
import {
  getDefaultEuiMarkdownParsingPlugins,
  getDefaultEuiMarkdownProcessingPlugins
} from '#src/utils/markdown/plugins/markdown-default-plugins/index.ts';

class State {
  @tracked value = '# Title\n\nSome text';
  changes: string[] = [];

  onChange = (value: string) => {
    this.changes.push(value);
    this.value = value;
  };
}

module('Integration | Component | eui-markdown-editor', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders the toolbar and a text area with the value', async function (assert) {
    const state = new State();

    await render(<template><EuiMarkdownEditor @value={{state.value}} @onChange={{state.onChange}} @ariaLabel="Notes" /></template>);

    assert.dom('.euiMarkdownEditor .euiMarkdownEditorToolbar').exists();
    assert.dom('textarea.euiMarkdownEditorTextArea').hasValue('# Title\n\nSome text').hasAttribute('aria-label', 'Notes');
    assert.dom('.euiMarkdownEditorToolbar button[aria-label="Bold"]').exists();
  });

  test('typing calls @onChange with the new value', async function (assert) {
    const state = new State();

    await render(<template><EuiMarkdownEditor @value={{state.value}} @onChange={{state.onChange}} /></template>);

    await fillIn('textarea.euiMarkdownEditorTextArea', 'New **text**');
    assert.deepEqual(state.changes, ['New **text**']);
  });

  test('the preview toggle renders the formatted markdown', async function (assert) {
    const state = new State();

    await render(<template><EuiMarkdownEditor @value={{state.value}} @onChange={{state.onChange}} /></template>);

    await click('.euiMarkdownEditorToolbar button.euiButtonEmpty');
    await waitUntil(() => document.querySelector('.euiMarkdownEditorPreview'));

    // upstream state class (was the legacy `euiMarkdownEditor--isPreviewing`)
    assert.dom('.euiMarkdownEditor').hasClass('euiMarkdownEditor-isPreviewing');
    assert.dom('.euiMarkdownEditorPreview h1').hasText('Title');
    assert.dom('.euiMarkdownEditorPreview p').hasText('Some text');
  });

  test('toolbar buttons are disabled while previewing', async function (assert) {
    const state = new State();

    await render(<template><EuiMarkdownEditor @value={{state.value}} @onChange={{state.onChange}} /></template>);

    await click('.euiMarkdownEditorToolbar button.euiButtonEmpty');
    assert.dom('.euiMarkdownEditorToolbar button[aria-label="Bold"]').isDisabled();
  });

  test('the Bold button wraps the selection', async function (assert) {
    const state = new State();

    state.value = 'make me bold';

    await render(<template><EuiMarkdownEditor @value={{state.value}} @onChange={{state.onChange}} /></template>);

    const textarea = (this.element as HTMLElement).querySelector('textarea')!;

    textarea.focus();
    textarea.setSelectionRange(8, 12);

    await click('.euiMarkdownEditorToolbar button[aria-label="Bold"]');
    await waitUntil(() => textarea.value.includes('**bold**'), { timeout: 1000 });

    assert.strictEqual(textarea.value, 'make me **bold**');
  });

  test('@disabled and @isInvalid', async function (assert) {
    const state = new State();

    await render(<template><EuiMarkdownEditor @value={{state.value}} @onChange={{state.onChange}} @disabled={{true}} @isInvalid={{true}} /></template>);

    const textarea = (this.element as HTMLElement).querySelector('textarea')!;

    assert.dom(textarea).isDisabled();
    assert.false(textarea.validity.valid);
  });

  test('@showFooter={{false}} hides the footer', async function (assert) {
    const state = new State();

    await render(<template><EuiMarkdownEditor @value={{state.value}} @onChange={{state.onChange}} @showFooter={{false}} /></template>);

    assert.dom('.euiMarkdownEditorFooter').doesNotExist();
    assert.dom('textarea.euiMarkdownEditorTextArea').exists();
  });

  test('@toolbarProps adds a class and replaces the preview switch', async function (assert) {
    const state = new State();
    const toolbarProps = { className: 'myToolbar', right: 'Custom right' };

    await render(<template><EuiMarkdownEditor @value={{state.value}} @onChange={{state.onChange}} @toolbarProps={{toolbarProps}} /></template>);

    assert.dom('.euiMarkdownEditorToolbar').hasClass('myToolbar');
    assert.dom('.euiMarkdownEditorToolbar').includesText('Custom right');
    assert.dom('[data-test-subj="markdown_editor_edit_button"]').doesNotExist();
  });

  test('@onParse reports the ast and messages; @parsingPluginList/@processingPluginList', async function (assert) {
    const state = new State();

    state.value = 'Hi :smile:';

    const parses: { error: unknown; ast: any }[] = [];
    const onParse = (error: unknown, { ast }: { messages: any[]; ast: any }) => {
      parses.push({ error, ast });
    };
    const parsingPluginList = getDefaultEuiMarkdownParsingPlugins({ exclude: ['emoji'] });
    const processingPluginList = getDefaultEuiMarkdownProcessingPlugins({ exclude: ['emoji'] });

    await render(<template>
      <EuiMarkdownEditor
        @value={{state.value}}
        @onChange={{state.onChange}}
        @onParse={{onParse}}
        @parsingPluginList={{parsingPluginList}}
        @processingPluginList={{processingPluginList}}
        @initialViewMode="viewing"
      />
    </template>);

    await fillIn('textarea.euiMarkdownEditorTextArea', 'Hello :smile:');

    const last = parses[parses.length - 1]!;

    assert.strictEqual(last.error, null);
    assert.strictEqual(last.ast.type, 'root', 'the parsed ast');
    // emoji excluded: the shortcode stays text
    assert.dom('.euiMarkdownEditorPreview').includesText(':smile:');
  });

  test('@markdownFormatProps reach the preview', async function (assert) {
    const state = new State();
    const markdownFormatProps = { textSize: 's' as const, grow: false, textAlign: 'center' as const, rootClasses: 'myFormat' };

    await render(<template><EuiMarkdownEditor @value={{state.value}} @onChange={{state.onChange}} @initialViewMode="viewing" @markdownFormatProps={{markdownFormatProps}} /></template>);

    const format = (this.element as HTMLElement).querySelector<HTMLElement>('.euiMarkdownFormat')!;

    assert.dom(format).hasClass('myFormat');
    assert.strictEqual(getComputedStyle(format).textAlign, 'center');
    assert.notStrictEqual(getComputedStyle(format).maxWidth, 'none', 'not growing caps the width');
  });

  test('@autoExpandPreview={{false}} keeps the preview at @height', async function (assert) {
    const state = new State();

    state.value = Array.from({ length: 40 }, (_, i) => `Line ${i}`).join('\n\n');

    await render(<template><EuiMarkdownEditor @value={{state.value}} @onChange={{state.onChange}} @height={{200}} @autoExpandPreview={{false}} /></template>);

    await click('[data-test-subj="markdown_editor_edit_button"]');

    const preview = (this.element as HTMLElement).querySelector<HTMLElement>('.euiMarkdownEditorPreview')!;

    assert.strictEqual(preview.style.height, '200px');
    assert.true(preview.scrollHeight > 200, 'the content scrolls');
  });
});
