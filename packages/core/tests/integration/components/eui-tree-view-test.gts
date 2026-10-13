import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render, triggerKeyEvent } from '@ember/test-helpers';

import EuiTreeView from '#src/components/eui-tree-view.gts';

import type { EuiTreeViewNode } from '#src/components/eui-tree-view.gts';

const ITEMS: EuiTreeViewNode[] = [
  {
    id: 'src',
    label: 'src',
    icon: 'folderClosed',
    iconWhenExpanded: 'folderOpen',
    children: [
      { id: 'index', label: 'index.ts', icon: 'document' },
      { id: 'utils', label: 'utils', icon: 'folderClosed', children: [{ id: 'dates', label: 'dates.ts' }] },
    ],
  },
  { id: 'readme', label: 'README.md', icon: 'document' },
];

module('Integration | Component | eui-tree-view', function (hooks) {
  setupRenderingTest(hooks);

  test('nodes open and close their children', async function (assert) {
    await render(<template><EuiTreeView @items={{ITEMS}} aria-label="Files" /></template>);

    assert.dom('ul.euiTreeView').hasAria('label', 'Files');
    assert.dom('.euiTreeView__nodeLabel').exists({ count: 2 }, 'children are closed');
    assert.dom('#src').hasAria('expanded', 'false');

    await click('#src');
    assert.dom('#src').hasAria('expanded', 'true');
    assert.dom('#index').exists();
    assert.dom('#src').hasClass('euiTreeView__node--active');
    assert.dom('#src').hasAria('controls', this.element.querySelector('#src')!.nextElementSibling!.id);

    await click('#src');
    assert.dom('#index').doesNotExist();
  });

  test('isExpanded, expandByDefault and callbacks', async function (assert) {
    const called: string[] = [];
    const items: EuiTreeViewNode[] = [
      { id: 'a', label: 'A', isExpanded: true, children: [{ id: 'a1', label: 'A1', callback: () => called.push('a1') }] },
      { id: 'b', label: 'B', children: [{ id: 'b1', label: 'B1' }] },
    ];

    await render(<template><EuiTreeView class="one" @items={{items}} aria-label="One" /></template>);

    assert.dom('#a1').exists();
    assert.dom('#b1').doesNotExist();
    await click('#a1');
    assert.deepEqual(called, ['a1']);
  });

  test('expandByDefault opens every node', async function (assert) {
    await render(<template><EuiTreeView @items={{ITEMS}} @expandByDefault={{true}} aria-label="Files" /></template>);

    assert.dom('#dates').exists();
  });

  test('arrow keys move between nodes and open or close them', async function (assert) {
    await render(<template><EuiTreeView @items={{ITEMS}} aria-label="Files" /></template>);

    await triggerKeyEvent('#src', 'keydown', 'ArrowRight');
    assert.dom('#index').exists('arrow right opens');

    (this.element.querySelector('#src') as HTMLElement).focus();
    await triggerKeyEvent('#src', 'keydown', 'ArrowDown');
    assert.dom('#index').isFocused();
    await triggerKeyEvent('#index', 'keydown', 'ArrowDown');
    assert.dom('#utils').isFocused();
    await triggerKeyEvent('#utils', 'keydown', 'ArrowLeft');
    assert.dom('#src').isFocused('arrow left in the children goes back to the parent');

    await triggerKeyEvent('#src', 'keydown', 'ArrowLeft');
    assert.dom('#index').doesNotExist('arrow left closes');
  });

  test('icons, arrows, compressed display and the label block', async function (assert) {
    await render(
      <template>
        <EuiTreeView @items={{ITEMS}} @display="compressed" @showExpansionArrows={{true}} aria-label="Files">
          <:label as |node|><em>{{node.label}}</em></:label>
        </EuiTreeView>
      </template>
    );

    // legacy `--compressed`/`--withArrows` and the `euiText` wrapper are gone:
    // compressed is measured (upstream button height `size.l`, 24px)
    assert.dom('.euiTreeView__wrapper').doesNotExist();
    assert.strictEqual(getComputedStyle(this.element.querySelector('#src')!).height, '24px');
    assert.dom('#readme .euiTreeView__arrowPlaceholder').exists('leaves keep the arrow space');
    assert.dom('#src .euiTreeView__expansionArrow').exists();
    assert.dom('#readme .euiTreeView__expansionArrow').doesNotExist();
    assert.dom('#src .euiTreeView__iconWrapper .euiIcon').exists();
    assert.dom('#readme em').hasText('README.md');

    await click('#src');
    assert.dom('#index em').hasText('index.ts', 'nested levels use the label block too');
  });

  test('icon and iconWhenExpanded can be components (e.g. EuiToken) next to icon types', async function (assert) {
    const Closed = <template><span class="custom-closed">C</span></template>;
    const Open = <template><span class="custom-open">O</span></template>;
    const items: EuiTreeViewNode[] = [
      { id: 'a', label: 'A', icon: Closed, iconWhenExpanded: Open, children: [{ id: 'a1', label: 'A1', icon: 'document' }] },
      { id: 'b', label: 'B', icon: 'document' }
    ];
    await render(<template><EuiTreeView @items={{items}} aria-label="Custom icons" /></template>);

    assert.dom('.euiTreeView__iconWrapper .custom-closed').exists();
    assert.dom('.euiTreeView__iconWrapper .custom-open').doesNotExist();
    assert.dom('.euiTreeView__iconWrapper svg').exists({ count: 1 }, 'string icons still use EuiIcon');

    await click('#a');
    assert.dom('.euiTreeView__iconWrapper .custom-open').exists();
    assert.dom('.euiTreeView__iconWrapper .custom-closed').doesNotExist();
  });
});
