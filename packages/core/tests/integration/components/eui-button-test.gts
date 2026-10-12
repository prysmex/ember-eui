import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { on } from '@ember/modifier';
import {
  click,
  render,
  settled,
  focus,
  triggerKeyEvent
} from '@ember/test-helpers';

import { tracked } from '@glimmer/tracking';
import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import type { EuiColorMode } from '#src/utils/emotion/theme.ts';
import type { EuiBorealisOverrides } from '#src/utils/eui/theme.ts';

import EuiButton from '#src/components/eui-button.gts';
import EuiButtonEmpty from '#src/components/eui-button-empty.gts';

module('Integration | Component | eui-button', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders a primary button', async function (assert) {
    let clicks = 0;
    const onClick = () => clicks++;

    await render(
      <template>
        <EuiButton {{on "click" onClick}}>Save</EuiButton>
      </template>
    );

    assert
      .dom('button.euiButton')
      .hasAttribute('type', 'button')
      .hasText('Save');
    assert
      .dom('.euiButton .euiButton__content .euiButton__text')
      .hasText('Save');
    await click('button.euiButton');
    assert.strictEqual(clicks, 1);
  });

  test('color, fill, size, full width and selected', async function (assert) {
    await render(
      <template>
        <EuiButton
          @color="danger"
          @fill={{true}}
          @size="s"
          @fullWidth={{true}}
          @isSelected={{true}}
        >Delete</EuiButton>
      </template>
    );

    assert.dom('.euiButton').hasAttribute('aria-pressed', 'true');
    const button = this.element.querySelector('.euiButton')!;
    const style = getComputedStyle(button);
    assert.strictEqual(style.height, '32px');
    assert.strictEqual(style.display, 'block');
    assert.notStrictEqual(style.backgroundColor, 'rgba(0, 0, 0, 0)');
  });

  test('@href renders a link unless disabled or loading', async function (assert) {
    await render(
      <template>
        <EuiButton @href="#go" class="link">Go</EuiButton>
        <EuiButton
          @href="#go"
          @isDisabled={{true}}
          class="disabled"
        >Go</EuiButton>
        <EuiButton @isLoading={{true}} class="loading">Wait</EuiButton>
      </template>
    );

    assert.dom('a.link').hasAttribute('href', '#go');
    assert.dom('button.disabled').isDisabled();
    assert.dom('button.loading').isDisabled();
    assert.dom('button.loading .euiButtonContent__spinner').exists();
  });

  test('@iconType and @iconSide', async function (assert) {
    await render(
      <template>
        <EuiButton @iconType="plus" @iconSide="right">Add</EuiButton>
      </template>
    );

    assert.dom('.euiButtonContent').hasClass('euiButtonContent--iconRight');
    assert.dom('.euiButtonContent svg.euiButtonContent__icon').exists();
  });

  test('native state transitions preserve attributes, events and toggle semantics', async function (assert) {
    class State {
      @tracked disabled = false;
      @tracked loading = false;
      @tracked selected = false;
    }
    const state = new State();
    let clicks = 0;
    const onClick = () => clicks++;
    await render(
      <template>
        <EuiButton
          @href="#go"
          @target="_blank"
          @disabled={{state.disabled}}
          @isLoading={{state.loading}}
          @isSelected={{state.selected}}
          data-native
          class="consumer-class"
          aria-label="Save changes"
          {{on "click" onClick}}
        >Save</EuiButton>
      </template>
    );
    assert
      .dom('a[data-native]')
      .hasAttribute('target', '_blank')
      .hasClass('consumer-class')
      .hasAttribute('aria-label', 'Save changes')
      .hasAttribute('aria-pressed', 'false');
    state.disabled = true;
    await settled();
    assert
      .dom('button[data-native]')
      .isDisabled()
      .doesNotHaveAttribute('href')
      .hasAttribute('type', 'button');
    // Browser-native click() must not dispatch on a disabled native button.
    (this.element.querySelector('[data-native]') as HTMLButtonElement).click();
    assert.strictEqual(clicks, 0);
    state.disabled = false;
    state.loading = true;
    await settled();
    assert.dom('[data-native]').isDisabled().hasAttribute('aria-busy', 'true');
    assert.dom('[data-native] .euiButtonContent__spinner').exists();
    state.loading = false;
    state.selected = true;
    await settled();
    assert
      .dom('a[data-native]')
      .hasAttribute('aria-pressed', 'true')
      .doesNotHaveAttribute('aria-busy');
    await click('[data-native]');
    assert.strictEqual(clicks, 1, 'modifier survives element replacement');
  });

  test('all supported colors, sizes and fill states are styled without legacy CSS', async function (assert) {
    const colors = [
      'primary',
      'accent',
      'accentSecondary',
      'success',
      'warning',
      'danger',
      'text',
      'ghost'
    ];
    const sizes = ['s', 'm'];
    const fills = [false, true];
    await render(
      <template>
        {{#each colors as |color|}}{{#each sizes as |size|}}{{#each
              fills
              as |fill|
            }}
              <EuiButton
                @color={{color}}
                @size={{size}}
                @fill={{fill}}
                data-color={{color}}
                data-size={{size}}
                data-fill={{fill}}
              >Action</EuiButton>
            {{/each}}{{/each}}{{/each}}
      </template>
    );
    const buttons = this.element.querySelectorAll<HTMLButtonElement>('button');
    assert.strictEqual(buttons.length, 32);
    for (const button of buttons) {
      const style = getComputedStyle(button);
      const label = `${button.dataset.color}/${button.dataset.size}/${button.dataset.fill}`;
      assert.strictEqual(
        style.height,
        button.dataset.size === 's' ? '32px' : '40px',
        `${label} height`
      );
      assert.strictEqual(style.boxSizing, 'border-box', `${label} sizing`);
      assert.notStrictEqual(
        style.backgroundColor,
        'rgba(0, 0, 0, 0)',
        `${label} semantic background`
      );
      assert.notStrictEqual(
        style.color,
        style.backgroundColor,
        `${label} readable label`
      );
      assert.strictEqual(
        style.borderRadius,
        '8px',
        `${label} Borealis control radius`
      );
      assert.strictEqual(
        style.textDecorationLine,
        'none',
        `${label} decoration`
      );
    }
  });

  test('link, label, submit, full width and scoped icon/content styling', async function (assert) {
    await render(
      <template>
        <div style="width: 280px">
          <EuiButton
            @type="submit"
            @fullWidth={{true}}
            data-submit
          >Save</EuiButton>
          <EuiButton @element="label" for="upload" data-label>Upload</EuiButton>
          <EuiButton @href="#docs" data-link>Docs</EuiButton>
          <EuiButton
            @iconType="plus"
            @iconSide="right"
            @iconSize="s"
            @iconClasses="custom-icon"
            @contentClasses="custom-content"
            @textClasses="custom-text"
            data-icon
          >Add</EuiButton>
        </div>
      </template>
    );
    assert.dom('[data-submit]').hasAttribute('type', 'submit');
    assert.strictEqual(
      getComputedStyle(this.element.querySelector('[data-submit]')!).width,
      '280px'
    );
    assert
      .dom('label[data-label]')
      .hasAttribute('for', 'upload')
      .doesNotHaveAttribute('type');
    assert.dom('a[data-link]').doesNotHaveAttribute('type');
    assert.dom('[data-icon] .custom-content').exists();
    assert.dom('[data-icon] .custom-text').hasText('Add');
    const content = this.element.querySelector('[data-icon] .custom-content')!;
    const icon = this.element.querySelector('[data-icon] .custom-icon')!;
    assert.strictEqual(getComputedStyle(content).display, 'flex');
    assert.strictEqual(getComputedStyle(content).flexDirection, 'row-reverse');
    assert.strictEqual(getComputedStyle(icon).width, '12px');
    assert.strictEqual(getComputedStyle(icon).height, '12px');
  });

  test('nearest-provider themes update existing buttons and isolate nested overrides', async function (assert) {
    class State {
      @tracked mode: EuiColorMode = 'light';
      @tracked overrides: EuiBorealisOverrides = {};
    }
    const state = new State();
    const own = { border: { radius: { control: '13px' } } };
    await render(
      <template>
        <EuiEmotionProvider
          @colorMode={{state.mode}}
          @borealisOverrides={{state.overrides}}
        >
          <EuiButton @fill={{true}} data-parent>Parent</EuiButton>
          <EuiEmotionProvider @borealisOverrides={{own}}>
            <EuiButton @fill={{true}} data-child>Child</EuiButton>
          </EuiEmotionProvider>
          <EuiEmotionProvider @colorMode="light"><EuiButton
              @fill={{true}}
              data-fixed
            >Fixed light</EuiButton></EuiEmotionProvider>
        </EuiEmotionProvider>
        <EuiEmotionProvider @colorMode="light"><EuiButton
            @fill={{true}}
            data-sibling
          >Sibling</EuiButton></EuiEmotionProvider>
      </template>
    );
    const parent = this.element.querySelector('[data-parent]')!;
    const child = this.element.querySelector('[data-child]')!;
    const fixed = this.element.querySelector('[data-fixed]')!;
    const sibling = this.element.querySelector('[data-sibling]')!;
    const initial = getComputedStyle(parent).backgroundColor;
    assert.strictEqual(getComputedStyle(child).borderRadius, '13px');
    state.mode = 'dark';
    await settled();
    assert.strictEqual(
      this.element.querySelector('[data-parent]'),
      parent,
      'updates existing DOM'
    );
    assert.notStrictEqual(getComputedStyle(parent).backgroundColor, initial);
    assert.strictEqual(
      getComputedStyle(child).backgroundColor,
      getComputedStyle(parent).backgroundColor,
      'nested child inherits mode'
    );
    assert.strictEqual(
      getComputedStyle(fixed).backgroundColor,
      initial,
      'fixed light branch stays light'
    );
    assert.strictEqual(
      getComputedStyle(sibling).backgroundColor,
      initial,
      'sibling outside provider isolated'
    );
    state.overrides = { border: { radius: { control: '10px' } } };
    await settled();
    assert.strictEqual(getComputedStyle(parent).borderRadius, '10px');
    assert.strictEqual(
      getComputedStyle(child).borderRadius,
      '13px',
      'child override wins'
    );
    assert.strictEqual(
      getComputedStyle(fixed).borderRadius,
      '10px',
      'mode override still inherits tokens'
    );
    assert.strictEqual(
      getComputedStyle(sibling).borderRadius,
      '8px',
      'sibling tokens isolated'
    );
  });

  test('native focus and keyboard modifiers remain usable with upstream scoped focus styles', async function (assert) {
    let keys = 0;
    const onKey = () => keys++;
    await render(
      <template>
        <EuiButton data-focus {{on "keydown" onKey}}>Focus</EuiButton>
      </template>
    );
    await focus('[data-focus]');
    assert.dom('[data-focus]').isFocused();
    await triggerKeyEvent('[data-focus]', 'keydown', 'Enter');
    assert.strictEqual(keys, 1);
    const button = this.element.querySelector('[data-focus]')!;
    assert.strictEqual(
      getComputedStyle(button).outlineStyle,
      button.matches(':focus-visible') ? 'auto' : 'none',
      'upstream focus ring respects browser keyboard modality'
    );
    assert.strictEqual(
      getComputedStyle(button).transitionDuration,
      '0s',
      'Borealis button has no movement animation'
    );
  });

  test('high contrast tokens, disabled fill and RTL icon placement remain scoped', async function (assert) {
    await render(
      <template>
        <EuiEmotionProvider @highContrastMode="preferred">
          <EuiButton @fill={{true}} data-contrast>Contrast</EuiButton>
          <EuiButton
            @fill={{true}}
            @isDisabled={{true}}
            data-disabled
          >Disabled</EuiButton>
        </EuiEmotionProvider>
        <div dir="rtl">
          <EuiButton @iconType="plus" data-rtl-left>Add</EuiButton>
          <EuiButton
            @iconType="plus"
            @iconSide="right"
            data-rtl-right
          >Add</EuiButton>
        </div>
      </template>
    );
    const contrast = getComputedStyle(
      this.element.querySelector('[data-contrast]')!
    );
    assert.strictEqual(
      contrast.borderTopWidth,
      '1px',
      'high contrast uses a visible border'
    );
    assert.strictEqual(contrast.borderTopStyle, 'solid');
    const disabled = getComputedStyle(
      this.element.querySelector('[data-disabled]')!
    );
    assert.notStrictEqual(
      disabled.backgroundColor,
      contrast.backgroundColor,
      'disabled semantic color instead of active color'
    );
    assert.strictEqual(disabled.cursor, 'not-allowed');
    assert.strictEqual(
      disabled.opacity,
      '1',
      'native disabled contrast keeps full opacity'
    );
    const leftIcon = this.element
      .querySelector('[data-rtl-left] .euiButtonContent__icon')!
      .getBoundingClientRect();
    const leftText = this.element
      .querySelector('[data-rtl-left] .euiButton__text')!
      .getBoundingClientRect();
    const rightIcon = this.element
      .querySelector('[data-rtl-right] .euiButtonContent__icon')!
      .getBoundingClientRect();
    const rightText = this.element
      .querySelector('[data-rtl-right] .euiButton__text')!
      .getBoundingClientRect();
    assert.ok(
      leftIcon.left >= leftText.right,
      'start icon follows RTL direction'
    );
    assert.ok(
      rightIcon.right <= rightText.left,
      'end icon follows RTL direction'
    );
  });

  test('EuiButtonEmpty: color, size, flush, link and disabled', async function (assert) {
    let clicks = 0;
    const onClick = () => clicks++;

    await render(
      <template>
        <EuiButtonEmpty
          @color="danger"
          @size="xs"
          @flush="left"
          class="empty"
          {{on "click" onClick}}
        >Remove</EuiButtonEmpty>
        <EuiButtonEmpty @href="#docs" class="link">Docs</EuiButtonEmpty>
        <EuiButtonEmpty
          @isDisabled={{true}}
          class="disabled"
        >Nope</EuiButtonEmpty>
      </template>
    );

    assert
      .dom('button.empty')
      .hasClass('euiButtonEmpty--danger')
      .hasClass('euiButtonEmpty--xSmall')
      .hasClass('euiButtonEmpty--flushLeft');
    await click('button.empty');
    assert.strictEqual(clicks, 1);
    assert.dom('a.link').hasAttribute('href', '#docs');
    assert
      .dom('button.disabled')
      .isDisabled()
      .hasClass('euiButtonEmpty-isDisabled');
    assert
      .dom('button.empty')
      .doesNotHaveAttribute('aria-pressed', 'not a toggle without @isSelected');
  });

  test('EuiButtonEmpty @isSelected sets aria-pressed to "true"/"false"', async function (assert) {
    await render(
      <template>
        <EuiButtonEmpty @isSelected={{true}} class="on">On</EuiButtonEmpty>
        <EuiButtonEmpty @isSelected={{false}} class="off">Off</EuiButtonEmpty>
      </template>
    );

    assert.dom('.on').hasAttribute('aria-pressed', 'true');
    assert.dom('.off').hasAttribute('aria-pressed', 'false');
  });
});
