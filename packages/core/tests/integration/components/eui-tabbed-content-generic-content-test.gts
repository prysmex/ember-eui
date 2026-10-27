import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render } from '@ember/test-helpers';
import Component from '@glimmer/component';

import EuiTabbedContent from '#src/components/eui-tabbed-content.gts';
import type { EuiTabbedContentTab } from '#src/components/eui-tabbed-content.gts';
import type { TOC } from '@ember/component/template-only';

// stands in for ember-intl's `t`, which takes a string key
const t = (key: string) => `translated ${key}`;

class Settings extends Component {
  tabs = [
    { id: 'general', name: 'General', content: 'settings.general' },
    { id: 'billing', name: 'Billing', content: 'settings.billing' }
  ];

  <template>
    <EuiTabbedContent @tabs={{this.tabs}} @initialSelectedTab={{this.tabs.[1]}}>
      <:selectedTabContent as |tab|>
        <p class="panel">{{t tab.content}}</p>
      </:selectedTabContent>
    </EuiTabbedContent>
  </template>
}

const Panel: TOC<{}> = <template>
  <p class="panel">A component</p>
</template>;

module(
  'Integration | Component | eui-tabbed-content | content',
  function (hooks) {
    setupRenderingTest(hooks);

    test('a tab content can be a string the block renders', async function (assert) {
      await render(<template><Settings /></template>);

      assert.dom('.panel').hasText('translated settings.billing');

      await click('#general');

      assert.dom('.panel').hasText('translated settings.general');
    });

    test('tabs annotated as EuiTabbedContentTab<string> type-check', async function (assert) {
      const tabs: EuiTabbedContentTab<string>[] = [
        { id: 'a', name: 'A', content: 'key.a' }
      ];
      const clicked: (string | undefined)[] = [];
      const onTabClick = (tab: EuiTabbedContentTab<string>) =>
        clicked.push(tab.content);

      await render(
        <template>
          <EuiTabbedContent @tabs={{tabs}} @onTabClick={{onTabClick}}>
            <:selectedTabContent as |tab|>
              <p class="panel">{{tab.content}}</p>
            </:selectedTabContent>
          </EuiTabbedContent>
        </template>
      );

      assert.dom('.panel').hasText('key.a');

      await click('#a');

      assert.deepEqual(clicked, ['key.a']);
    });

    test('without the block, a component content is rendered', async function (assert) {
      const tabs = [{ id: 'a', name: 'A', content: Panel }];

      await render(<template><EuiTabbedContent @tabs={{tabs}} /></template>);

      assert.dom('[role="tabpanel"] .panel').hasText('A component');
    });
  }
);
