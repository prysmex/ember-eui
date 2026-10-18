import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import {
  click,
  render,
  rerender,
  triggerKeyEvent,
  focus
} from '@ember/test-helpers';

import EuiPanel from '#src/components/eui-panel.gts';
import EuiPageContent from '#src/components/eui-page-content.gts';
import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';
import {
  euiBackgroundColor,
  euiPaddingSize,
  euiBorderColor
} from '#src/utils/eui/styles.generated.ts';

function rgb(color: string): string {
  const probe = document.createElement('div');
  probe.style.color = color;
  document.body.append(probe);
  const computed = getComputedStyle(probe).color;
  probe.remove();
  return computed;
}

module('Integration | Component | eui-panel | Borealis', function (hooks) {
  setupRenderingTest(hooks);

  test('upstream defaults without legacy stylesheet, with attrs and modifiers', async function (assert) {
    let events = 0;
    const listener = () => events++;
    await render(
      <template>
        <EuiPanel
          data-panel
          aria-label="Surface"
          class="custom"
          {{on "mouseenter" listener}}
        >Content</EuiPanel>
      </template>
    );
    const panel = this.element.querySelector('[data-panel]')!;
    const computed = getComputedStyle(panel);
    const theme = resolveBorealisTheme('light');
    assert
      .dom(panel)
      .hasClass('euiPanel', 'upstream class name')
      .hasClass('euiPanelBorealis')
      .hasClass('custom')
      .hasText('Content')
      .hasAttribute('aria-label', 'Surface')
      .doesNotHaveAttribute('role');
    assert.strictEqual(computed.paddingTop, euiPaddingSize(theme, 'm'));
    assert.strictEqual(
      computed.borderRadius,
      theme.euiTheme.border.radius.panel
    );
    assert.strictEqual(
      computed.backgroundColor,
      rgb(euiBackgroundColor(theme, 'plain'))
    );
    assert.strictEqual(
      computed.boxShadow,
      'none',
      'latest default is border without shadow'
    );
    assert.strictEqual(
      getComputedStyle(panel, '::after').borderTopWidth,
      '1px',
      'normal-contrast border is a pseudo element'
    );
    assert.strictEqual(computed.flexGrow, '1');
    panel.dispatchEvent(new MouseEvent('mouseenter'));
    assert.strictEqual(events, 1, 'element modifiers attach to root');
  });

  test('page content uses latest surface defaults while preserving centered growth', async function (assert) {
    await render(
      <template>
        <EuiPageContent data-default />
        <EuiPageContent @verticalPosition="center" data-centered />
        <EuiPageContent
          @horizontalPosition="center"
          @grow={{true}}
          @hasShadow={{false}}
          @hasBorder={{true}}
          data-override
        />
      </template>
    );
    const normal = this.element.querySelector('[data-default]')!;
    const centered = this.element.querySelector('[data-centered]')!;
    const override = this.element.querySelector('[data-override]')!;
    assert.strictEqual(getComputedStyle(normal).boxShadow, 'none');
    assert.dom(normal).hasStyle({ flexGrow: '1' });
    assert.strictEqual(
      getComputedStyle(normal, '::after').borderTopWidth,
      '1px'
    );
    assert.dom(centered).hasStyle({ flexGrow: '0' });
    assert.dom(override).hasStyle({ flexGrow: '1', boxShadow: 'none' });
  });

  for (const mode of ['light', 'dark'] as const) {
    for (const color of [
      'plain',
      'transparent',
      'subdued',
      'accent',
      'primary',
      'success',
      'warning',
      'danger'
    ] as const) {
      test(`${mode}/${color}: correct upstream background and shadow eligibility`, async function (assert) {
        await render(
          <template>
            <EuiEmotionProvider @colorMode={{mode}}><EuiPanel
                @color={{color}}
                @hasShadow={{true}}
                @hasBorder={{false}}
                data-panel
              /></EuiEmotionProvider>
          </template>
        );
        const panel = this.element.querySelector('[data-panel]')!;
        const expected =
          color === 'transparent'
            ? 'rgba(0, 0, 0, 0)'
            : rgb(euiBackgroundColor(resolveBorealisTheme(mode), color));
        const before = getComputedStyle(panel);
        assert.strictEqual(before.backgroundColor, expected);
        assert.strictEqual(before.borderTopWidth, '0px');
        assert.strictEqual(
          before.boxShadow === 'none',
          color !== 'plain',
          'shadow only on plain without border'
        );
      });
    }
  }

  test('padding, radius, grow and decoration react to argument updates', async function (assert) {
    const state = new (class {
      @tracked padding: 'none' | 's' | 'm' | 'l' = 'none';
      @tracked radius: 'none' | 'm' = 'none';
      @tracked grow = false;
      @tracked border = false;
      @tracked shadow = false;
      @tracked color: 'plain' | 'subdued' = 'plain';
    })();
    await render(
      <template>
        <EuiPanel
          @paddingSize={{state.padding}}
          @borderRadius={{state.radius}}
          @grow={{state.grow}}
          @hasBorder={{state.border}}
          @hasShadow={{state.shadow}}
          @color={{state.color}}
          data-panel
        />
      </template>
    );
    const panel = this.element.querySelector('[data-panel]')!;
    assert.dom(panel).hasStyle({
      paddingTop: '0px',
      borderRadius: '0px',
      flexGrow: '0',
      boxShadow: 'none'
    });
    for (const padding of ['s', 'm', 'l', 'none'] as const) {
      state.padding = padding;
      await rerender();
      assert.strictEqual(
        getComputedStyle(panel).paddingTop,
        euiPaddingSize(resolveBorealisTheme('light'), padding) ?? '0px'
      );
    }
    state.shadow = true;
    state.radius = 'm';
    state.grow = true;
    await rerender();
    assert.notStrictEqual(getComputedStyle(panel).boxShadow, 'none');
    assert.dom(panel).hasStyle({ flexGrow: '1' });
    state.border = true;
    await rerender();
    assert.dom(panel).hasStyle({ boxShadow: 'none' });
    assert.strictEqual(
      getComputedStyle(panel, '::after').borderTopWidth,
      '1px'
    );
    state.color = 'subdued';
    await rerender();
    assert.strictEqual(
      getComputedStyle(panel, '::after').content,
      'none',
      'colored panels do not retain stale border'
    );
    assert.dom(panel).hasStyle({ boxShadow: 'none' });
  });

  test('click, Enter and Space activate, nested controls and unrelated keys do not', async function (assert) {
    let clicks = 0;
    const onClick = () => clicks++;
    await render(
      <template>
        <EuiPanel @onClick={{onClick}} data-panel dir="rtl">Click<input
            data-inner
            aria-label="inner"
          /></EuiPanel>
      </template>
    );
    const panel = this.element.querySelector('[data-panel]')!;
    assert
      .dom(panel)
      .hasAttribute('role', 'button')
      .hasAttribute('tabindex', '0')
      .hasStyle({ cursor: 'pointer', textAlign: 'start' });
    await click(panel);
    await triggerKeyEvent(panel, 'keydown', 'Enter');
    await triggerKeyEvent(panel, 'keydown', ' ');
    assert.strictEqual(clicks, 3);
    await triggerKeyEvent(panel, 'keydown', 'A');
    await triggerKeyEvent('[data-inner]', 'keydown', 'Enter');
    await triggerKeyEvent('[data-inner]', 'keydown', ' ');
    assert.strictEqual(clicks, 3);
    const space = new KeyboardEvent('keydown', {
      key: ' ',
      bubbles: true,
      cancelable: true
    });
    panel.dispatchEvent(space);
    assert.true(space.defaultPrevented, 'Space prevents page scrolling');
    await focus(panel);
    assert.strictEqual(document.activeElement, panel);
  });

  for (const contrast of [false, 'preferred'] as const) {
    test(`interactive contrast=${contrast}: native focus decoration respects contrast`, async function (assert) {
      const noop = () => {};
      await render(
        <template>
          <EuiEmotionProvider @highContrastMode={{contrast}}><EuiPanel
              @onClick={{noop}}
              data-panel
            /></EuiEmotionProvider>
        </template>
      );
      const panel = this.element.querySelector('[data-panel]')!;
      const stopAnimations = document.createElement('style');
      stopAnimations.textContent =
        '[data-panel] { transition: none !important; }';
      document.head.append(stopAnimations);
      try {
        await focus(panel);
        const shadow = getComputedStyle(panel).boxShadow;
        const outline = getComputedStyle(panel).outlineColor;
        assert.strictEqual(getComputedStyle(panel).transform, 'none');
        assert.strictEqual(shadow === 'none', !!contrast);
        assert.notStrictEqual(outline, 'rgba(0, 0, 0, 0)');
      } finally {
        stopAnimations.remove();
      }
    });
  }

  test('isClickable false suppresses hover decoration while preserving activation', async function (assert) {
    let clicks = 0;
    const onClick = () => clicks++;
    await render(
      <template>
        <EuiPanel @onClick={{onClick}} @isClickable={{false}} data-panel />
      </template>
    );
    assert
      .dom('[data-panel]')
      .hasStyle({ cursor: 'auto' })
      .hasAttribute('role', 'button');
    await click('[data-panel]');
    await triggerKeyEvent('[data-panel]', 'keydown', 'Enter');
    assert.strictEqual(clicks, 2);
  });

  test('nearest provider inherits mode/overrides and siblings remain isolated on updates', async function (assert) {
    const state = new (class {
      @tracked mode: 'light' | 'dark' = 'light';
      @tracked overrides = { border: { radius: { panel: '19px' } } };
    })();
    await render(
      <template>
        <EuiEmotionProvider
          @colorMode={{state.mode}}
          @borealisOverrides={{state.overrides}}
        >
          <EuiPanel data-parent />
          <EuiEmotionProvider><EuiPanel data-child /></EuiEmotionProvider>
          <EuiEmotionProvider @colorMode="light"><EuiPanel
              data-fixed
            /></EuiEmotionProvider>
        </EuiEmotionProvider>
        <EuiEmotionProvider @colorMode="light"><EuiPanel
            data-sibling
          /></EuiEmotionProvider>
      </template>
    );
    const parent = this.element.querySelector('[data-parent]')!;
    const child = this.element.querySelector('[data-child]')!;
    const fixed = this.element.querySelector('[data-fixed]')!;
    const sibling = this.element.querySelector('[data-sibling]')!;
    const original = getComputedStyle(sibling).backgroundColor;
    assert.dom(child).hasStyle({ borderRadius: '19px' });
    state.mode = 'dark';
    state.overrides = { border: { radius: { panel: '27px' } } };
    await rerender();
    assert.strictEqual(
      getComputedStyle(child).backgroundColor,
      getComputedStyle(parent).backgroundColor
    );
    assert.notStrictEqual(getComputedStyle(parent).backgroundColor, original);
    assert.dom(child).hasStyle({ borderRadius: '27px' });
    assert
      .dom(fixed)
      .hasStyle({ borderRadius: '27px', backgroundColor: original });
    assert.strictEqual(getComputedStyle(sibling).backgroundColor, original);
    assert.notStrictEqual(getComputedStyle(sibling).borderRadius, '27px');
  });

  for (const contrast of ['preferred', 'forced'] as const) {
    for (const color of ['plain', 'transparent', 'primary'] as const) {
      test(`${contrast}/${color}: accessible border and shadow suppression`, async function (assert) {
        await render(
          <template>
            <EuiEmotionProvider @highContrastMode={{contrast}}><EuiPanel
                @color={{color}}
                @hasBorder={{false}}
                @hasShadow={{true}}
                data-panel
              /></EuiEmotionProvider>
          </template>
        );
        const panel = this.element.querySelector('[data-panel]')!;
        assert.dom(panel).hasStyle({
          boxShadow: 'none',
          borderTopWidth: color === 'transparent' ? '0px' : '1px'
        });
        if (color !== 'transparent') {
          assert.strictEqual(
            getComputedStyle(panel).borderTopColor,
            rgb(
              euiBorderColor(resolveBorealisTheme('light', {}, contrast), color)
            )
          );
        }
      });
    }
  }
});
