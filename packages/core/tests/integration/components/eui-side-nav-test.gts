import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import EuiSideNav from '#src/components/eui-side-nav.gts';

class State {
  @tracked selectedItem = 'users';
}

function buildItems(state: State) {
  const item = (id: string, extra: Record<string, unknown> = {}) => ({
    id,
    name: id[0]!.toUpperCase() + id.slice(1),
    onClick: () => (state.selectedItem = id),
    ...extra
  });

  return [
    {
      id: 'elasticsearch',
      name: 'Elasticsearch',
      icon: 'logoElasticsearch',
      items: [item('users'), item('roles'), item('sources', { disabled: true })]
    },
    item('kibana', { icon: 'logoKibana' })
  ];
}

module('Integration | Component | eui-side-nav', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders nested items and selects the @selectedItem child', async function (assert) {
    const state = new State();
    const items = buildItems(state);

    await render(
      <template><EuiSideNav @items={{items}} @selectedItem={{state.selectedItem}} /></template>
    );

    assert.dom('nav.euiSideNav').exists();
    assert.dom('.euiSideNavItem--root').exists({ count: 2 });
    assert.dom('.euiSideNavItem--root').hasClass('euiSideNavItem--hasChildItems');
    assert.dom('.euiSideNavItemButton-isSelected').hasText('Users');
    assert.dom('button.euiSideNavItemButton[disabled]').hasText('Sources');

    await click('.euiSideNavItem--trunk:nth-child(2) button');

    assert.strictEqual(state.selectedItem, 'roles');
    assert.dom('.euiSideNavItemButton-isSelected').hasText('Roles');
  });

  test('a heading block is visible', async function (assert) {
    const items = buildItems(new State());

    await render(
      <template>
        <EuiSideNav @items={{items}}>
          <:heading>Block heading</:heading>
        </EuiSideNav>
      </template>
    );

    assert.dom('.euiSideNav__heading').hasText('Block heading');
  });

  // Bug: the @heading branch checks the imported `screenReaderOnly`
  // modifier (always truthy) instead of @headingProps.screenReaderOnly
  test.todo('@heading is visible unless headingProps.screenReaderOnly', async function (assert) {
    const items = buildItems(new State());

    await render(<template><EuiSideNav @heading="Plain heading" @items={{items}} /></template>);

    assert.dom('.euiSideNav__heading').hasText('Plain heading');
  });

  // Bug: root items compare item.id with item.isSelected instead of @selectedItem
  test.todo('a clickable root item can be selected through @selectedItem', async function (assert) {
    const state = new State();
    const items = buildItems(state);

    state.selectedItem = 'kibana';

    await render(
      <template><EuiSideNav @items={{items}} @selectedItem={{state.selectedItem}} /></template>
    );

    assert.dom('.euiSideNavItemButton-isSelected').hasText('Kibana');
  });
});
