import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render } from '@ember/test-helpers';
import { on } from '@ember/modifier';

import EuiFacetButton from '#src/components/eui-facet-button.gts';
import EuiFacetGroup from '#src/components/eui-facet-group.gts';
import EuiIcon from '#src/components/eui-icon.gts';

module('Integration | Component | eui-facet-button and eui-facet-group', function (hooks) {
  setupRenderingTest(hooks);

  test('a facet button shows its name, quantity and icon', async function (assert) {
    let clicks = 0;
    const onClick = () => clicks++;

    await render(
      <template>
        <EuiFacetButton @quantity={{6}} {{on "click" onClick}}>
          <:default>Errors</:default>
          <:icon><EuiIcon class="euiFacetButton__icon" @type="dot" @color="danger" /></:icon>
        </EuiFacetButton>
      </template>
    );

    assert.dom('button.euiFacetButton').hasClass('euiFacetButton--unSelected').hasAttribute('title', 'Errors');
    assert.dom('.euiFacetButton__text').hasText('Errors').hasAttribute('data-text', 'Errors');
    assert.dom('.euiFacetButton__quantity').hasText('6').hasClass('euiNotificationBadge--subdued');
    assert.dom('.euiFacetButton__icon').exists();

    await click('button');
    assert.strictEqual(clicks, 1);
  });

  test('selected, loading and disabled states', async function (assert) {
    await render(
      <template>
        <EuiFacetButton class="selected" @quantity={{2}} @isSelected={{true}}>A</EuiFacetButton>
        <EuiFacetButton class="loading" @quantity={{2}} @isLoading={{true}}>B</EuiFacetButton>
        <EuiFacetButton class="disabled" @quantity={{0}} @isSelected={{true}} @isDisabled={{true}}>C</EuiFacetButton>
      </template>
    );

    assert.dom('.selected').hasClass('euiFacetButton--isSelected');
    // accent is the badge's default color, without a class of its own
    assert.dom('.selected .euiFacetButton__quantity').doesNotHaveClass('euiNotificationBadge--subdued');
    assert.dom('.loading').isDisabled();
    assert.dom('.loading .euiFacetButton__spinner').exists();
    assert.dom('.loading .euiFacetButton__quantity').doesNotExist();
    assert.dom('.disabled').isDisabled();
    assert.dom('.disabled .euiFacetButton__quantity').hasText('0').hasClass('euiNotificationBadge--subdued');
  });

  test('a facet group lays out its buttons', async function (assert) {
    await render(
      <template>
        <EuiFacetGroup class="vertical"><EuiFacetButton>A</EuiFacetButton></EuiFacetGroup>
        <EuiFacetGroup class="horizontal" @layout="horizontal" @gutterSize="l"><EuiFacetButton>B</EuiFacetButton></EuiFacetGroup>
      </template>
    );

    assert
      .dom('.vertical')
      .hasClass('euiFacetGroup')
      .hasClass('euiFacetGroup--vertical')
      .hasClass('euiFacetGroup--gutterMedium')
      .hasClass('euiFlexGroup--directionColumn');
    assert
      .dom('.horizontal')
      .hasClass('euiFacetGroup--horizontal')
      .hasClass('euiFacetGroup--gutterLarge')
      .hasClass('euiFlexGroup--wrap');
  });
});
