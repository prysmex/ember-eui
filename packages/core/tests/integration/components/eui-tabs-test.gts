import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { on } from '@ember/modifier';
import { click, render } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import EuiTab from '#src/components/eui-tab.gts';
import EuiTabbedContent from '#src/components/eui-tabbed-content.gts';
import EuiTabs from '#src/components/eui-tabs.gts';

const TABS = [
  { id: 'one', name: 'One' },
  { id: 'two', name: 'Two' },
  { id: 'three', name: 'Three', disabled: true }
];

module('Integration | Component | eui-tabs', function (hooks) {
  setupRenderingTest(hooks);

  test('EuiTabs and EuiTab render a tablist', async function (assert) {
    class State {
      @tracked selected = 'a';
    }
    const state = new State();
    const selectB = () => (state.selected = 'b');

    await render(
      <template>
        <EuiTabs @size="s" @expand={{true}}>
          <EuiTab @isSelected={{true}} class="a">
            <:prepend>*</:prepend>
            <:default>A</:default>
          </EuiTab>
          <EuiTab {{on "click" selectB}} class="b">B</EuiTab>
          <EuiTab @href="#c" class="c">C</EuiTab>
          <EuiTab @disabled={{true}} class="d">D</EuiTab>
        </EuiTabs>
      </template>
    );

    assert.dom('[role="tablist"]').hasClass('euiTabs--small').hasClass('euiTabs--expand').hasClass('euiTabs--bottomBorder');
    assert.dom('button.a').hasClass('euiTab-isSelected').hasAttribute('aria-selected', 'true');
    assert.dom('button.a .euiTab__prepend').hasText('*');
    assert.dom('button.b').hasAttribute('aria-selected', 'false', 'explicit "false", not a missing attribute');
    assert.dom('a.c').hasAttribute('href', '#c').hasAttribute('role', 'tab');
    assert.dom('button.d').isDisabled().hasClass('euiTab-isDisabled');

    await click('button.b');
    assert.strictEqual(state.selected, 'b');
  });

  test('condensed tabs have no bottom border', async function (assert) {
    await render(<template><EuiTabs @display="condensed"><EuiTab>A</EuiTab></EuiTabs></template>);

    assert.dom('.euiTabs').hasClass('euiTabs--condensed').doesNotHaveClass('euiTabs--bottomBorder');
  });

  test('EuiTabbedContent switches the panel when a tab is clicked', async function (assert) {
    const clicked: string[] = [];
    const onTabClick = (tab: { id: string }) => clicked.push(tab.id);

    await render(
      <template>
        <EuiTabbedContent @tabs={{TABS}} @onTabClick={{onTabClick}}>
          <:selectedTabContent as |tab|><p class="panel">Panel {{tab.name}}</p></:selectedTabContent>
        </EuiTabbedContent>
      </template>
    );

    assert.dom('[role="tab"]').exists({ count: 3 });
    assert.dom('[role="tabpanel"] .panel').hasText('Panel One');

    await click('[role="tab"]:nth-child(2)');

    assert.deepEqual(clicked, ['two']);
    assert.dom('[role="tabpanel"] .panel').hasText('Panel Two');
    assert.dom('[role="tab"]:nth-child(2)').hasAttribute('aria-selected', 'true');
    assert.dom('[role="tab"]:nth-child(3)').isDisabled();
  });

  test('EuiTabbedContent @initialSelectedTab', async function (assert) {
    const second = TABS[1];

    await render(
      <template>
        <EuiTabbedContent @tabs={{TABS}} @initialSelectedTab={{second}}>
          <:selectedTabContent as |tab|>{{tab.name}}</:selectedTabContent>
        </EuiTabbedContent>
      </template>
    );

    assert.dom('[role="tabpanel"]').hasText('Two');
  });
});
