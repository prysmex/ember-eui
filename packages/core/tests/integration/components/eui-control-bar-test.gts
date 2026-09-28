import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render } from '@ember/test-helpers';

import EuiControlBar from '#src/components/eui-control-bar.gts';

import type { EuiControlBarControl } from '#src/components/eui-control-bar.gts';

module('Integration | Component | eui-control-bar', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders each type of control', async function (assert) {
    const clicked: string[] = [];
    const controls: EuiControlBarControl[] = [
      { controlType: 'icon', id: 'logo', iconType: 'logoElastic', 'aria-label': 'Elastic' },
      { controlType: 'breadcrumbs', id: 'crumbs', breadcrumbs: [{ text: 'Root' }, { text: 'Page' }] },
      { controlType: 'spacer' },
      { controlType: 'text', id: 'status', text: 'Saved' },
      { controlType: 'divider' },
      { controlType: 'button', id: 'run', label: 'Run', onClick: () => clicked.push('run') },
      { controlType: 'icon', id: 'close', iconType: 'cross', 'aria-label': 'Close', onClick: () => clicked.push('close') },
    ];

    await render(<template><EuiControlBar @controls={{controls}} @position="relative" /></template>);

    assert.dom('section.euiControlBar').hasClass('euiControlBar--relative').hasClass('euiControlBar--large').hasAria('label', 'Page level controls');
    assert.dom('.euiControlBar h2').hasText('Page level controls');
    assert.dom('.euiControlBar__icon').exists();
    assert.dom('.euiControlBar__breadcrumbs').exists();
    assert.dom('.euiControlBar__spacer').exists();
    assert.dom('.euiControlBar__text').hasText('Saved');
    assert.dom('.euiControlBar__divider').exists();

    await click('.euiControlBar__button');
    await click('.euiControlBar__buttonIcon');
    assert.deepEqual(clicked, ['run', 'close']);
  });

  test('tabs and content', async function (assert) {
    let tabClicks = 0;
    const controls: EuiControlBarControl[] = [{ controlType: 'tab', id: 'console', label: 'Console', onClick: () => tabClicks++ }];

    await render(
      <template>
        <EuiControlBar @controls={{controls}} @position="relative" @showContent={{true}} @size="s">
          <p class="content">Output</p>
        </EuiControlBar>
      </template>
    );

    assert.dom('.euiControlBar').hasClass('euiControlBar-isOpen').hasClass('euiControlBar--small');
    assert.dom('.euiControlBar__content .content').hasText('Output');
    assert.dom('.euiControlBar__tab').doesNotHaveClass('euiControlBar__tab--active');

    await click('.euiControlBar__tab');
    assert.strictEqual(tabClicks, 1);
    assert.dom('.euiControlBar__tab').hasClass('euiControlBar__tab--active');
  });

  test('a fixed bar renders at the end of body and pads it', async function (assert) {
    const controls: EuiControlBarControl[] = [{ controlType: 'text', id: 't', text: 'Fixed' }];

    await render(
      <template><EuiControlBar @controls={{controls}} @landmarkHeading="Editor controls" @bodyClassName="has-bar" /></template>
    );

    assert.dom('.euiControlBar', document.body).hasClass('euiControlBar--fixed').hasAria('label', 'Editor controls');
    assert.dom('[aria-live="assertive"]', document.body).includesText('Editor controls');
    assert.dom(document.body).hasClass('has-bar');
    assert.notStrictEqual(document.body.style.paddingBottom, '');
  });
});
