import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { on } from '@ember/modifier';
import { click, render } from '@ember/test-helpers';

import EuiFilterButton from '#src/components/eui-filter-button.gts';
import EuiFilterGroup from '#src/components/eui-filter-group.gts';
import EuiFilterSelectItem from '#src/components/eui-filter-select-item.gts';

module('Integration | Component | eui-filter-group', function (hooks) {
  setupRenderingTest(hooks);

  test('a group of filter buttons', async function (assert) {
    let clicks = 0;
    const onClick = () => clicks++;

    await render(
      <template>
        <EuiFilterGroup @fullWidth={{true}}>
          <EuiFilterButton class="on" @withNext={{true}} @hasActiveFilters={{true}} {{on "click" onClick}}>On</EuiFilterButton>
          <EuiFilterButton class="off">Off</EuiFilterButton>
        </EuiFilterGroup>
      </template>
    );

    assert.dom('.euiFilterGroup').hasClass('euiFilterGroup--fullWidth');
    assert
      .dom('.on')
      .hasClass('euiFilterButton')
      .hasClass('euiFilterButton--withNext')
      .hasClass('euiFilterButton-hasActiveFilters')
      .hasClass('euiButtonEmpty--text');
    assert.dom('.on .euiFilterButton__textShift').hasText('On').hasAttribute('data-text', 'On').hasAttribute('title', 'On');

    await click('.on');
    assert.strictEqual(clicks, 1);
  });

  test('badges count available or active filters', async function (assert) {
    await render(
      <template>
        <EuiFilterButton class="available" @iconType="arrowDown" @numFilters={{12}}>Status</EuiFilterButton>
        <EuiFilterButton class="active" @iconType="arrowDown" @numFilters={{12}} @numActiveFilters={{2}} @hasActiveFilters={{true}} @isSelected={{true}}>Tags</EuiFilterButton>
        <EuiFilterButton class="none">Plain</EuiFilterButton>
      </template>
    );

    assert.dom('.available').hasClass('euiFilterButton-hasNotification').hasClass('euiFilterButton--hasIcon');
    assert.dom('.available .euiFilterButton__notification').hasText('12').hasAria('label', '12 available filters').hasClass('euiNotificationBadge--subdued');
    assert.dom('.active').hasClass('euiFilterButton-isSelected').hasAria('pressed', 'true');
    assert.dom('.active .euiFilterButton__notification').hasText('2').hasAria('label', '2 active filters').doesNotHaveClass('euiNotificationBadge--subdued');
    assert.dom('.none .euiFilterButton__notification').doesNotExist();
  });

  test('filter select items show whether they are applied', async function (assert) {
    await render(
      <template>
        <div role="listbox" aria-label="Status">
          <EuiFilterSelectItem class="on" @checked="on">Open</EuiFilterSelectItem>
          <EuiFilterSelectItem class="off" @checked="off">Closed</EuiFilterSelectItem>
          <EuiFilterSelectItem class="none" @isFocused={{true}}>Draft</EuiFilterSelectItem>
          <EuiFilterSelectItem class="noicons" @showIcons={{false}} @disabled={{true}}>Archived</EuiFilterSelectItem>
        </div>
      </template>
    );

    assert.dom('.on').hasAttribute('role', 'option').hasText('Open');
    assert.dom('.on .euiIcon').exists();
    assert.dom('.off .euiIcon').exists();
    assert.dom('.none').hasClass('euiFilterSelectItem-isFocused').hasAria('selected', 'true');
    assert.dom('.noicons .euiIcon').doesNotExist();
    assert.dom('.noicons').isDisabled();
  });
});
