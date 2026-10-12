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

    // Latest-only: legacy modifier classes are gone; assert native styles.
    // Geometry coverage lives in eui-flex-family-test.gts.
    const css = (selector: string) =>
      getComputedStyle(document.querySelector(selector)!);
    assert.dom('div.default').hasClass('euiFlexGroup');
    assert.strictEqual(css('div.default').display, 'flex');
    assert.strictEqual(css('div.default').columnGap, '16px', 'default gutter m');
    assert.dom('div.default .euiFlexItem').exists();
    assert.dom('span.custom').hasClass('euiFlexGroup');
    const custom = css('span.custom');
    assert.strictEqual(custom.rowGap, '8px');
    assert.strictEqual(custom.alignItems, 'center');
    assert.strictEqual(custom.justifyContent, 'space-between');
    assert.strictEqual(custom.flexDirection, 'column');
    assert.strictEqual(custom.flexWrap, 'wrap');
    assert.dom('span.item-a').hasClass('euiFlexItem');
    assert.strictEqual(css('span.item-a').flexGrow, '0');
    assert.strictEqual(css('section.item-b').flexGrow, '3');
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

    const css = (selector: string) =>
      getComputedStyle(document.querySelector(selector)!);
    assert.dom('.grid').hasClass('euiFlexGrid');
    const grid = css('.grid');
    assert.strictEqual(grid.display, 'grid');
    assert.strictEqual(grid.gridTemplateColumns.split(' ').length, 3, 'three columns');
    assert.strictEqual(grid.columnGap, '8px');
    assert.strictEqual(grid.gridAutoFlow, 'column');
    assert.dom('.grid .euiFlexItem').exists({ count: 3 });
    assert.dom('ul.list').hasClass('euiFlexGrid');
    assert.strictEqual(css('ul.list').display, 'grid', 'default is one grid column (upstream)');
  });
});
