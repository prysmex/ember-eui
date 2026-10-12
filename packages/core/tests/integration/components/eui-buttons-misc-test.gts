import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { on } from '@ember/modifier';
import { click, focus, render, settled } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import EuiButtonContent from '#src/components/eui-button-content.gts';
import EuiButtonGroup from '#src/components/eui-button-group.gts';
import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import EuiFacetButton from '#src/components/eui-facet-button.gts';
import EuiFacetGroup from '#src/components/eui-facet-group.gts';
import EuiFilterButton from '#src/components/eui-filter-button.gts';
import EuiFilterGroup from '#src/components/eui-filter-group.gts';
import EuiFilterSelectItem from '#src/components/eui-filter-select-item.gts';
import EuiIcon from '#src/components/eui-icon.gts';
import { euiBadgeColors } from '#src/utils/eui/styles.generated.ts';
import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';

import type { EuiColorMode } from '#src/utils/emotion/theme.ts';
import type { EuiBorealisOverrides } from '#src/utils/eui/theme.ts';

const lightContext = resolveBorealisTheme('light');
const light = lightContext.euiTheme;
const dark = resolveBorealisTheme('dark').euiTheme;
const TRANSPARENT = 'rgba(0, 0, 0, 0)';

type Tokens = Record<string, string>;
const buttons = (theme: typeof light) =>
  theme.components.buttons as unknown as Tokens;
const badges = euiBadgeColors(lightContext) as Record<
  string,
  { backgroundColor: string }
>;

/** Normalize any CSS color to the browser's computed `rgb()` form. */
function rgb(color: string) {
  const probe = document.createElement('span');
  probe.style.color = color;
  document.body.appendChild(probe);
  const value = getComputedStyle(probe).color;
  probe.remove();
  return value;
}

