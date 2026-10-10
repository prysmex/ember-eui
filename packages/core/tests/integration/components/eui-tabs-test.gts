import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { on } from '@ember/modifier';
import { click, focus, render, settled } from '@ember/test-helpers';
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

  test('EuiTabbedContent follows externally controlled selection', async function (assert) {
    class State {
      @tracked selected = TABS[1];
    }
    const state = new State();
    const clicked: string[] = [];
    const onTabClick = (tab: { id: string }) => clicked.push(tab.id);

    await render(
      <template>
        <EuiTabbedContent @tabs={{TABS}} @selectedTab={{state.selected}} @onTabClick={{onTabClick}}>
          <:selectedTabContent as |tab|>{{tab.name}}</:selectedTabContent>
        </EuiTabbedContent>
      </template>
    );

    assert.dom('[role="tabpanel"]').hasText('Two').hasAttribute('aria-labelledby', 'two');
    assert.dom('#two').hasAttribute('aria-selected', 'true');

    await click('#one');

    assert.deepEqual(clicked, ['one']);
    assert.dom('[role="tabpanel"]').hasText('Two', 'the owner controls selection after a click');

    state.selected = TABS[0];
    await settled();

    assert.dom('[role="tabpanel"]').hasText('One').hasAttribute('aria-labelledby', 'one');
    assert.dom('#one').hasAttribute('aria-selected', 'true');
    assert.dom('#two').hasAttribute('aria-selected', 'false');
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

  test('selected autofocus follows controlled selection when entering and re-entering the tabs', async function (assert) {
    const state = new (class {
      @tracked selected = TABS[1];
    })();

    await render(
      <template>
        <button class="outside" type="button">Outside</button>
        <EuiTabbedContent @tabs={{TABS}} @selectedTab={{state.selected}} @autoFocus="selected">
          <:selectedTabContent as |tab|>{{tab.name}}</:selectedTabContent>
        </EuiTabbedContent>
      </template>
    );

    await focus('#one');
    assert.dom('#two').isFocused();

    await focus('#one');
    assert.dom('#one').isFocused('moving within the tablist does not reset focus');

    await focus('.outside');
    state.selected = TABS[0];
    await settled();
    await focus('#two');
    assert.dom('#one').isFocused('re-entry uses the current controlled selection');
  });

  test('tab selection supports IDs with CSS special characters and labels its panel', async function (assert) {
    const tabs = [{ id: 'first', name: 'First' }, { id: 'tab:2.with.dot', name: 'Second' }];

    await render(
      <template>
        <EuiTabbedContent @tabs={{tabs}}>
          <:selectedTabContent as |tab|>{{tab.name}}</:selectedTabContent>
        </EuiTabbedContent>
      </template>
    );

    const second = this.element.querySelectorAll<HTMLElement>('[role="tab"]')[1]!;
    await click(second);
    assert.dom(second).isFocused().hasAttribute('aria-selected', 'true');
    assert.dom('[role="tabpanel"]').hasText('Second').hasAttribute('aria-labelledby', second.id);
    assert.strictEqual(second.getAttribute('aria-controls'), this.element.querySelector('[role="tabpanel"]')!.id);
  });

  test('empty tabs and removal of the selected tab render no stale panel', async function (assert) {
    const state = new (class {
      @tracked tabs = [...TABS];
      removeOnClick = false;
      click = () => {
        if (this.removeOnClick) this.tabs = [];
      };
    })();

    await render(
      <template>
        <EuiTabbedContent @tabs={{state.tabs}} @onTabClick={{state.click}}>
          <:selectedTabContent as |tab|>{{tab.name}}</:selectedTabContent>
        </EuiTabbedContent>
      </template>
    );

    await click('#two');
    state.tabs = [TABS[0]!];
    await settled();
    assert.dom('[role="tabpanel"]').doesNotExist();
    assert.dom('#one').hasAttribute('aria-selected', 'false');

    state.removeOnClick = true;
    await click('#one');
    assert.dom('[role="tab"]').doesNotExist();
    assert.dom('[role="tabpanel"]').doesNotExist();
  });
});
