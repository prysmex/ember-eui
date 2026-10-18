import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render } from '@ember/test-helpers';
import { htmlSafe } from '@ember/template';

import EuiToast from '#src/components/eui-toast.gts';

module('Integration | Component | eui-toast', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders title, icon, color and body', async function (assert) {
    await render(
      <template><EuiToast @title="Saved" @color="success" @iconType="check" @body="All good" /></template>
    );

    assert.dom('.euiToast').hasClass('euiToast--success');
    assert.dom('.euiToastHeader__title').hasText('Saved');
    // upstream has no header wrapper/modifier: the body follows the title
    assert.dom('[data-test-subj="euiToastBody"] .euiToast__text').hasText('All good');
    assert.dom('svg[data-icon-type="check"]').hasAttribute('aria-hidden', 'true');
    assert.dom('.euiToast').containsText('All good');
  });

  test('@onClose renders a dismiss button', async function (assert) {
    let closed = 0;
    const onClose = () => closed++;

    await render(<template><EuiToast @title="Bye" @onClose={{onClose}} /></template>);

    await click('[data-test-subj="toastCloseButton"]');
    assert.strictEqual(closed, 1);
  });

  test('@body can be a component for rich content', async function (assert) {
    const Rich = <template><span class="rich-body">See <a href="#docs">the docs</a></span></template>;
    await render(<template><EuiToast @title="Rich" @body={{Rich}} /></template>);

    assert.dom('[data-test-subj="euiToastBody"] .euiToast__text .rich-body a').hasText('the docs');
  });

  test('a component body ignores @useMarkdownFormat, a string body still renders markdown', async function (assert) {
    const Rich = <template><span class="rich-body">**not markdown**</span></template>;
    await render(
      <template>
        <EuiToast @title="A" @body={{Rich}} @useMarkdownFormat={{true}} data-test-subj="a" />
        <EuiToast @title="B" @body="**bold**" @useMarkdownFormat={{true}} data-test-subj="b" />
      </template>
    );

    assert.dom('[data-test-subj="a"] .rich-body').hasText('**not markdown**');
    assert.dom('[data-test-subj="b"] strong').hasText('bold');
  });

  test('@body can be an htmlSafe string, rendered as HTML (as in 14.x)', async function (assert) {
    const body = htmlSafe('Saved <strong>3</strong> items');

    await render(
      <template>
        <EuiToast @title="A" @body={{body}} data-test-subj="a" />
        <EuiToast @title="B" @body={{body}} @useMarkdownFormat={{true}} data-test-subj="b" />
      </template>
    );

    for (const toast of ['a', 'b']) {
      assert.dom(`[data-test-subj="${toast}"] .euiToast__text`).hasText('Saved 3 items');
      assert.dom(`[data-test-subj="${toast}"] .euiToast__text strong`).hasText('3');
    }
    assert.dom('[data-test-subj="b"] .euiMarkdownFormat').doesNotExist('HTML already, not markdown');
  });
});
