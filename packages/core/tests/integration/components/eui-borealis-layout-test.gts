import { tracked } from '@glimmer/tracking';
import { render, settled, clearRender } from '@ember/test-helpers';
import { setupRenderingTest } from 'ember-qunit';
import { module, test } from 'qunit';
import EuiSpacer from '#src/components/eui-spacer.gts';
import EuiHorizontalRule from '#src/components/eui-horizontal-rule.gts';
import EuiLoadingSpinner from '#src/components/eui-loading-spinner.gts';
import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import { euiLoadingSpinnerStyles } from '#src/utils/eui/styles.generated.ts';
import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';
import type {
  EuiBorealisOverrides,
  EuiBorealisHighContrastMode
} from '#src/utils/eui/theme.ts';
import type { EuiColorMode } from '#src/utils/emotion/theme.ts';

function computed(root: Element, selector: string) {
  return getComputedStyle(root.querySelector(selector)!);
}

module('Integration | Component | Borealis layout', function (hooks) {
  setupRenderingTest(hooks);

  test('all spacer and spinner sizes render real logical dimensions without legacy CSS', async function (assert) {
    const sizes = ['xs', 's', 'm', 'l', 'xl', 'xxl'] as const;
    const spinnerSizes = ['s', 'm', 'l', 'xl', 'xxl'] as const;
    await render(
      <template>
        {{#each sizes as |size|}}<EuiSpacer
            @size={{size}}
            data-spacer={{size}}
          />{{/each}}
        {{#each spinnerSizes as |size|}}<EuiLoadingSpinner
            @size={{size}}
            data-spinner={{size}}
          />{{/each}}
      </template>
    );
    sizes.forEach((size, index) => {
      const style = computed(this.element, `[data-spacer="${size}"]`);
      assert.strictEqual(
        style.blockSize,
        `${[4, 8, 16, 24, 32, 40][index]}px`,
        `spacer ${size}`
      );
      assert.strictEqual(style.flexShrink, '0');
    });
    spinnerSizes.forEach((size, index) => {
      const style = computed(this.element, `[data-spinner="${size}"]`);
      const expected = `${[12, 16, 24, 32, 40][index]}px`;
      assert.strictEqual(style.inlineSize, expected, `spinner ${size} width`);
      assert.strictEqual(style.blockSize, expected, `spinner ${size} height`);
      assert.strictEqual(style.boxSizing, 'border-box');
      assert.strictEqual(style.borderRadius, '50%');
      assert.strictEqual(style.borderTopStyle, 'solid');
      assert.strictEqual(style.borderTopWidth, index < 2 ? '1px' : '2px');
    });
  });

  test('horizontal rule widths, centering, margins and native semantics', async function (assert) {
    const margins = ['none', 'xs', 's', 'm', 'l', 'xl', 'xxl'] as const;
    await render(
      <template>
        <div style="width: 400px" dir="rtl">
          <EuiHorizontalRule data-full />
          <EuiHorizontalRule
            @size="half"
            @margin="none"
            data-half
            aria-label="Section divider"
          />
          <EuiHorizontalRule @size="quarter" data-quarter />
          {{#each margins as |margin|}}<EuiHorizontalRule
              @margin={{margin}}
              data-margin={{margin}}
            />{{/each}}
        </div>
      </template>
    );
    assert.strictEqual(computed(this.element, '[data-full]').width, '400px');
    assert.strictEqual(computed(this.element, '[data-half]').width, '200px');
    assert.strictEqual(computed(this.element, '[data-quarter]').width, '100px');
    assert.strictEqual(
      computed(this.element, '[data-half]').marginInlineStart,
      '100px'
    );
    assert.strictEqual(
      computed(this.element, '[data-half]').marginInlineEnd,
      '100px'
    );
    assert.dom('hr[data-half]').hasAttribute('aria-label', 'Section divider');
    margins.forEach((margin, index) => {
      const style = computed(this.element, `[data-margin="${margin}"]`);
      const expected = `${[0, 8, 12, 16, 24, 32, 40][index]}px`;
      assert.strictEqual(style.marginBlockStart, expected, `${margin} start`);
      assert.strictEqual(style.marginBlockEnd, expected, `${margin} end`);
      assert.strictEqual(style.blockSize, '1px');
    });
  });

  test('live native token overrides, nesting and color modes stay scoped', async function (assert) {
    class State {
      @tracked mode: EuiColorMode = 'light';
      @tracked size: 's' | 'xl' = 's';
      @tracked overrides: EuiBorealisOverrides = {};
    }
    const state = new State();
    await render(
      <template>
        <EuiEmotionProvider
          @colorMode={{state.mode}}
          @borealisOverrides={{state.overrides}}
        >
          <EuiSpacer @size="xs" data-parent-space />
          <EuiHorizontalRule @margin="xs" data-parent-rule />
          <EuiLoadingSpinner @size={{state.size}} data-parent-spinner />
          <EuiEmotionProvider><EuiSpacer
              @size="xs"
              data-nested-space
            /></EuiEmotionProvider>
        </EuiEmotionProvider>
        <EuiEmotionProvider @colorMode="light"><EuiSpacer
            @size="xs"
            data-sibling-space
          /><EuiHorizontalRule data-sibling-rule /></EuiEmotionProvider>
      </template>
    );
    const initialColor = computed(
      this.element,
      '[data-parent-rule]'
    ).backgroundColor;
    const siblingColor = computed(
      this.element,
      '[data-sibling-rule]'
    ).backgroundColor;
    state.mode = 'dark';
    state.size = 'xl';
    state.overrides = {
      size: { xs: '9px', s: '17px' },
      colors: { DARK: { borderStrongPrimary: '#123456' } }
    };
    await settled();
    assert.strictEqual(
      computed(this.element, '[data-parent-space]').blockSize,
      '9px'
    );
    assert.strictEqual(
      computed(this.element, '[data-nested-space]').blockSize,
      '9px'
    );
    assert.strictEqual(
      computed(this.element, '[data-sibling-space]').blockSize,
      '4px'
    );
    assert.strictEqual(
      computed(this.element, '[data-parent-rule]').marginBlockStart,
      '17px'
    );
    assert.notStrictEqual(
      computed(this.element, '[data-parent-rule]').backgroundColor,
      initialColor
    );
    assert.strictEqual(
      computed(this.element, '[data-sibling-rule]').backgroundColor,
      siblingColor
    );
    assert.strictEqual(
      computed(this.element, '[data-parent-spinner]').inlineSize,
      '32px'
    );
    assert.strictEqual(
      computed(this.element, '[data-parent-spinner]').borderTopColor,
      'rgb(18, 52, 86)'
    );
    state.overrides = {};
    state.mode = 'light';
    await settled();
    assert.strictEqual(
      computed(this.element, '[data-parent-space]').blockSize,
      '4px'
    );
    assert.strictEqual(
      computed(this.element, '[data-parent-rule]').backgroundColor,
      initialColor
    );
  });

  test('spinner accessibility, custom color and native attribute forwarding', async function (assert) {
    await render(
      <template>
        <EuiLoadingSpinner data-default />
        <EuiLoadingSpinner
          @color={{hash highlight="#123456" border="#abcdef"}}
          role="status"
          aria-label="Saving"
          class="consumer"
          title="Working"
          data-custom
        />
        <EuiLoadingSpinner aria-hidden="true" data-decorative />
      </template>
    );
    assert
      .dom('[data-default]')
      .hasAttribute('role', 'progressbar')
      .hasAttribute('aria-label', 'Loading');
    assert
      .dom('[data-custom]')
      .hasAttribute('role', 'status')
      .hasAttribute('aria-label', 'Saving')
      .hasAttribute('title', 'Working')
      .hasClass('consumer');
    assert.dom('[data-decorative]').hasAttribute('aria-hidden', 'true');
    assert.strictEqual(
      computed(this.element, '[data-custom]').borderTopColor,
      'rgb(18, 52, 86)'
    );
    assert.strictEqual(
      computed(this.element, '[data-custom]').borderInlineStartColor,
      'rgb(171, 205, 239)'
    );
  });

  test('logical dimensions follow vertical writing direction', async function (assert) {
    await render(
      <template>
        <div style="writing-mode: vertical-rl; height: 400px">
          <EuiSpacer @size="xl" data-space />
          <EuiHorizontalRule @size="half" @margin="none" data-rule />
          <EuiLoadingSpinner @size="xl" data-spinner />
        </div>
      </template>
    );
    assert.strictEqual(computed(this.element, '[data-space]').width, '32px');
    assert.strictEqual(computed(this.element, '[data-rule]').height, '200px');
    assert.strictEqual(computed(this.element, '[data-rule]').width, '1px');
    assert.strictEqual(
      computed(this.element, '[data-spinner]').inlineSize,
      '32px'
    );
  });

  test('contrast modes reactively strengthen spinner borders and use visible rule borders', async function (assert) {
    class State {
      @tracked contrast: EuiBorealisHighContrastMode = false;
    }
    const state = new State();
    await render(
      <template>
        <EuiEmotionProvider @highContrastMode={{state.contrast}}>
          <EuiLoadingSpinner
            @size="s"
            @color={{hash highlight="#123456"}}
            data-spinner
          />
          <EuiHorizontalRule data-rule />
        </EuiEmotionProvider>
      </template>
    );
    assert.strictEqual(
      computed(this.element, '[data-spinner]').borderTopWidth,
      '1px'
    );
    state.contrast = 'preferred';
    await settled();
    assert.strictEqual(
      computed(this.element, '[data-spinner]').borderTopWidth,
      '2px'
    );
    state.contrast = 'forced';
    await settled();
    assert.strictEqual(
      computed(this.element, '[data-rule]').borderBlockEndWidth,
      '1px'
    );
    assert.strictEqual(
      computed(this.element, '[data-rule]').borderBlockEndStyle,
      'solid'
    );
    assert.strictEqual(
      computed(this.element, '[data-spinner]').forcedColorAdjust,
      'none'
    );
    assert.notStrictEqual(
      computed(this.element, '[data-spinner]').borderTopColor,
      'rgb(18, 52, 86)',
      'forced contrast overrides custom color as upstream does'
    );
  });

  test('reduced motion guard and keyframes survive extraction', async function (assert) {
    const allStyles = euiLoadingSpinnerStyles(resolveBorealisTheme('light'));
    const style = allStyles.euiLoadingSpinner;
    assert.true(
      allStyles.s.styles.includes('border-width:1.5px'),
      'fractional upstream border survives serialization; Chromium quantizes its rendered width'
    );
    assert.true(style.styles.includes('prefers-reduced-motion: no-preference'));
    assert.true(style.styles.includes('0.6s infinite linear'));
    await render(<template><EuiLoadingSpinner data-spinner /></template>);
    const spinnerStyle = computed(this.element, '[data-spinner]');
    if (matchMedia('(prefers-reduced-motion: reduce)').matches) {
      assert.strictEqual(spinnerStyle.animationName, 'none');
    } else {
      assert.notStrictEqual(spinnerStyle.animationName, 'none');
      assert.strictEqual(spinnerStyle.animationDuration, '0.6s');
      assert.strictEqual(spinnerStyle.animationIterationCount, 'infinite');
    }
    await clearRender();
    assert.dom('[data-spinner]').doesNotExist();
  });
});
