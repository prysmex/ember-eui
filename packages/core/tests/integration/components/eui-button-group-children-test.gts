import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { on } from '@ember/modifier';
import { click, focus, render, settled } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import EuiButton from '#src/components/eui-button.gts';
import EuiButtonGroup from '#src/components/eui-button-group.gts';
import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import EuiToolTip from '#src/components/eui-tool-tip.gts';
import { euiButtonSizeMap } from '#src/utils/eui/styles.generated.ts';
import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';

import type { EuiColorMode } from '#src/utils/emotion/theme.ts';

const lightContext = resolveBorealisTheme('light');
const light = lightContext.euiTheme;
const dark = resolveBorealisTheme('dark').euiTheme;
const sizeMap = euiButtonSizeMap(lightContext) as unknown as Record<
  's' | 'm',
  { height: string }
>;
const TRANSPARENT = 'rgba(0, 0, 0, 0)';

/** Normalize any CSS color to the browser's computed `rgb()` form. */
function rgb(color: string) {
  const probe = document.createElement('span');
  probe.style.color = color;
  document.body.appendChild(probe);
  const value = getComputedStyle(probe).color;
  probe.remove();
  return value;
}

function el<T extends HTMLElement = HTMLElement>(selector: string): T {
  const element = document.querySelector<T>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

function style(selector: string, pseudo?: string) {
  return getComputedStyle(el(selector), pseudo);
}

/** Height in CSS pixels (the ember-qunit container is scaled). */
function height(selector: string) {
  const container = el('#ember-testing');
  const scale = container.getBoundingClientRect().width / container.offsetWidth;
  return Math.round((el(selector).getBoundingClientRect().height / scale) * 100) / 100;
}

/** Root font size: tests without a provider keep the browser's 16px root. */
const px = (value: string) =>
  value.endsWith('rem')
    ? parseFloat(value) * parseFloat(getComputedStyle(document.documentElement).fontSize)
    : parseFloat(value);

class State {
  @tracked buttonSize: 's' | 'm' = 's';
  @tracked isDisabled = false;
  @tracked hasAriaDisabled = false;
  @tracked isFullWidth = false;
  @tracked gutterSize: 'none' | 'xs' | 's' | 'm' | 'l' | 'xl' = 's';
  @tracked showDividers = false;
  @tracked wrap = true;
  @tracked layout: 'horizontal' | 'vertical' = 'horizontal';
  @tracked display: 'regular' | 'highlighted' | 'inverse' = 'regular';
  @tracked idSelected = 'edit';
  @tracked idToSelectedMap: Record<string, boolean> = { edit: true };
  @tracked mode: EuiColorMode = 'light';
  changes: string[] = [];
  clicks: string[] = [];

  onChange = (id: string) => {
    this.changes.push(id);
    this.idSelected = id;
  };
  onChangeMulti = (id: string) => {
    this.changes.push(id);
    this.idToSelectedMap = { ...this.idToSelectedMap, [id]: !this.idToSelectedMap[id] };
  };
  onClick = (event: Event) => {
    this.clicks.push((event.currentTarget as HTMLElement).textContent!.trim());
  };
}

module('Integration | Component | eui-button-group (children API)', function (hooks) {
  setupRenderingTest(hooks);

  test('a block renders a labelled role="group" and yields wired buttons', async function (assert) {
    const state = new State();

    await render(
      <template>
        <EuiButtonGroup @legend="Document actions" class="custom" data-test-group as |group|>
          <group.Button @fill={{true}} {{on "click" state.onClick}}>Save</group.Button>
          <group.Button @color="text" @iconType="undo">Undo</group.Button>
          <group.ButtonEmpty @color="text">Cancel</group.ButtonEmpty>
          <EuiToolTip @content="Delete">
            <group.ButtonIcon @iconType="trash" @color="danger" aria-label="Delete" />
          </EuiToolTip>
        </EuiButtonGroup>
        <EuiButton @size="s" data-standalone-s>Standalone</EuiButton>
      </template>
    );

    assert.dom('fieldset').doesNotExist('no fieldset without @options');
    assert.dom('[data-test-group]').hasTagName('div');
    assert.dom('[data-test-group]').hasClass('euiButtonGroup').hasClass('custom');
    assert.dom('[data-test-group]').hasAttribute('role', 'group');
    assert.dom('[data-test-group]').hasAttribute('aria-label', 'Document actions');
    assert.dom('[data-test-group]').hasAttribute('data-variant', 'default');
    assert.dom('[data-test-group]').hasAttribute('data-size', 's');
    assert.dom('[data-test-group]').doesNotHaveAttribute('data-layout');
    assert.dom('[data-test-group]').doesNotHaveAttribute('data-display');
    assert.dom('[data-test-group]').doesNotHaveAttribute('aria-disabled');
    assert.dom('[data-test-group] > .euiButtonGroup__container > .euiButtonGroup__buttons').exists();
    assert.dom('.euiButtonGroup__buttons > .euiButton').exists({ count: 2 });
    assert.dom('.euiButtonGroup__buttons > .euiButtonEmpty').exists();
    assert.dom('.euiButtonGroup__buttons > .euiToolTipAnchor .euiButtonIcon').exists();
    assert.dom('.euiButtonGroup__item').doesNotExist('default variant does not wrap the buttons');

    // Default variant: a wrapping row with a `s` gutter.
    const buttons = style('.euiButtonGroup__buttons');
    assert.strictEqual(buttons.display, 'flex');
    assert.strictEqual(buttons.flexWrap, 'wrap');
    assert.strictEqual(px(buttons.columnGap), px(light.size.s));
    assert.strictEqual(style('.euiButtonGroup__container').backgroundColor, TRANSPARENT, 'no inset container');

    // The group's buttonSize ('s') wins over EuiButton's default 'm'.
    assert.strictEqual(height('.euiButton'), height('[data-standalone-s]'));
    assert.strictEqual(height('.euiButtonIcon'), height('[data-standalone-s]'), 'icon button is s too');

    // Own args still apply (fill, colors, block content, attributes, modifiers).
    assert.strictEqual(
      style('.euiButtonGroup__buttons > .euiButton').backgroundColor,
      rgb(light.components.buttons.backgroundFilledPrimary)
    );
    assert.strictEqual(style('.euiButtonIcon').color, rgb(light.components.buttons.textColorDanger));
    await click('.euiButton');
    assert.deepEqual(state.clicks, ['Save']);
  });

  test('buttonSize, isDisabled, hasAriaDisabled and isFullWidth are passed down reactively', async function (assert) {
    const state = new State();

    await render(
      <template>
        <div style="width: 600px">
          <EuiButtonGroup
            @legend="Actions"
            @buttonSize={{state.buttonSize}}
            @isDisabled={{state.isDisabled}}
            @hasAriaDisabled={{state.hasAriaDisabled}}
            @isFullWidth={{state.isFullWidth}}
            as |group|
          >
            <group.Button data-one {{on "click" state.onClick}}>One</group.Button>
            <group.ButtonEmpty data-two {{on "click" state.onClick}}>Two</group.ButtonEmpty>
            <group.Button @isDisabled={{true}} data-three>Three</group.Button>
            <group.ButtonIcon @iconType="trash" aria-label="Delete" data-four />
          </EuiButtonGroup>
        </div>
        <EuiButton @size="m" data-standalone-m>Standalone</EuiButton>
      </template>
    );

    const one = el('[data-one]');
    assert.dom('[data-three]').isDisabled('a child disabled on its own stays disabled');
    assert.dom(one).isNotDisabled();

    state.buttonSize = 'm';
    await settled();
    assert.strictEqual(el('[data-one]'), one, 'buttons are not re-rendered');
    assert.dom('.euiButtonGroup').hasAttribute('data-size', 'm');
    assert.strictEqual(height('[data-one]'), height('[data-standalone-m]'));
    assert.strictEqual(height('[data-one]'), px(sizeMap.m.height));

    state.isDisabled = true;
    await settled();
    assert.dom('.euiButtonGroup').hasAttribute('aria-disabled', 'true');
    assert.dom('.euiButtonGroup').hasClass('euiButtonGroup-isDisabled');
    for (const selector of ['[data-one]', '[data-two]', '[data-three]', '[data-four]']) {
      assert.dom(selector).isDisabled(`${selector} disabled`);
    }

    state.hasAriaDisabled = true;
    await settled();
    for (const selector of ['[data-one]', '[data-two]', '[data-four]']) {
      assert.dom(selector).hasAttribute('aria-disabled', 'true');
      assert.dom(selector).doesNotHaveAttribute('disabled');
    }
    await click('[data-one]');
    await click('[data-two]');
    assert.deepEqual(state.clicks, [], 'clicks are blocked');
    await focus('[data-two]');
    assert.strictEqual(document.activeElement, el('[data-two]'), 'still focusable');

    state.isDisabled = false;
    state.hasAriaDisabled = false;
    state.isFullWidth = true;
    await settled();
    assert.dom('[data-three]').isDisabled('the group never enables a disabled child');
    assert.strictEqual(style('.euiButtonGroup').display, 'block');
    assert.strictEqual(style('.euiButtonGroup__container').width, '600px');
    assert.strictEqual(style('[data-one]').flexGrow, '1', 'EuiButton children grow');
    assert.strictEqual(style('[data-two]').flexShrink, '0', 'EuiButtonEmpty does not shrink');
  });

  test('@gutterSize sets the gap of the default variant', async function (assert) {
    const state = new State();

    await render(
      <template>
        <EuiButtonGroup @legend="Actions" @gutterSize={{state.gutterSize}} as |group|>
          <group.Button>One</group.Button>
          <group.Button>Two</group.Button>
        </EuiButtonGroup>
      </template>
    );

    const expected = { xs: light.size.xs, s: light.size.s, m: light.size.base, l: light.size.l, xl: light.size.xl };
    for (const size of ['xs', 's', 'm', 'l', 'xl'] as const) {
      state.gutterSize = size;
      await settled();
      assert.strictEqual(px(style('.euiButtonGroup__buttons').columnGap), px(expected[size]), `gutter ${size}`);
    }
    state.gutterSize = 'none';
    await settled();
    assert.strictEqual(style('.euiButtonGroup__buttons').columnGap, 'normal', 'none removes the gap');
  });

  test('variant="segmented": inset items, dividers, wrap and vertical layout', async function (assert) {
    const state = new State();

    await render(
      <template>
        <div style="width: 200px">
          <EuiButtonGroup
            @legend="Document actions"
            @variant="segmented"
            @buttonSize={{state.buttonSize}}
            @showDividers={{state.showDividers}}
            @wrap={{state.wrap}}
            @gutterSize="xl"
            data-text
            as |group|
          >
            <group.Button @color="danger" @fill={{true}}>Delete</group.Button>
            <group.Button>Rename</group.Button>
            <group.Button>Duplicate</group.Button>
          </EuiButtonGroup>
        </div>
        <EuiButtonGroup @legend="Icon actions" @variant="segmented" @layout={{state.layout}} @showDividers={{state.showDividers}} data-icons as |group|>
          <EuiToolTip @content="Delete">
            <group.ButtonIcon @iconType="trash" aria-label="Delete" />
          </EuiToolTip>
          <group.ButtonIcon @iconType="pencil" aria-label="Rename" />
        </EuiButtonGroup>
      </template>
    );

    assert.dom('[data-text]').hasAttribute('data-variant', 'segmented');
    assert.dom('[data-text]').hasAttribute('data-layout', 'horizontal');
    assert.dom('[data-text]').doesNotHaveAttribute('data-dividers');
    assert.dom('[data-text] .euiButtonGroup__buttons > .euiButtonGroup__item > .euiButton').exists({ count: 3 });
    assert.dom('[data-icons] .euiButtonGroup__item .euiButtonIcon').exists({ count: 2 });

    // Inset container with a faux border; buttons are `text`, `base`, borderless.
    const container = style('[data-text] .euiButtonGroup__container');
    assert.strictEqual(container.backgroundColor, rgb(light.colors.backgroundBasePlain));
    assert.strictEqual(px(container.borderTopLeftRadius), px((light.border.radius as unknown as Record<string, string>)['control']!));
    assert.strictEqual(
      style('[data-text] .euiButtonGroup__container', '::after').borderTopColor,
      rgb(light.colors.borderBasePlain)
    );
    assert.strictEqual(px(style('[data-text] .euiButtonGroup__buttons').columnGap), px(light.size.xs), 'gutterSize does not apply');
    const first = style('[data-text] .euiButton');
    assert.strictEqual(first.color, rgb(light.components.buttons.textColorText), 'color is forced to text');
    assert.strictEqual(first.borderTopStyle, 'none');
    // `inline-flex` upstream, blockified to `flex` as a flex item.
    assert.strictEqual(style('[data-text] .euiButtonGroup__item').display, 'flex');
    assert.true(
      height('[data-text] .euiButton') < px(sizeMap.s.height),
      'buttons are inset (smaller than the s height)'
    );

    // Wraps by default within 200px; `@wrap={{false}}` keeps one row.
    assert.strictEqual(style('[data-text] .euiButtonGroup__buttons').flexWrap, 'wrap');
    state.wrap = false;
    await settled();
    assert.strictEqual(style('[data-text] .euiButtonGroup__buttons').flexWrap, 'nowrap');

    state.showDividers = true;
    await settled();
    assert.dom('[data-text]').hasAttribute('data-dividers', 'true');
    assert.strictEqual(
      style('[data-text] .euiButtonGroup__item', '::after').borderInlineStartColor,
      rgb(light.colors.borderBasePlain),
      'divider line'
    );
    assert.strictEqual(
      px(style('[data-text] .euiButtonGroup__buttons').columnGap),
      px(light.size.xs) + px(light.border.width.thin),
      'gap makes room for the dividers'
    );

    // Vertical layout stacks icon buttons.
    assert.strictEqual(style('[data-icons] .euiButtonGroup__buttons').flexDirection, 'row');
    state.layout = 'vertical';
    await settled();
    assert.dom('[data-icons]').hasAttribute('data-layout', 'vertical');
    assert.strictEqual(style('[data-icons] .euiButtonGroup__buttons').flexDirection, 'column');
    const [a, b] = Array.from(document.querySelectorAll('[data-icons] .euiButtonIcon')).map((e) => e.getBoundingClientRect());
    assert.true(b!.top >= a!.bottom, 'second icon is below the first');
  });

  test('variant="selection": single and multi selection with aria-pressed', async function (assert) {
    const state = new State();

    await render(
      <template>
        <EuiButtonGroup
          @legend="Single"
          @variant="selection"
          @idSelected={{state.idSelected}}
          @onChange={{state.onChange}}
          data-single
          as |group|
        >
          <group.Button @id="save" {{on "click" state.onClick}}>Save</group.Button>
          <group.Button @id="edit">Edit</group.Button>
          <EuiToolTip @content="Delete">
            <group.ButtonIcon @id="delete" @iconType="trash" aria-label="Delete" />
          </EuiToolTip>
        </EuiButtonGroup>
        <EuiButtonGroup
          @legend="Multi"
          @variant="selection"
          @type="multi"
          @idToSelectedMap={{state.idToSelectedMap}}
          @onChange={{state.onChangeMulti}}
          data-multi
          as |group|
        >
          <group.Button @id="save">Save</group.Button>
          <group.Button @id="edit">Edit</group.Button>
          <group.Button @id="delete">Delete</group.Button>
        </EuiButtonGroup>
      </template>
    );

    assert.dom('[data-single]').hasAttribute('data-variant', 'selection');
    assert.dom('[data-single]').hasAttribute('data-display', 'regular');
    assert.dom('[data-single] #save').hasAttribute('aria-pressed', 'false');
    assert.dom('[data-single] #edit').hasAttribute('aria-pressed', 'true');
    assert.dom('[data-single] #delete').hasAttribute('aria-pressed', 'false');

    await click('[data-single] #save');
    assert.deepEqual(state.changes, ['save'], 'onChange gets the id');
    assert.deepEqual(state.clicks, ['Save'], "the button's own click handler still runs");
    assert.dom('[data-single] #save').hasAttribute('aria-pressed', 'true');
    assert.dom('[data-single] #edit').hasAttribute('aria-pressed', 'false');

    await click('[data-single] #delete');
    assert.dom('[data-single] #delete').hasAttribute('aria-pressed', 'true', 'icon buttons take part');

    assert.dom('[data-multi] #edit').hasAttribute('aria-pressed', 'true');
    await click('[data-multi] #save');
    assert.dom('[data-multi] #save').hasAttribute('aria-pressed', 'true');
    assert.dom('[data-multi] #edit').hasAttribute('aria-pressed', 'true', 'several can be selected');
    await click('[data-multi] #edit');
    assert.dom('[data-multi] #edit').hasAttribute('aria-pressed', 'false');
    assert.deepEqual(state.changes, ['save', 'delete', 'save', 'edit']);
  });

  test('variant="selection" display: regular, highlighted and inverse', async function (assert) {
    const state = new State();

    await render(
      <template>
        <EuiButtonGroup
          @legend="View"
          @variant="selection"
          @display={{state.display}}
          @idSelected={{state.idSelected}}
          @onChange={{state.onChange}}
          as |group|
        >
          <group.Button @id="save">Save</group.Button>
          <group.Button @id="edit">Edit</group.Button>
          <group.Button @id="off" @isDisabled={{true}}>Off</group.Button>
        </EuiButtonGroup>
      </template>
    );

    const colors = light.colors;
    const buttons = light.components.buttons;

    // regular: subdued selected background, transparent others.
    assert.strictEqual(style('#edit').backgroundColor, rgb(colors.backgroundLightText));
    assert.strictEqual(style('#save').backgroundColor, TRANSPARENT);
    assert.strictEqual(style('#off').backgroundColor, TRANSPARENT, 'disabled unselected is transparent');
    assert.strictEqual(style('.euiButtonGroup__container').backgroundColor, rgb(colors.backgroundBasePlain));

    // highlighted: selected button is filled.
    state.display = 'highlighted';
    await settled();
    assert.strictEqual(style('#edit').backgroundColor, rgb(buttons.backgroundFilledText));
    assert.strictEqual(style('#edit').color, rgb(buttons.textColorFilledText));
    assert.strictEqual(style('#save').backgroundColor, TRANSPARENT);

    // inverse: subdued container, light selected button with a shadow.
    state.display = 'inverse';
    await settled();
    assert.dom('.euiButtonGroup').hasAttribute('data-display', 'inverse');
    assert.strictEqual(style('.euiButtonGroup__container').backgroundColor, rgb(colors.backgroundBaseSubdued));
    assert.strictEqual(style('#edit').backgroundColor, rgb(buttons.backgroundText), 'base (light) toggle');
    assert.notStrictEqual(style('#edit').boxShadow, 'none', 'selected button has a shadow');
    assert.strictEqual(style('#save').backgroundColor, TRANSPARENT);
  });

  test('selection: a disabled selected button stays visibly selected; aria-disabled blocks selection', async function (assert) {
    const state = new State();

    await render(
      <template>
        <EuiButtonGroup
          @legend="View"
          @variant="selection"
          @isDisabled={{true}}
          @hasAriaDisabled={{true}}
          @idSelected={{state.idSelected}}
          @onChange={{state.onChange}}
          as |group|
        >
          <group.Button @id="save">Save</group.Button>
          <group.Button @id="edit">Edit</group.Button>
        </EuiButtonGroup>
      </template>
    );

    assert.dom('#edit').hasAttribute('aria-disabled', 'true');
    assert.dom('#edit').hasAttribute('aria-pressed', 'true');
    assert.strictEqual(
      style('#edit').backgroundColor,
      rgb(light.components.buttons.backgroundFilledDisabled),
      'disabled + selected renders the filled disabled state'
    );
    await click('#save');
    assert.deepEqual(state.changes, [], 'selection is blocked');
  });

  test('dark mode and sibling providers', async function (assert) {
    const state = new State();
    state.mode = 'dark';

    await render(
      <template>
        <EuiEmotionProvider @colorMode={{state.mode}}>
          <EuiButtonGroup @legend="A" @variant="segmented" data-a as |group|>
            <group.Button>One</group.Button>
          </EuiButtonGroup>
        </EuiEmotionProvider>
        <EuiEmotionProvider @colorMode="light">
          <EuiButtonGroup @legend="B" @variant="segmented" data-b as |group|>
            <group.Button>One</group.Button>
          </EuiButtonGroup>
        </EuiEmotionProvider>
      </template>
    );

    assert.strictEqual(style('[data-a] .euiButtonGroup__container').backgroundColor, rgb(dark.colors.backgroundBasePlain));
    assert.strictEqual(style('[data-a] .euiButton').color, rgb(dark.components.buttons.textColorText));
    assert.strictEqual(style('[data-b] .euiButtonGroup__container').backgroundColor, rgb(light.colors.backgroundBasePlain));

    state.mode = 'light';
    await settled();
    assert.strictEqual(style('[data-a] .euiButtonGroup__container').backgroundColor, rgb(light.colors.backgroundBasePlain));
  });

  test('the options API is used whenever @options is passed', async function (assert) {
    const options = [{ id: 'a', label: 'Alpha' }];

    await render(
      <template>
        <EuiButtonGroup @legend="Options" @options={{options}} @idSelected="a" @variant="segmented">
          <span data-ignored>ignored</span>
        </EuiButtonGroup>
      </template>
    );

    assert.dom('fieldset.euiButtonGroup').exists();
    assert.dom('fieldset').doesNotHaveAttribute('data-variant');
    assert.dom('[data-ignored]').doesNotExist();
  });
});
