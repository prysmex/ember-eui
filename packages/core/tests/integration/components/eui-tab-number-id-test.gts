import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';

import EuiTab from '#src/components/eui-tab.gts';
import EuiTabs from '#src/components/eui-tabs.gts';

const NAMES = ['One', 'Two'];

module('Integration | Component | eui-tab | @id', function (hooks) {
  setupRenderingTest(hooks);

  test('@id can be an {{#each}} index', async function (assert) {
    await render(
      <template>
        <EuiTabs>
          {{#each NAMES as |name index|}}
            <EuiTab @id={{index}}>{{name}}</EuiTab>
          {{/each}}
        </EuiTabs>
      </template>
    );

    assert.dom('[role="tab"]:nth-child(1)').hasAttribute('id', '0');
    assert.dom('[role="tab"]:nth-child(2)').hasAttribute('id', '1');
  });
});