function el<T extends Element = HTMLElement>(selector: string): T {
  const element = document.querySelector<T>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

function style(selector: string, pseudo?: string) {
  return getComputedStyle(el(selector), pseudo);
}

/** Measured box in CSS pixels (the ember-qunit container is scaled). */
function box(selector: string) {
  const container = el('#ember-testing');
  const scale = container.getBoundingClientRect().width / container.offsetWidth;
  const rect = el(selector).getBoundingClientRect();
  const round = (value: number) => Math.round((value / scale) * 100) / 100;
  return {
    width: round(rect.width),
    height: round(rect.height),
    left: round(rect.left),
    right: round(rect.right),
    top: round(rect.top)
  };
}

const OPTIONS = [
  { id: 'left', label: 'Left', value: 'l' },
  { id: 'center', label: 'Center', value: 'c' },
  { id: 'right', label: 'Right', value: 'r' }
];

const ICONS = [
  { id: 'bold', label: 'Bold', iconType: 'editorBold' },
  { id: 'italic', label: 'Italic', iconType: 'editorItalic' }
];

const SELECTED_ICONS = { bold: true };

module('Integration | Component | Borealis buttons misc', function (hooks) {
  setupRenderingTest(hooks);

  module('EuiButtonGroup', function () {
    test('single selection keeps radio semantics with a styled label per option', async function (assert) {
      class State {
        @tracked idSelected = 'left';
        calls: unknown[][] = [];
        onChange = (id: string, value?: string) => {
          this.calls.push([id, value]);
          this.idSelected = id;
        };
      }
      const state = new State();
      await render(
        <template>
          <EuiButtonGroup
            @legend="Alignment"
            @name="align"
            @options={{OPTIONS}}
            @idSelected={{state.idSelected}}
            @onChange={{state.onChange}}
          />
        </template>
      );

      const legend = el('fieldset.euiButtonGroup > legend');
      assert.dom(legend).hasText('Alignment');
      assert.strictEqual(
        getComputedStyle(legend).position,
        'absolute',
        'legend is visually hidden'
      );
      assert.dom('label.euiButtonGroupButton').exists({ count: 3 });
      assert.dom('input[type="radio"][name="align"]').exists({ count: 3 });
      document
        .querySelectorAll<HTMLLabelElement>('label.euiButtonGroupButton')
        .forEach((label) => {
          const input = label.querySelector('input')!;
          assert.strictEqual(label.htmlFor, input.id, 'label targets its radio');
          assert.false(label.hasAttribute('aria-pressed'), 'no aria-pressed');
          assert.strictEqual(
            getComputedStyle(input).position,
            'absolute',
            'radio is visually hidden'
          );
        });
      assert.true(el<HTMLInputElement>('input[value="l"]').checked);
      assert.dom('.euiButtonGroupButton-isSelected').hasText('Left');

      await click('input[value="c"]');
      assert.deepEqual(state.calls, [['center', 'c']]);
      assert.true(el<HTMLInputElement>('input[value="c"]').checked);
      assert.dom('.euiButtonGroupButton-isSelected').hasText('Center');

      // Keyboard: the radio takes focus and the label shows the focus ring.
      const radio = el<HTMLInputElement>('input[value="r"]');
      await focus(radio);
      assert.strictEqual(document.activeElement, radio);
      if (radio.matches(':focus-visible')) {
        assert.strictEqual(
          getComputedStyle(radio.closest('label')!).outlineStyle,
          'auto',
          'focus ring on the label'
        );
      }
    });

    test('multi selection uses toggle buttons with aria-pressed', async function (assert) {
      class State {
        @tracked map: Record<string, boolean> = { left: true, center: false };
        onChange = (id: string) => {
          this.map = { ...this.map, [id]: !this.map[id] };
        };
      }
      const state = new State();
      await render(
        <template>
          <EuiButtonGroup
            @legend="Styles"
            @type="multi"
            @options={{OPTIONS}}
            @idToSelectedMap={{state.map}}
            @onChange={{state.onChange}}
          />
        </template>
      );
      assert.dom('input').doesNotExist();
      assert.dom('button.euiButtonGroupButton').exists({ count: 3 });
      assert.dom('button[title="Left"]').hasAttribute('type', 'button').hasAria('pressed', 'true');
      assert.dom('button[title="Center"]').hasAria('pressed', 'false');
      assert.dom('button[title="Right"]').doesNotHaveAttribute('aria-pressed', 'undefined in the map');

      await click('button[title="Center"]');
      assert.dom('button[title="Center"]').hasAria('pressed', 'true');
      await click('button[title="Left"]');
      assert.dom('button[title="Left"]').hasAria('pressed', 'false');
    });

    test('sizes, radius and container are measured from Borealis tokens', async function (assert) {
      await render(
        <template>
          <div data-s><EuiButtonGroup @legend="s" @options={{OPTIONS}} @idSelected="left" /></div>
          <div data-m><EuiButtonGroup @legend="m" @buttonSize="m" @options={{OPTIONS}} @idSelected="left" /></div>
          <div data-c><EuiButtonGroup @legend="c" @buttonSize="compressed" @options={{OPTIONS}} @idSelected="left" /></div>
        </template>
      );
      const expected = { s: [32, 24], m: [40, 32], c: [32, 24] } as const;
      for (const [key, [outer, inner]] of Object.entries(expected)) {
        assert.strictEqual(box(`[data-${key}] .euiButtonGroup__buttons`).height, outer, `${key} container height`);
        assert.strictEqual(box(`[data-${key}] .euiButtonGroupButton`).height, inner, `${key} button height`);
      }
      const container = style('[data-s] .euiButtonGroup__buttons');
      assert.strictEqual(container.borderRadius, light.border.radius.control);
      assert.strictEqual(container.paddingTop, light.size.xs);
      assert.strictEqual(container.paddingInlineStart, light.size.xs);
      assert.strictEqual(container.backgroundColor, rgb(light.colors.backgroundBasePlain));
      const border = style('[data-s] .euiButtonGroup__buttons', '::after');
      assert.strictEqual(border.borderTopWidth, '1px');
      assert.strictEqual(border.borderTopColor, rgb(light.colors.borderBasePlain));
      const button = style('[data-s] .euiButtonGroupButton');
      assert.strictEqual(button.borderTopLeftRadius, '6px', 'inset radius: control - xxs');
      assert.strictEqual(button.borderTopWidth, '0px');
      assert.strictEqual(button.fontWeight, String(light.font.weight.medium));
      assert.strictEqual(style('fieldset').borderTopWidth, '0px', 'fieldset reset');
      assert.strictEqual(style('fieldset').display, 'inline-block');
    });

    test('selected, disabled and color states', async function (assert) {
      const disabledOption = [
        ...OPTIONS.slice(0, 2),
        { id: 'right', label: 'Right', isDisabled: true }
      ];
      await render(
        <template>
          <div data-text><EuiButtonGroup @legend="t" @options={{disabledOption}} @idSelected="left" /></div>
          <div data-primary><EuiButtonGroup @legend="p" @color="primary" @options={{OPTIONS}} @idSelected="left" /></div>
          <div data-ghost><EuiButtonGroup @legend="g" @color="ghost" @options={{OPTIONS}} @idSelected="left" /></div>
          <div data-off><EuiButtonGroup @legend="o" @isDisabled={{true}} @options={{OPTIONS}} @idSelected="left" /></div>
        </template>
      );
      const tokens = buttons(light);
      assert.strictEqual(style('[data-text] .euiButtonGroupButton-isSelected').backgroundColor, rgb(light.colors.backgroundLightText), 'text: light selected background');
      assert.strictEqual(style('[data-text] label:not(.euiButtonGroupButton-isSelected)').backgroundColor, TRANSPARENT, 'unselected is empty');
      assert.strictEqual(style('[data-text] label:not(.euiButtonGroupButton-isSelected)').color, rgb(tokens['textColorText']!));
      assert.strictEqual(style('[data-primary] .euiButtonGroupButton-isSelected').backgroundColor, rgb(tokens['backgroundFilledPrimary']!), 'primary: filled');
      assert.strictEqual(style('[data-primary] .euiButtonGroupButton-isSelected').color, rgb(tokens['textColorFilledPrimary']!));
      assert.strictEqual(style('[data-primary] label:not(.euiButtonGroupButton-isSelected)').color, rgb(tokens['textColorPrimary']!));
      assert.strictEqual(style('[data-ghost] .euiButtonGroupButton-isSelected').backgroundColor, rgb(light.colors.backgroundLightText), 'ghost renders as text');

      // A disabled option renders a native disabled button.
      assert.dom('[data-text] button.euiButtonGroupButton').isDisabled().hasText('Right');
      assert.strictEqual(style('[data-text] button.euiButtonGroupButton').color, rgb(tokens['textColorDisabled']!));
      assert.strictEqual(style('[data-text] button.euiButtonGroupButton').cursor, 'not-allowed');

      assert.dom('[data-off] fieldset').isDisabled().hasClass('euiButtonGroup-isDisabled');
      assert.dom('[data-off] button.euiButtonGroupButton').exists({ count: 3 });
      const selectedDisabled = style('[data-off] .euiButtonGroupButton-isSelected');
      assert.strictEqual(selectedDisabled.color, rgb(light.colors.textDisabled));
      assert.strictEqual(selectedDisabled.backgroundColor, rgb(light.components.buttonGroupBackgroundDisabledSelected));
    });

    test('full width, icon only and tooltips', async function (assert) {
      const tips = [
        { id: 'a', label: 'Alpha', iconType: 'plus', toolTipContent: 'First' },
        { id: 'b', label: 'Beta', iconType: 'minus' }
      ];
      await render(
        <template>
          <div style="width: 600px" data-full>
            <EuiButtonGroup @legend="f" @isFullWidth={{true}} @options={{OPTIONS}} @idSelected="left" />
          </div>
          <div data-icons>
            <EuiButtonGroup @legend="i" @type="multi" @isIconOnly={{true}} @buttonSize="m" @options={{ICONS}} @idToSelectedMap={{SELECTED_ICONS}} />
          </div>
          <div data-tips><EuiButtonGroup @legend="t" @options={{tips}} @idSelected="a" /></div>
        </template>
      );
      assert.strictEqual(style('[data-full] fieldset').display, 'block');
      assert.strictEqual(box('[data-full] .euiButtonGroup__buttons').width, 600);
      const widths = [...document.querySelectorAll('[data-full] .euiButtonGroupButton')].map(
        (b) => Math.round(b.getBoundingClientRect().width)
      );
      assert.strictEqual(new Set(widths).size, 1, 'buttons share the width evenly');

      assert.dom('[data-icons] .euiButtonGroupButton').hasClass('euiButtonGroupButton-isIconOnly');
      assert.strictEqual(box('[data-icons] .euiButtonGroupButton').width, 32, 'm icon-only is square');
      assert.strictEqual(box('[data-icons] .euiButtonGroupButton').height, 32);
      assert.dom('[data-icons] .euiButtonGroupButton svg').exists();
      assert.strictEqual(style('[data-icons] .euiButtonGroupButton__text').position, 'absolute', 'label kept for screen readers');
      assert.dom('[data-icons] .euiButtonGroupButton__text').hasText('Bold');

      assert.dom('[data-tips] .euiToolTipAnchor.euiButtonGroup__tooltipWrapper').exists({ count: 1 });
      assert.dom('[data-tips] .euiButtonGroup__tooltipWrapper').hasClass('euiButtonGroup__tooltipWrapper-isSelected');
      assert.dom('[data-tips] .euiButtonGroup__tooltipWrapper label').hasText('Alpha');
    });

    test('text shift reserves bold width and the title tracks the label', async function (assert) {
      await render(<template><EuiButtonGroup @legend="x" @options={{OPTIONS}} @idSelected="left" /></template>);
      assert.dom('.euiButtonGroupButton__text').hasAttribute('data-text', 'Left');
      const after = style('.euiButtonGroupButton__text', '::after');
      assert.strictEqual(after.content, '"Left"');
      assert.strictEqual(after.fontWeight, String(light.font.weight.bold));
      assert.strictEqual(after.height, '0px');
      assert.dom('label.euiButtonGroupButton').hasAttribute('title', 'Left');
    });

    test('reactive args update in place without replacing elements', async function (assert) {
      class State {
        @tracked size: 's' | 'm' = 's';
        @tracked color: 'text' | 'primary' = 'text';
        @tracked selected = 'left';
        @tracked full = false;
      }
      const state = new State();
      await render(
        <template>
          <EuiButtonGroup
            @legend="r"
            @buttonSize={{state.size}}
            @color={{state.color}}
            @isFullWidth={{state.full}}
            @options={{OPTIONS}}
            @idSelected={{state.selected}}
          />
        </template>
      );
      const fieldset = el('fieldset');
      const first = el('.euiButtonGroupButton');
      state.size = 'm';
      state.color = 'primary';
      state.selected = 'center';
      state.full = true;
      await settled();
      assert.strictEqual(el('fieldset'), fieldset, 'same fieldset');
      assert.strictEqual(el('.euiButtonGroupButton'), first, 'same option element');
      assert.strictEqual(box('.euiButtonGroupButton').height, 32);
      assert.strictEqual(style('fieldset').display, 'block');
      assert.strictEqual(style('label[title="Center"]').backgroundColor, rgb(buttons(light)['backgroundFilledPrimary']!));
      assert.strictEqual(style('label[title="Left"]').backgroundColor, TRANSPARENT);
    });
  });

  module('EuiButtonContent', function () {
    test('with @size it styles itself like upstream EuiButtonDisplayContent', async function (assert) {
      await render(
        <template>
          <button type="button" data-right><EuiButtonContent @size="s" @iconType="plus" @iconSide="right">Go</EuiButtonContent></button>
          <button type="button" data-loading style="color: rgb(1, 2, 3)"><EuiButtonContent @size="m" @isLoading={{true}} @isDisabled={{true}}>Wait</EuiButtonContent></button>
          <button type="button" data-legacy><EuiButtonContent @iconType="plus" @iconSide="right">Old</EuiButtonContent></button>
        </template>
      );
      const content = style('[data-right] .euiButtonContent');
      assert.strictEqual(content.display, 'flex');
      assert.strictEqual(content.justifyContent, 'center');
      assert.strictEqual(content.columnGap, light.size.xs);
      const right = el('[data-right] .euiButtonContent');
      assert.true(right.lastElementChild!.classList.contains('euiButtonContent__icon'), 'icon after the text in DOM order');
      const text = style('[data-right] .eui-textTruncate');
      assert.strictEqual(text.paddingInlineStart, light.size.xs);
      assert.strictEqual(text.textOverflow, 'ellipsis');
      assert.strictEqual(style('[data-loading] .euiButtonContent__spinner').borderBottomColor, 'rgb(1, 2, 3)', 'disabled spinner uses currentcolor');
      // Without @size the caller styles it (EuiButton / EuiButtonEmpty contract).
      const legacy = el('[data-legacy] .euiButtonContent');
      assert.strictEqual(legacy.className, 'euiButtonContent');
      assert.true(legacy.firstElementChild!.classList.contains('euiButtonContent__icon'), 'legacy DOM order kept');
    });
  });

  module('EuiFacetButton and EuiFacetGroup', function () {
    test('quantity, selected, loading and disabled states', async function (assert) {
      let clicks = 0;
      const onClick = () => clicks++;
      await render(
        <template>
          <EuiFacetButton data-plain @quantity={{6}} {{on "click" onClick}}>
            <:default>Errors</:default>
            <:icon><EuiIcon class="euiFacetButton__icon" @type="dot" /></:icon>
          </EuiFacetButton>
          <EuiFacetButton data-selected @quantity={{2}} @isSelected={{true}}>Warnings</EuiFacetButton>
          <EuiFacetButton data-loading @quantity={{2}} @isLoading={{true}}>Info</EuiFacetButton>
          <EuiFacetButton data-disabled @quantity={{0}} @isSelected={{true}} @isDisabled={{true}}>
            <:default>Debug</:default>
            <:icon><EuiIcon class="euiFacetButton__icon" @type="dot" /></:icon>
          </EuiFacetButton>
        </template>
      );
      // Notification badges animate every property (upstream `transition: all`)
      // and icons fade in: finish every finite animation (not the spinner).
      document
        .getAnimations()
        .filter(
          (animation) =>
            animation.effect?.getComputedTiming().endTime !== Infinity
        )
        .forEach((animation) => animation.finish());
      const plain = style('[data-plain]');
      assert.strictEqual(box('[data-plain]').height, 32, 'upstream button display size s');
      assert.strictEqual(plain.backgroundColor, TRANSPARENT);
      assert.strictEqual(plain.borderTopWidth, '0px');
      assert.strictEqual(plain.textAlign, 'start', 'logical left');
      assert.dom('[data-plain]').hasAttribute('type', 'button').hasAttribute('title', 'Errors');
      assert.strictEqual(style('[data-plain] .euiFacetButton__text').fontWeight, String(light.font.weight.medium), 'inherits the button weight');
      assert.strictEqual(style('[data-plain] .euiFacetButton__text').flexGrow, '1');
      assert.strictEqual(style('[data-plain] .euiFacetButton__quantity').backgroundColor, rgb(badges['subdued']!.backgroundColor));
      await click('[data-plain]');
      assert.strictEqual(clicks, 1);

      assert.strictEqual(style('[data-selected] .euiFacetButton__text').fontWeight, String(light.font.weight.bold));
      assert.strictEqual(style('[data-selected] .euiFacetButton__quantity').backgroundColor, rgb(badges['accentText']!.backgroundColor));

      assert.dom('[data-loading]').isDisabled();
      assert.dom('[data-loading] .euiFacetButton__spinner').exists();
      assert.dom('[data-loading] .euiFacetButton__quantity').doesNotExist();

      assert.dom('[data-disabled]').isDisabled();
      assert.strictEqual(style('[data-disabled]').color, rgb(light.colors.textDisabled));
      assert.strictEqual(style('[data-disabled]').pointerEvents, 'none');
      assert.strictEqual(style('[data-disabled] .euiFacetButton__quantity').opacity, '0.5');
      // An icon that had to load fades in with a filling animation (EuiIcon
      // `isLoaded`), which overrides any opacity until it is removed.
      el('[data-disabled] .euiFacetButton__icon')
        .getAnimations()
        .forEach((animation) => animation.cancel());
      assert.strictEqual(style('[data-disabled] .euiFacetButton__icon').opacity, '0.5');
      assert.strictEqual(style('[data-disabled] .euiFacetButton__quantity').backgroundColor, rgb(badges['subdued']!.backgroundColor));
    });

    test('group layouts and gutters, reactive in place', async function (assert) {
      class State {
        @tracked layout: 'vertical' | 'horizontal' = 'vertical';
        @tracked gutter: 'none' | 's' | 'm' | 'l' = 'm';
      }
      const state = new State();
      await render(
        <template>
          <EuiFacetGroup @layout={{state.layout}} @gutterSize={{state.gutter}}>
            <EuiFacetButton>A</EuiFacetButton>
            <EuiFacetButton>B</EuiFacetButton>
          </EuiFacetGroup>
        </template>
      );
      const group = el('.euiFacetGroup');
      let computed = getComputedStyle(group);
      assert.strictEqual(computed.display, 'flex');
      assert.strictEqual(computed.flexDirection, 'column');
      assert.strictEqual(computed.rowGap, light.size.s);
      assert.strictEqual(computed.columnGap, '0px');

      state.layout = 'horizontal';
      state.gutter = 'l';
      await settled();
      assert.strictEqual(el('.euiFacetGroup'), group, 'same element');
      computed = getComputedStyle(group);
      assert.strictEqual(computed.flexDirection, 'row');
      assert.strictEqual(computed.flexWrap, 'wrap');
      assert.strictEqual(computed.rowGap, light.size.m);
      assert.strictEqual(computed.columnGap, `${parseFloat(light.size.m) * 2}px`, 'horizontal adds m');

      state.gutter = 'none';
      await settled();
      assert.strictEqual(getComputedStyle(group).rowGap, '0px');
    });
  });

  module('EuiFilterButton and EuiFilterGroup', function () {
    test('badge counts, active filters and disabled states', async function (assert) {
      await render(
        <template>
          <EuiFilterButton data-available @iconType="arrowDown" @numFilters={{12}}>Status</EuiFilterButton>
          <EuiFilterButton data-active @iconType="arrowDown" @numFilters={{12}} @numActiveFilters={{2}} @hasActiveFilters={{true}}>Tags</EuiFilterButton>
          <EuiFilterButton data-zero @numFilters={{0}}>Zero</EuiFilterButton>
          <EuiFilterButton data-success @numActiveFilters={{3}} @hasActiveFilters={{true}} @badgeColor="success">Ok</EuiFilterButton>
          <EuiFilterButton data-disabled @numFilters={{4}} @hasActiveFilters={{true}} @isDisabled={{true}}>Off</EuiFilterButton>
          <EuiFilterButton data-plain>Plain</EuiFilterButton>
        </template>
      );
      assert.dom('[data-available] .euiFilterButton__notification').hasText('12').hasAria('label', '12 available filters').hasAttribute('role', 'marquee');
      assert.strictEqual(style('[data-available] .euiFilterButton__notification').backgroundColor, rgb(badges['subdued']!.backgroundColor));
      assert.dom('[data-available]').hasAria('expanded', 'false').doesNotHaveAttribute('aria-pressed');
      assert.strictEqual(style('[data-available]').fontWeight, String(light.font.weight.medium));

      assert.dom('[data-active] .euiFilterButton__notification').hasText('2').hasAria('label', '2 active filters');
      assert.strictEqual(style('[data-active] .euiFilterButton__notification').backgroundColor, rgb(badges['accentText']!.backgroundColor));
      assert.dom('[data-active]').hasAria('expanded', 'true', 'active filters expand a popover anchor');
      assert.dom('[data-active] .euiFilterButton__text').hasClass('euiFilterButton__text-hasNotification');
      assert.strictEqual(box('[data-active]').width >= 96 - 8, true, 'hasNotification min width');

      assert.dom('[data-zero] .euiFilterButton__notification').hasText('0');
      assert.strictEqual(style('[data-success] .euiFilterButton__notification').backgroundColor, rgb(badges['success']?.backgroundColor ?? light.colors.success));

      assert.dom('[data-disabled]').isDisabled();
      assert.strictEqual(style('[data-disabled] .euiFilterButton__notification').backgroundColor, rgb(badges['subdued']!.backgroundColor));
      assert.strictEqual(style('[data-disabled] .euiFilterButton__notification').opacity, '0.5');
      assert.strictEqual(style('[data-disabled]').color, rgb(buttons(light)['textColorDisabled']!));

      assert.dom('[data-plain] .euiFilterButton__notification').doesNotExist();
      assert.strictEqual(style('[data-plain]').color, rgb(buttons(light)['textColorText']!));
      assert.strictEqual(style('[data-plain] .euiFilterButton__text').textOverflow, 'ellipsis');
      assert.strictEqual(style('[data-plain] .euiFilterButton__text', '::after').content, '"Plain"', 'text shift');
    });

    test('group layout: border, sizes, dividers, withNext, grow and RTL', async function (assert) {
      await render(
        <template>
          <div style="width: 800px">
            <EuiFilterGroup data-group>
              <EuiFilterButton data-first @withNext={{true}}>On</EuiFilterButton>
              <EuiFilterButton data-second>Off</EuiFilterButton>
              <EuiFilterButton data-nogrow @grow={{false}}>Fixed</EuiFilterButton>
            </EuiFilterGroup>
          </div>
          <EuiFilterGroup data-compressed @compressed={{true}} @showDividers={{false}}>
            <EuiFilterButton data-c1>On</EuiFilterButton>
            <EuiFilterButton data-c2>Off</EuiFilterButton>
          </EuiFilterGroup>
          <div dir="rtl">
            <EuiFilterGroup data-rtl>
              <EuiFilterButton @withNext={{true}}>One</EuiFilterButton>
              <EuiFilterButton data-rtl-second>Two</EuiFilterButton>
            </EuiFilterGroup>
          </div>
          <EuiFilterGroup data-full @fullWidth={{true}}><EuiFilterButton>X</EuiFilterButton></EuiFilterGroup>
        </template>
      );
      const group = style('[data-group]');
      assert.strictEqual(group.display, 'inline-flex');
      assert.strictEqual(group.borderTopLeftRadius, light.border.radius.control);
      assert.strictEqual(group.backgroundColor, rgb(light.components.forms.background));
      assert.dom('[data-group]').hasAttribute('data-dividers', 'true').hasAttribute('data-display', 'regular');
      const border = style('[data-group]', '::after');
      assert.strictEqual(border.borderTopWidth, '1px');
      assert.strictEqual(border.borderTopColor, rgb(light.colors.borderBasePlain));

      assert.strictEqual(box('[data-group] .euiFilterButton__wrapper').height, 40, 'wrapper m height');
      assert.strictEqual(box('[data-first]').height, 32, 'button inset height');
      assert.strictEqual(style('[data-first]').borderTopLeftRadius, '6px');
      const secondWrapper = el('[data-second]').parentElement!;
      assert.strictEqual(getComputedStyle(secondWrapper).marginInlineStart, '-5px', 'withNext overlaps padding + divider');
      assert.strictEqual(getComputedStyle(secondWrapper, '::before').borderInlineStartWidth, '0px', 'no divider after withNext');
      const nogrowWrapper = el('[data-nogrow]').parentElement!;
      assert.strictEqual(getComputedStyle(nogrowWrapper).flexGrow, '0');
      assert.strictEqual(getComputedStyle(nogrowWrapper, '::before').borderInlineStartWidth, '1px', 'divider');
      assert.strictEqual(getComputedStyle(el('[data-first]').parentElement!).flexGrow, '1');

      assert.dom('[data-compressed]').doesNotHaveAttribute('data-dividers');
      assert.strictEqual(box('[data-c1]').height, 24, 'compressed inset height');
      assert.strictEqual(getComputedStyle(el('[data-c1]').parentElement!, '::before').content, 'none', 'no dividers');
      assert.strictEqual(getComputedStyle(el('[data-c2]').parentElement!).marginInlineStart, '-4px');

      const rtlSecond = getComputedStyle(el('[data-rtl-second]').parentElement!);
      assert.strictEqual(rtlSecond.marginRight, '-5px', 'logical margin flips in RTL');
      assert.strictEqual(rtlSecond.marginLeft, '0px');

      assert.strictEqual(style('[data-full]').display, 'flex');
    });

    test('toggles: pressed state, highlighted fill and inverse badge', async function (assert) {
      class State {
        @tracked on = false;
        @tracked display: 'regular' | 'highlighted' = 'regular';
      }
      const state = new State();
      const toggle = () => (state.on = !state.on);
      await render(
        <template>
          <EuiFilterGroup @display={{state.display}}>
            <EuiFilterButton data-toggle @isToggle={{true}} @isSelected={{state.on}} @numFilters={{3}} {{on "click" toggle}}>On</EuiFilterButton>
          </EuiFilterGroup>
        </template>
      );
      const button = el('[data-toggle]');
      assert.dom(button).hasClass('euiFilterButton-isToggle').hasClass('euiButton').hasAria('pressed', 'false');
      assert.dom('[data-toggle] .euiThemeProvider').doesNotExist();
      await click(button);
      assert.strictEqual(el('[data-toggle]'), button, 'same element');
      assert.dom(button).hasAria('pressed', 'true').hasClass('euiFilterButton-isSelected');
      assert.strictEqual(getComputedStyle(button).backgroundColor, rgb(light.colors.backgroundLightText));
      assert.dom('[data-toggle] .euiThemeProvider .euiFilterButton__notification').exists('badge in the inverse mode');
      // Upstream `inline-flex`, blockified to `flex` as a flex item.
      assert.strictEqual(style('[data-toggle] .euiFilterButton__content .euiThemeProvider').display, 'flex');
      assert.strictEqual(style('[data-toggle] .euiThemeProvider').color, rgb(dark.colors.textParagraph), 'inverse (dark) mode');

      state.display = 'highlighted';
      await settled();
      assert.strictEqual(getComputedStyle(button).backgroundColor, rgb(buttons(light)['backgroundFilledText']!), 'highlighted fills');
    });
  });

  module('EuiFilterSelectItem', function () {
    test('checked, focus and disabled semantics', async function (assert) {
      class State {
        @tracked focused = false;
      }
      const state = new State();
      await render(
        <template>
          <div role="listbox" aria-label="Status" style="width: 120px">
            <EuiFilterSelectItem data-on @checked="on">Open</EuiFilterSelectItem>
            <EuiFilterSelectItem data-off @checked="off">Closed</EuiFilterSelectItem>
            <EuiFilterSelectItem data-focus @isFocused={{state.focused}}>A very long draft label that truncates</EuiFilterSelectItem>
            <EuiFilterSelectItem data-disabled @showIcons={{false}} @disabled={{true}}>Archived</EuiFilterSelectItem>
          </div>
        </template>
      );
      assert.dom('[data-on]').hasAttribute('role', 'option').hasAttribute('type', 'button').hasAria('selected', 'true');
      assert.dom('[data-off]').hasAria('selected', 'false');
      assert.dom('[data-focus]').hasAria('selected', 'false');
      assert.dom('[data-on] .euiIcon').exists();
      assert.dom('[data-disabled] .euiIcon').doesNotExist();
      assert.dom('[data-disabled]').isDisabled().hasAria('disabled', 'true');

      const on = style('[data-on]');
      assert.strictEqual(on.display, 'block');
      assert.strictEqual(on.paddingTop, light.size.xs);
      assert.strictEqual(on.paddingInlineStart, light.size.m);
      assert.strictEqual(on.textAlign, 'start', 'logical left');
      assert.strictEqual(on.color, rgb(light.colors.textParagraph));
      assert.strictEqual(on.backgroundColor, TRANSPARENT);
      assert.strictEqual(on.borderBottomColor, rgb(light.colors.borderBaseSubdued));
      assert.strictEqual(on.borderBottomWidth, '1px');
      assert.strictEqual(on.borderTopWidth, '0px');
      assert.strictEqual(box('[data-on]').width, 120, 'full width');
      assert.strictEqual(style('[data-focus] .euiFilterSelectItem__content').textOverflow, 'ellipsis');
      assert.strictEqual(style('[data-disabled]').color, rgb(light.colors.textDisabled));
      assert.strictEqual(style('[data-disabled]').cursor, 'not-allowed');

      const item = el<HTMLButtonElement>('[data-focus]');
      let scrolled = 0;
      item.scrollIntoView = () => {
        scrolled++;
      };
      state.focused = true;
      await settled();
      assert.strictEqual(el('[data-focus]'), item, 'same element');
      assert.strictEqual(scrolled, 1, 'scrolled into view on focus');
      const focused = getComputedStyle(item);
      assert.strictEqual(focused.color, rgb(light.colors.primary));
      assert.strictEqual(focused.backgroundColor, rgb(light.focus.backgroundColor));
      assert.strictEqual(focused.textDecorationLine, 'underline');
    });
  });

  module('themes', function () {
    test('nearest-provider light/dark, sibling isolation and JS-object overrides', async function (assert) {
      class State {
        @tracked mode: EuiColorMode = 'light';
      }
      const state = new State();
      const own: EuiBorealisOverrides = {
        border: { radius: { control: '12px' } },
        colors: {
          LIGHT: { backgroundLightText: '#123456' },
          DARK: { backgroundLightText: '#abcdef' }
        }
      };
      await render(
        <template>
          <EuiEmotionProvider @colorMode={{state.mode}}>
            <div data-parent>
              <EuiButtonGroup @legend="p" @options={{OPTIONS}} @idSelected="left" />
              <EuiFilterSelectItem @checked="on">Open</EuiFilterSelectItem>
            </div>
            <EuiEmotionProvider @borealisOverrides={{own}}>
              <div data-child>
                <EuiButtonGroup @legend="c" @options={{OPTIONS}} @idSelected="left" />
                <EuiFilterGroup><EuiFilterButton @isToggle={{true}} @isSelected={{true}}>T</EuiFilterButton></EuiFilterGroup>
              </div>
            </EuiEmotionProvider>
          </EuiEmotionProvider>
          <EuiEmotionProvider @colorMode="light">
            <div data-sibling><EuiButtonGroup @legend="s" @options={{OPTIONS}} @idSelected="left" /></div>
          </EuiEmotionProvider>
        </template>
      );
      const container = () => style('[data-parent] .euiButtonGroup__buttons').backgroundColor;
      const parentGroup = el('[data-parent] fieldset');
      assert.strictEqual(container(), rgb(light.colors.backgroundBasePlain));
      assert.strictEqual(style('[data-child] .euiButtonGroup__buttons').borderTopLeftRadius, '12px', 'override radius');
      assert.strictEqual(style('[data-child] .euiButtonGroupButton').borderTopLeftRadius, '10px', 'inset radius follows');
      assert.strictEqual(style('[data-child] .euiButtonGroupButton-isSelected').backgroundColor, rgb('#123456'));
      assert.strictEqual(style('[data-child] .euiFilterButton-isSelected').backgroundColor, rgb('#123456'));

      state.mode = 'dark';
      await settled();
      assert.strictEqual(el('[data-parent] fieldset'), parentGroup, 'same element');
      assert.strictEqual(container(), rgb(dark.colors.backgroundBasePlain), 'parent follows dark');
      assert.strictEqual(style('[data-parent] .euiFilterSelectItem').color, rgb(dark.colors.textParagraph));
      assert.strictEqual(style('[data-child] .euiButtonGroupButton-isSelected').backgroundColor, rgb('#abcdef'), 'nested inherits dark with its own override');
      assert.strictEqual(style('[data-sibling] .euiButtonGroup__buttons').backgroundColor, rgb(light.colors.backgroundBasePlain), 'sibling stays light');
      assert.strictEqual(style('[data-sibling] .euiButtonGroupButton-isSelected').backgroundColor, rgb(light.colors.backgroundLightText));
    });

    test('preferred high contrast adds selection borders', async function (assert) {
      await render(
        <template>
          <EuiEmotionProvider @highContrastMode="preferred">
            <div data-hc>
              <EuiButtonGroup @legend="h" @options={{OPTIONS}} @idSelected="left" />
              <EuiFilterGroup><EuiFilterButton data-toggle @isToggle={{true}} @isSelected={{true}}>T</EuiFilterButton></EuiFilterGroup>
            </div>
          </EuiEmotionProvider>
          <div data-standard><EuiButtonGroup @legend="s" @options={{OPTIONS}} @idSelected="left" /></div>
        </template>
      );
      const selected = style('[data-hc] .euiButtonGroupButton-isSelected');
      assert.strictEqual(selected.borderTopWidth, '1px');
      assert.strictEqual(selected.borderTopColor, selected.color, 'currentColor border');
      assert.strictEqual(style('[data-hc] label:not(.euiButtonGroupButton-isSelected)').borderTopWidth, '0px');
      assert.strictEqual(style('[data-hc] [data-toggle]').borderTopWidth, '1px');
      assert.strictEqual(style('[data-standard] .euiButtonGroupButton-isSelected').borderTopWidth, '0px');
    });
  });
});

