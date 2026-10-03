import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { on } from '@ember/modifier';
import { click, render } from '@ember/test-helpers';

import EuiLink from '#src/components/eui-link.gts';

module('Integration | Component | eui-link', function (hooks) {
  setupRenderingTest(hooks);

  test('with @href it renders an anchor', async function (assert) {
    await render(<template><EuiLink @href="#docs" @color="subdued">Docs</EuiLink></template>);

    assert.dom('a.euiLink').hasAttribute('href', '#docs').hasClass('euiLink--subdued').hasText('Docs');
  });

  test('target _blank shows the external icon and a screen reader hint', async function (assert) {
    await render(<template><EuiLink @href="https://example.com" @target="_blank">Out</EuiLink></template>);

    assert.dom('a.euiLink').hasAttribute('target', '_blank');
    assert.dom('a.euiLink svg.euiIcon').hasAttribute('aria-label', 'External link');
    assert.dom('a.euiLink svg.euiIcon').doesNotHaveAttribute('aria-hidden');
    assert.dom('a.euiLink').containsText('opens in a new tab or window');
  });

  test('@external={{false}} hides the external icon', async function (assert) {
    await render(<template><EuiLink @href="https://example.com" @target="_blank" @external={{false}}>Out</EuiLink></template>);

    assert.dom('a.euiLink svg.euiIcon').doesNotExist();
  });

  test('without @href it renders a button', async function (assert) {
    let clicks = 0;
    const onClick = () => clicks++;

    await render(
      <template>
        <EuiLink {{on "click" onClick}} class="button-link">Action</EuiLink>
        <EuiLink @disabled={{true}} class="disabled">Off</EuiLink>
      </template>
    );

    assert.dom('button.button-link').hasAttribute('type', 'button').hasClass('euiLink--primary');
    await click('button.button-link');
    assert.strictEqual(clicks, 1);
    assert.dom('button.disabled').isDisabled();
  });

  test('a disabled link with @href is a disabled button, as links cannot be disabled', async function (assert) {
    await render(<template><EuiLink @href="#here" @disabled={{true}} class="off">Off</EuiLink></template>);

    assert.dom('a').doesNotExist();
    assert.dom('button.off').isDisabled().hasClass('euiLink-disabled');
  });
});
