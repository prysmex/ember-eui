import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, triggerEvent, waitUntil } from '@ember/test-helpers';
import { htmlSafe } from '@ember/template';

import EuiToolTip from '#src/components/eui-tool-tip.gts';

// stands in for ember-intl's `t`, which returns a string
const t = (key: string) => `<b class="label">${key}</b>`;

module('Integration | Component | eui-tool-tip | @content', function (hooks) {
  setupRenderingTest(hooks);

  test('@content can be a SafeString, rendered as markup', async function (assert) {
    await render(
      <template>
        <EuiToolTip @content={{htmlSafe (t "some.key")}}>
          <button type="button">Hover me</button>
        </EuiToolTip>
      </template>
    );

    await triggerEvent('.euiToolTipAnchor', 'mouseover');
    await waitUntil(() => document.querySelector('.euiToolTip'));

    assert.dom('.euiToolTip b.label', document.body).hasText('some.key');
  });
});
