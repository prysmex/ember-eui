import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';

import EuiFlexGrid from '#src/components/eui-flex-grid.gts';
import EuiFlexGroup from '#src/components/eui-flex-group.gts';
import EuiFlexItem from '#src/components/eui-flex-item.gts';

module('Integration | Component | eui-flex', function (hooks) {
  setupRenderingTest(hooks);

  test('EuiFlexGroup defaults and options', async function (assert) {
    await render(
      <template>
        <EuiFlexGroup class="default"><EuiFlexItem>a</EuiFlexItem></EuiFlexGroup>
        <EuiFlexGroup @gutterSize="s" @alignItems="center" @justifyContent="spaceBetween" @direction="column" @wrap={{true}} @responsive={{false}} @tagName="span" class="custom">
          <EuiFlexItem @grow={{false}} @tagName="span" class="item-a">a</EuiFlexItem>
          <EuiFlexItem @grow={{3}} @tagName="section" class="item-b">b</EuiFlexItem>
        </EuiFlexGroup>
      </template>
    );

    assert.dom('div.default').hasClass('euiFlexGroup').hasClass('euiFlexGroup--gutterLarge').hasClass('euiFlexGroup--responsive');
    assert.dom('div.default .euiFlexItem').exists();
    assert.dom('span.custom').hasClass('euiFlexGroup--gutterSmall').hasClass('euiFlexGroup--alignItemsCenter').hasClass('euiFlexGroup--justifyContentSpaceBetween').hasClass('euiFlexGroup--directionColumn').hasClass('euiFlexGroup--wrap').doesNotHaveClass('euiFlexGroup--responsive');
    assert.dom('span.item-a').hasClass('euiFlexItem--flexGrowZero');
    assert.dom('section.item-b').hasClass('euiFlexItem--flexGrow3');
  });

  test('EuiFlexGrid columns, gutter and direction', async function (assert) {
    await render(
      <template>
        <EuiFlexGrid @columns={{3}} @gutterSize="s" @direction="column" class="grid">
          <EuiFlexItem>1</EuiFlexItem><EuiFlexItem>2</EuiFlexItem><EuiFlexItem>3</EuiFlexItem>
        </EuiFlexGrid>
        <EuiFlexGrid @tagName="ul" @responsive={{false}} class="list" />
      </template>
    );

    assert.dom('.grid').hasClass('euiFlexGrid--thirds').hasClass('euiFlexGrid--gutterSmall').hasClass('euiFlexGrid--directionColumn').hasClass('euiFlexGrid--responsive');
    assert.dom('.grid .euiFlexItem').exists({ count: 3 });
    assert.dom('ul.list').hasClass('euiFlexGrid--wrap').doesNotHaveClass('euiFlexGrid--responsive');
  });
});
