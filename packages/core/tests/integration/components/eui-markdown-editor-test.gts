import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, fillIn, render, waitUntil } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import EuiMarkdownEditor from '#src/components/eui-markdown-editor.gts';

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

    assert.dom('.euiMarkdownEditor').hasClass('euiMarkdownEditor--isPreviewing');
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
});
