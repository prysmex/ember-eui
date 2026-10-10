import { tracked } from '@glimmer/tracking';
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render, rerender, triggerKeyEvent } from '@ember/test-helpers';

import EuiPanel from '#src/components/eui-panel.gts';
import lightTheme from '../../../vendor/eui_theme_light.min.css?raw';

module('Integration | Component | eui-panel', function (hooks) {
  setupRenderingTest(hooks);

  test('default plain panel with shadow and medium padding', async function (assert) {
    await render(
      <template>
        <EuiPanel>Content</EuiPanel>
      </template>
    );

    assert
      .dom('.euiPanel')
      .hasClass('euiPanel--plain')
      .hasClass('euiPanel--hasShadow')
      .hasClass('euiPanel--paddingMedium')
      .hasClass('euiPanel--borderRadiusMedium')
      .hasText('Content');
  });

  test('color, padding, border radius, border and grow', async function (assert) {
    await render(
      <template>
        <EuiPanel
          @color="subdued"
          @hasShadow={{false}}
          @paddingSize="l"
          @borderRadius="none"
          @grow={{false}}
          class="a"
        />
        <EuiPanel @hasBorder={{true}} class="b" />
      </template>
    );

    assert
      .dom('.a')
      .hasClass('euiPanel--subdued')
      .hasClass('euiPanel--noShadow')
      .hasClass('euiPanel--paddingLarge')
      .hasClass('euiPanel--borderRadiusNone')
      .hasClass('euiPanel--flexGrowZero')
      .doesNotHaveClass('euiPanel--hasShadow');
    assert.dom('.b').hasClass('euiPanel--hasBorder');
  });

  test('@onClick makes it a clickable button', async function (assert) {
    let clicks = 0;
    const onClick = () => clicks++;

    await render(
      <template>
        <EuiPanel @onClick={{onClick}}>Click</EuiPanel>
      </template>
    );

    assert
      .dom('.euiPanel')
      .hasAttribute('role', 'button')
      .hasClass('euiPanel--isClickable');
    await click('.euiPanel');
    assert.strictEqual(clicks, 1);
  });

  test('a clickable panel is focusable and activated by Enter and Space', async function (assert) {
    let clicks = 0;
    const onClick = () => clicks++;

    await render(
      <template>
        <EuiPanel @onClick={{onClick}}>
          Click
          <input class="inner" aria-label="inner" />
        </EuiPanel>
      </template>
    );

    assert.dom('.euiPanel').hasAttribute('tabindex', '0');

    await triggerKeyEvent('.euiPanel', 'keydown', 'Enter');
    await triggerKeyEvent('.euiPanel', 'keydown', ' ');
    assert.strictEqual(clicks, 2);

    await triggerKeyEvent('.euiPanel', 'keydown', 'A');
    await triggerKeyEvent('.inner', 'keydown', 'Enter');
    assert.strictEqual(
      clicks,
      2,
      'other keys and keys in inner controls are ignored'
    );
  });
  for (const clickable of [false, true]) {
    test(`clickable=${clickable}: disabling decoration and changing color removes theme borders and shadows`, async function (assert) {
      const state = new (class {
        @tracked decorate = false;
        @tracked border = false;
        @tracked color: 'plain' | 'subdued' = 'plain';
      })();
      const onClick = clickable ? () => {} : undefined;
      const theme = document.createElement('style');
      // settled() does not await CSS transitions; inspect the final decoration.
      theme.textContent = `${lightTheme}.euiPanel.euiPanel--isClickable { transition: none; }`;
      document.head.append(theme);
      try {
        await render(
          <template>
            <EuiPanel
              @onClick={{onClick}}
              @color={{state.color}}
              @hasBorder={{state.border}}
              @hasShadow={{state.decorate}}
            >Content</EuiPanel>
          </template>
        );
        assert
          .dom('.euiPanel')
          .hasClass('euiPanel--noBorder')
          .hasClass('euiPanel--noShadow')
          .hasStyle({ borderTopWidth: '0px', boxShadow: 'none' });
        state.decorate = true;
        await rerender();
        assert.notStrictEqual(
          getComputedStyle(this.element.querySelector('.euiPanel')!).boxShadow,
          'none'
        );
        state.border = true;
        await rerender();
        assert
          .dom('.euiPanel')
          .hasStyle({ borderTopWidth: '1px', boxShadow: 'none' });
        state.color = 'subdued';
        await rerender();
        assert
          .dom('.euiPanel')
          .hasClass('euiPanel--noBorder')
          .hasClass('euiPanel--noShadow')
          .hasStyle({ borderTopWidth: '0px', boxShadow: 'none' });
      } finally {
        theme.remove();
      }
    });
  }
});
