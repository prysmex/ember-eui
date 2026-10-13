import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { click, focus, render, settled } from '@ember/test-helpers';
import { setupRenderingTest } from 'ember-qunit';
import { module, test } from 'qunit';

import EuiCheckbox from '#src/components/eui-checkbox.gts';
import EuiCheckboxGroup from '#src/components/eui-checkbox-group.gts';
import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import EuiRadio from '#src/components/eui-radio.gts';
import EuiRadioGroup from '#src/components/eui-radio-group.gts';
import EuiSwitch from '#src/components/eui-switch.gts';
import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';

import type {
  EuiBorealisContext,
  EuiBorealisHighContrastMode,
  EuiBorealisOverrides
} from '#src/utils/eui/theme.ts';

const light = resolveBorealisTheme('light').euiTheme;
const dark = resolveBorealisTheme('dark').euiTheme;
const TRANSPARENT = 'rgba(0, 0, 0, 0)';
const array = [{ id: 'a', label: 'A' }];
const map = { a: false };
const noop = () => {};

function el(root: Element, selector: string) {
  const element = root.querySelector<HTMLElement>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

function style(root: Element, selector: string) {
  return getComputedStyle(el(root, selector));
}

/** Normalize any CSS color to the browser's computed `rgb()` form. */
function rgb(color: string) {
  const probe = document.createElement('span');
  probe.style.color = color;
  document.body.appendChild(probe);
  const value = getComputedStyle(probe).color;
  probe.remove();
  return value;
}

/** `#ember-testing` is scaled down; undo it so boxes are in CSS pixels. */
function scale() {
  const container = document.querySelector<HTMLElement>('#ember-testing');
  if (!container?.offsetWidth) return 1;
  return container.getBoundingClientRect().width / container.offsetWidth;
}

function box(root: Element, selector: string) {
  const rect = el(root, selector).getBoundingClientRect();
  const factor = scale();
  const round = (value: number) => Math.round((value / factor) * 100) / 100;
  return {
    left: round(rect.left),
    right: round(rect.right),
    top: round(rect.top),
    width: round(rect.width),
    height: round(rect.height)
  };
}

/** Upstream font sizes are rem based; EUI apps set a 14px root (`s`). */
function remPx(rem: number) {
  return rem * parseFloat(getComputedStyle(document.documentElement).fontSize);
}

function assertFont(assert: Assert, fontSize: string, px: number, label: string) {
  assert.true(
    Math.abs(parseFloat(fontSize) - remPx(px / 14)) < 0.05,
    `${label}: ${fontSize} is the ${px}px (in a 14px root) scale step`
  );
}

/** Finish background/thumb transitions so computed styles are final. */
function finishTransitions() {
  document.getAnimations().forEach((animation) => animation.finish());
}

/** Square (checkbox control) or circle (radio) of a control by data attribute. */
function controlStyle(root: Element, name: string) {
  const host = el(root, `[data-test="${name}"]`).closest('.euiCheckbox, .euiRadio')!;
  return getComputedStyle(
    host.querySelector('.euiCheckboxControl, .euiRadio__circle')!
  );
}

/** Rendered (not `display: none`) state icons, by their upstream type. */
function visibleIcons(root: Element, name: string) {
  const host = el(root, `[data-test="${name}"]`).closest('.euiCheckbox, .euiRadio')!;
  const types = host.classList.contains('euiRadio') ? ['dot'] : ['check', 'stopFill'];
  return [...host.querySelectorAll('.euiCheckbox__icon, .euiRadio__icon')]
    .map((icon, index) => [icon, types[index]] as const)
    .filter(([icon]) => getComputedStyle(icon).display !== 'none')
    .map(([, type]) => type);
}

type Theme = EuiBorealisContext['euiTheme'];

function assertControl(
  assert: Assert,
  actual: CSSStyleDeclaration,
  expected: { background: string; border: string },
  label: string
) {
  assert.strictEqual(
    actual.backgroundColor,
    expected.background === 'transparent' ? TRANSPARENT : rgb(expected.background),
    `${label}: background`
  );
  assert.strictEqual(actual.borderTopColor, rgb(expected.border), `${label}: border`);
}

function states(theme: Theme, highContrast = false) {
  const forms = theme.components.forms;
  return {
    unselected: {
      background: forms.controlBackgroundUnselected,
      border: highContrast ? theme.border.color : forms.controlBorder
    },
    selected: { background: theme.colors.primary, border: theme.colors.primary },
    disabled: {
      background: forms.controlBackgroundDisabled,
      border: highContrast ? forms.iconDisabled : forms.controlBackgroundDisabled
    }
  };
}

module('Integration | Component | Borealis checkables (checkbox, radio, switch)', function (hooks) {
  setupRenderingTest(hooks);

  test('EuiCheckbox measures every state from the upstream control factory', async function (assert) {
    await render(
      <template>
        <EuiCheckbox @label="Off" data-test="off" />
        <EuiCheckbox @label="On" @checked={{true}} data-test="on" />
        <EuiCheckbox @label="Some" @indeterminate={{true}} data-test="some" />
        <EuiCheckbox @label="Disabled" @disabled={{true}} data-test="disabled" />
        <EuiCheckbox
          @label="Disabled on"
          @disabled={{true}}
          @checked={{true}}
          data-test="disabled-on"
        />
        <EuiCheckbox data-test="bare" />
      </template>
    );
    finishTransitions();
    const s = states(light);
    const root = this.element;

    assertControl(assert, controlStyle(root, 'off'), s.unselected, 'unchecked');
    assertControl(assert, controlStyle(root, 'on'), s.selected, 'checked');
    assertControl(assert, controlStyle(root, 'some'), s.selected, 'indeterminate');
    assertControl(assert, controlStyle(root, 'disabled'), s.disabled, 'disabled');
    assertControl(assert, controlStyle(root, 'disabled-on'), s.disabled, 'disabled checked');

    assert.strictEqual(controlStyle(root, 'on').color, rgb(light.colors.emptyShade), 'check color');
    assert.strictEqual(
      controlStyle(root, 'disabled-on').color,
      rgb(light.components.forms.iconDisabled),
      'disabled check color'
    );
    assert.strictEqual(controlStyle(root, 'off').color, TRANSPARENT);

    // The check mark: only the matching icon is rendered (display), so
    // forced colors can never reveal a hidden one.
    assert.deepEqual(visibleIcons(root, 'off'), [], 'no mark when unchecked');
    assert.deepEqual(visibleIcons(root, 'on'), ['check'], 'check mark');
    assert.deepEqual(visibleIcons(root, 'some'), ['stopFill'], 'indeterminate bar');
    assert.deepEqual(visibleIcons(root, 'disabled-on'), ['check']);
    const checkIcon = [...el(root, '[data-test="on"]').parentElement!.querySelectorAll('.euiCheckbox__icon')]
      .find((icon) => getComputedStyle(icon).display !== 'none')!;
    assert.true(getComputedStyle(checkIcon).transform.startsWith('matrix(0.75'), 'check scaled 0.75');
    const bar = [...el(root, '[data-test="some"]').parentElement!.querySelectorAll('.euiCheckbox__icon')]
      .find((icon) => getComputedStyle(icon).display !== 'none')!;
    assert.true(getComputedStyle(bar).transform.startsWith('matrix(0.5'), 'indeterminate scaled 0.5');
    assert.strictEqual(checkIcon.getAttribute('role'), 'presentation');

    // Geometry: 16px square with a 1px border and inline radius, 24px label line.
    const square = el(root, '[data-test="on"]').parentElement!;
    const squareRect = square.getBoundingClientRect();
    assert.strictEqual(Math.round(squareRect.width / scale()), 16, 'square width');
    assert.strictEqual(Math.round(squareRect.height / scale()), 16, 'square height');
    const control = controlStyle(root, 'on');
    assert.strictEqual(control.borderTopWidth, '1px');
    assert.strictEqual(control.borderTopLeftRadius, light.border.radius.inline);
    assert.strictEqual(getComputedStyle(square).marginTop, '4px', 'centred on the 24px label line');
    assert.strictEqual(
      getComputedStyle(el(root, '[data-test="bare"]').parentElement!).marginTop,
      '0px',
      'no label offset without a label'
    );
    assert.dom('[data-test="bare"]').hasNoAttribute('aria-hidden');
    assert.dom(el(root, '[data-test="bare"]').closest('.euiCheckbox')!).doesNotContainText('Off');

    const label = style(root, '.euiCheckbox:has([data-test="on"]) .euiCheckbox__label');
    assert.strictEqual(label.paddingInlineStart, '8px');
    assert.strictEqual(label.lineHeight, '24px');
    assertFont(assert, label.fontSize, 14, 'label');
    assert.strictEqual(label.cursor, 'pointer');
    const disabledLabel = style(root, '.euiCheckbox:has([data-test="disabled"]) .euiCheckbox__label');
    assert.strictEqual(disabledLabel.color, rgb(light.colors.textDisabled));
    assert.strictEqual(disabledLabel.cursor, 'not-allowed');

    // The native input is hidden (opacity) on top of the square, still interactive.
    const input = style(root, '[data-test="on"]');
    assert.strictEqual(input.opacity, '0');
    assert.strictEqual(input.position, 'absolute');
    assert.strictEqual(input.cursor, 'pointer');
    assert.strictEqual(style(root, '[data-test="disabled"]').cursor, 'not-allowed');
    assert.strictEqual(style(root, '.euiCheckbox').display, 'flex');
    assert.strictEqual(style(root, '.euiCheckbox').alignItems, 'flex-start');
    assert.dom('.euiCheckbox--compressed, .euiCheckbox--noLabel').doesNotExist('no legacy modifiers');
  });

  test('EuiCheckbox keeps native semantics: label click, activation, name/value, uncontrolled state', async function (assert) {
    const changes: boolean[] = [];
    const onChange = (event: Event) => changes.push((event.target as HTMLInputElement).checked);

    await render(
      <template>
        <form>
          <EuiCheckbox
            @id="native"
            @label="Native"
            @name="agree"
            value="yes"
            data-test="native"
            {{on "change" onChange}}
          />
        </form>
      </template>
    );
    const input = el(this.element, '[data-test="native"]') as HTMLInputElement;
    assert.dom(input).hasAttribute('name', 'agree').hasAttribute('value', 'yes');
    assert.dom('label.euiCheckbox__label').hasAttribute('for', 'native');

    await click('label.euiCheckbox__label');
    finishTransitions();
    assert.true(input.checked, 'label click toggles');
    assert.deepEqual(changes, [true]);
    assertControl(assert, controlStyle(this.element, 'native'), states(light).selected, 'uncontrolled checked');
    assert.deepEqual(visibleIcons(this.element, 'native'), ['check']);
    assert.deepEqual(
      [...new FormData(el(this.element, 'form') as HTMLFormElement).entries()],
      [['agree', 'yes']],
      'submits name/value'
    );

    // Space on a focused checkbox runs its activation behavior (`click()`);
    // synthetic key events cannot trigger default actions, so we assert it is
    // focusable and activate it the way the browser does.
    await focus(input);
    assert.strictEqual(document.activeElement, input, 'the native input takes focus');
    assert.strictEqual(input.tabIndex, 0);
    input.click();
    await settled();
    finishTransitions();
    assert.false(input.checked, 'activation toggles back');
    assert.deepEqual(changes, [true, false]);
    assertControl(assert, controlStyle(this.element, 'native'), states(light).unselected, 'unchecked again');
  });

  test('EuiCheckbox reactive args update the same elements, including indeterminate', async function (assert) {
    class State {
      @tracked checked = false;
      @tracked indeterminate = false;
      @tracked disabled = false;
      @tracked label: string | undefined = 'Label';
    }
    const state = new State();
    await render(
      <template>
        <EuiCheckbox
          @checked={{state.checked}}
          @indeterminate={{state.indeterminate}}
          @disabled={{state.disabled}}
          @label={{state.label}}
          data-test="cb"
        />
      </template>
    );
    const input = el(this.element, '[data-test="cb"]') as HTMLInputElement;
    const control = el(this.element, '.euiCheckboxControl');
    const s = states(light);

    state.indeterminate = true;
    await settled();
    finishTransitions();
    assert.true(input.indeterminate, 'indeterminate property set via JS');
    assert.false(input.hasAttribute('indeterminate'), 'not an attribute');
    assertControl(assert, getComputedStyle(control), s.selected, 'indeterminate');
    assert.deepEqual(visibleIcons(this.element, 'cb'), ['stopFill']);

    state.indeterminate = false;
    state.checked = true;
    await settled();
    finishTransitions();
    assert.false(input.indeterminate);
    assert.true(input.checked);
    assert.deepEqual(visibleIcons(this.element, 'cb'), ['check']);

    state.disabled = true;
    await settled();
    finishTransitions();
    assertControl(assert, getComputedStyle(control), s.disabled, 'disabled');

    state.label = undefined;
    await settled();
    assert.dom('.euiCheckbox__label').doesNotExist();
    assert.strictEqual(getComputedStyle(el(this.element, '.euiCheckbox__square')).marginTop, '0px');
    assert.strictEqual(el(this.element, '[data-test="cb"]'), input, 'input was not replaced');
    assert.strictEqual(el(this.element, '.euiCheckboxControl'), control, 'control was not replaced');
  });

  test('focus rings: checkbox square and radio circle outline the focused native input', async function (assert) {
    await render(
      <template>
        <EuiCheckbox @label="Focus me" data-test="cb" />
        <EuiRadio @label="Radio" @name="focus" data-test="radio" />
      </template>
    );
    for (const [name, selector] of [
      ['cb', '.euiCheckbox__square'],
      ['radio', '.euiRadio__circle']
    ] as const) {
      const input = el(this.element, `[data-test="${name}"]`);
      const ring = el(this.element, selector);
      assert.strictEqual(getComputedStyle(ring).outlineStyle, 'none', `${name}: no ring before focus`);
      await focus(input);
      if (input.matches(':focus-visible')) {
        const outline = getComputedStyle(ring);
        assert.strictEqual(outline.outlineStyle, 'solid', `${name}: ring`);
        assert.strictEqual(outline.outlineWidth, light.focus.width);
        assert.strictEqual(outline.outlineOffset, light.focus.width);
        assert.strictEqual(outline.outlineColor, rgb(light.colors.primary));
      } else {
        assert.strictEqual(getComputedStyle(ring).outlineStyle, 'none', `${name}: pointer focus has no ring`);
      }
    }
    finishTransitions();
    // Upstream's unselected radio shows a primary border while focused.
    assert.strictEqual(
      style(this.element, '.euiRadio__circle').borderTopColor,
      rgb(light.colors.primary),
      'focused unselected radio border'
    );
  });

  test('EuiRadio states, the dot, and native sibling unchecking', async function (assert) {
    await render(
      <template>
        <EuiRadio @label="A" @name="letters" data-test="a" />
        <EuiRadio @label="B" @name="letters" @checked={{true}} data-test="b" />
        <EuiRadio @label="C" @name="other" @disabled={{true}} data-test="c" />
        <EuiRadio @label="D" @name="other2" @disabled={{true}} @checked={{true}} data-test="d" />
      </template>
    );
    finishTransitions();
    const s = states(light);
    const root = this.element;
    assertControl(assert, controlStyle(root, 'a'), s.unselected, 'unselected');
    assertControl(assert, controlStyle(root, 'b'), s.selected, 'selected');
    assertControl(assert, controlStyle(root, 'c'), s.disabled, 'disabled');
    assertControl(assert, controlStyle(root, 'd'), s.disabled, 'disabled selected');
    assert.strictEqual(controlStyle(root, 'b').color, rgb(light.colors.emptyShade), 'dot color');
    assert.strictEqual(controlStyle(root, 'd').color, rgb(light.components.forms.iconDisabled));
    assert.strictEqual(controlStyle(root, 'a').borderTopLeftRadius, '50%');
    assert.deepEqual(visibleIcons(root, 'a'), []);
    assert.deepEqual(visibleIcons(root, 'b'), ['dot']);
    const circle = el(root, '[data-test="b"]').parentElement!.getBoundingClientRect();
    assert.strictEqual(Math.round(circle.width / scale()), 16);
    assert.strictEqual(Math.round(circle.height / scale()), 16);

    await click('.euiRadio:has([data-test="a"]) label');
    finishTransitions();
    assert.true((el(root, '[data-test="a"]') as HTMLInputElement).checked);
    assert.false((el(root, '[data-test="b"]') as HTMLInputElement).checked, 'browser unchecked B');
    assertControl(assert, controlStyle(root, 'b'), s.unselected, 'B follows the native state');
    assert.deepEqual(visibleIcons(root, 'b'), []);
    assert.deepEqual(visibleIcons(root, 'a'), ['dot']);

    const label = style(root, '.euiRadio:has([data-test="c"]) .euiRadio__label');
    assert.strictEqual(label.color, rgb(light.colors.textDisabled));
    assert.strictEqual(label.cursor, 'not-allowed');
    assert.strictEqual(label.lineHeight, '24px');
    assert.dom('.euiRadio--noLabel, .euiRadio--compressed').doesNotExist();
  });

  test('groups: flex column, xs gap or compressed, legend fieldset, names and aria', async function (assert) {
    class State {
      @tracked compressed = false;
      @tracked selected: Record<string, boolean> = { a: true };
      @tracked idSelected = 'x';
    }
    const state = new State();
    const options = [
      { id: 'a', label: 'Apple' },
      { id: 'b', label: 'Banana', disabled: true }
    ];
    const radios = [
      { id: 'x', label: 'X', value: '1' },
      { id: 'y', label: 'Y', value: '2' }
    ];
    const calls: unknown[][] = [];
    const onCheckbox = (id: string) => {
      calls.push(['checkbox', id]);
      state.selected = { ...state.selected, [id]: !state.selected[id] };
    };
    const onRadio = (id: string, value?: string) => {
      calls.push(['radio', id, value]);
      state.idSelected = id;
    };

    await render(
      <template>
        <EuiCheckboxGroup
          @options={{options}}
          @idToSelectedMap={{state.selected}}
          @onChange={{onCheckbox}}
          @compressed={{state.compressed}}
          data-test="cbg"
          aria-label="Fruits"
        />
        <EuiCheckboxGroup
          @options={{options}}
          @idToSelectedMap={{state.selected}}
          @onChange={{onCheckbox}}
          @legend="Pick fruit"
          data-test="cbg-legend"
        />
        <EuiRadioGroup
          @options={{radios}}
          @idSelected={{state.idSelected}}
          @onChange={{onRadio}}
          @compressed={{state.compressed}}
          @name="letters"
          role="radiogroup"
          aria-label="Letters"
          data-test="rg"
        />
        <EuiRadioGroup
          @options={{radios}}
          @idSelected={{state.idSelected}}
          @onChange={{onRadio}}
          @legend="Pick letter"
          data-test="rg-legend"
        />
      </template>
    );
    const root = this.element;
    for (const name of ['cbg', 'rg']) {
      const group = style(root, `[data-test="${name}"]`);
      assert.strictEqual(group.display, 'flex', `${name}: flex`);
      assert.strictEqual(group.flexDirection, 'column');
      assert.strictEqual(group.rowGap, light.size.xs, `${name}: xs gap`);
    }
    assert.dom('[data-test="cbg"]').hasClass('euiCheckboxGroup').hasAttribute('aria-label', 'Fruits');
    assert.dom('[data-test="rg"]').hasClass('euiRadioGroup').hasAttribute('role', 'radiogroup');
    const first = box(root, '[data-test="cbg"] .euiCheckbox:nth-of-type(1)');
    const second = box(root, '[data-test="cbg"] .euiCheckbox:nth-of-type(2)');
    assert.strictEqual(Math.round(second.top - (first.top + first.height)), 4, 'rows 4px apart');

    const gapBefore = el(root, '[data-test="cbg"]');
    state.compressed = true;
    await settled();
    assert.strictEqual(style(root, '[data-test="cbg"]').rowGap, '0px', 'compressed removes the gap');
    assert.strictEqual(style(root, '[data-test="rg"]').rowGap, '0px');
    assert.strictEqual(el(root, '[data-test="cbg"]'), gapBefore, 'group not replaced');

    // Legends wrap the group in a fieldset that carries the group class.
    assert.dom('fieldset[data-test="cbg-legend"]').hasClass('euiCheckboxGroup');
    assert.dom('fieldset[data-test="cbg-legend"] > legend').hasText('Pick fruit');
    assert.dom('fieldset[data-test="rg-legend"]').hasClass('euiRadioGroup');
    assert.dom('fieldset[data-test="rg-legend"] > legend').hasText('Pick letter');
    assert.strictEqual(style(root, '[data-test="rg-legend"]').flexDirection, 'column');

    // Radios share one name per group; the legend group generates its own.
    const names = [...root.querySelectorAll<HTMLInputElement>('[data-test="rg"] input')].map((i) => i.name);
    assert.deepEqual(names, ['letters', 'letters']);
    const generated = [...root.querySelectorAll<HTMLInputElement>('[data-test="rg-legend"] input')].map((i) => i.name);
    assert.ok(generated[0]);
    assert.strictEqual(generated[0], generated[1]);
    assert.notStrictEqual(generated[0], 'letters');

    assert.dom('[data-test="cbg"] input.euiCheckboxGroup__item:disabled').exists({ count: 1 });
    await click('[data-test="cbg"] .euiCheckbox:nth-of-type(1) label');
    await click('[data-test="rg"] .euiRadio:nth-of-type(2) label');
    assert.deepEqual(calls, [
      ['checkbox', 'a'],
      ['radio', 'y', '2']
    ]);
    assert.false((el(root, '[data-test="cbg"] input') as HTMLInputElement).checked);
    assert.true((el(root, '[data-test="rg-legend"] .euiRadio:nth-of-type(2) input') as HTMLInputElement).checked);
  });

  test('EuiSwitch sizes, thumb positions, colors and icons are measured', async function (assert) {
    await render(
      <template>
        <EuiSwitch @label="Off" @checked={{false}} data-test="off" />
        <EuiSwitch @label="On" @checked={{true}} data-test="on" />
        <EuiSwitch @label="Compressed" @checked={{true}} @compressed={{true}} data-test="compressed" />
        <EuiSwitch @label="Mini" @checked={{true}} @mini={{true}} @compressed={{true}} data-test="mini" />
        <EuiSwitch @label="Disabled" @checked={{false}} @disabled={{true}} data-test="disabled" />
        <EuiSwitch
          @label="Disabled mini"
          @checked={{true}}
          @disabled={{true}}
          @mini={{true}}
          data-test="disabled-mini"
        />
      </template>
    );
    finishTransitions();
    const root = this.element;
    const c = light.components;
    // Upstream sizes: (xxl + xs) x 1.25 base; 1.75 base x base; half of uncompressed.
    const px = (value: string) => parseFloat(value);
    const full = [px(light.size.xxl) + px(light.size.xs), px(light.size.base) * 1.25];
    assert.deepEqual(full, [44, 20], 'Borealis uncompressed switch is 44x20');
    const sizes = {
      off: full,
      on: full,
      compressed: [px(light.size.base) * 1.75, px(light.size.base)],
      mini: [full[0]! / 2, full[1]! / 2]
    } as Record<string, number[]>;
    for (const [name, [width = 0, height = 0]] of Object.entries(sizes)) {
      const button = box(root, `[data-test="${name}"]`);
      assert.deepEqual([button.width, button.height], [width, height], `${name}: ${width}x${height}`);
      assert.strictEqual(style(root, `[data-test="${name}"]`).borderTopLeftRadius, `${height}px`);
      // offset sizes ignore the thumb's scale() transform.
      const thumb = el(root, `[data-test="${name}"] .euiSwitch__thumb`);
      assert.deepEqual(
        [thumb.offsetWidth, thumb.offsetHeight],
        [height, height],
        `${name}: round thumb fills the height`
      );
      const expectedLeft = name === 'off' ? 0 : width - height;
      assert.strictEqual(
        style(root, `[data-test="${name}"] .euiSwitch__thumb`).insetInlineStart,
        `${expectedLeft}px`,
        `${name}: thumb position`
      );
    }
    assert.strictEqual(style(root, '[data-test="on"] .euiSwitch__body').backgroundColor, rgb(c.switchBackgroundOn));
    assert.strictEqual(style(root, '[data-test="off"] .euiSwitch__body').backgroundColor, rgb(c.switchBackgroundOff));
    assert.strictEqual(
      style(root, '[data-test="disabled"] .euiSwitch__body').backgroundColor,
      rgb(c.switchUncompressedBackgroundDisabled)
    );
    assert.strictEqual(
      style(root, '[data-test="disabled-mini"] .euiSwitch__body').backgroundColor,
      rgb(c.switchMiniBackgroundDisabled)
    );
    const thumb = style(root, '[data-test="off"] .euiSwitch__thumb');
    assert.strictEqual(thumb.backgroundColor, rgb(light.colors.emptyShade));
    assert.strictEqual(thumb.borderTopColor, rgb(c.switchThumbBorderOff));
    assert.strictEqual(style(root, '[data-test="on"] .euiSwitch__thumb').borderTopColor, rgb(c.switchThumbBorderOn));
    assert.strictEqual(
      style(root, '[data-test="disabled"] .euiSwitch__thumb').backgroundColor,
      rgb(c.switchThumbBackgroundDisabled)
    );
    assert.strictEqual(style(root, '[data-test="compressed"] .euiSwitch__thumb').transform, 'matrix(0.9, 0, 0, 0.9, 0, 0)');
    assert.strictEqual(style(root, '[data-test="mini"] .euiSwitch__thumb').transform, 'matrix(0.8, 0, 0, 0.8, 0, 0)');

    // Check/cross icons only in the uncompressed switch.
    assert.dom('[data-test="on"] .euiSwitch__icons svg').exists({ count: 2 });
    assert.dom('[data-test="compressed"] .euiSwitch__icons').doesNotExist();
    assert.dom('[data-test="mini"] .euiSwitch__icons').doesNotExist();
    assert.strictEqual(style(root, '[data-test="on"] .euiSwitch__icons').color, rgb(light.colors.emptyShade));
    assert.strictEqual(style(root, '[data-test="disabled"] .euiSwitch__icons').color, rgb(c.switchIconDisabled));
    assert.strictEqual(style(root, '[data-test="on"] .euiSwitch__icons').insetInlineStart, `${-0.25 * 44}px`);
    assert.strictEqual(style(root, '[data-test="off"] .euiSwitch__icons').insetInlineStart, `${-0.75 * 44}px`);

    // Labels: s (xs for mini), line height = switch height, disabled color.
    const label = (name: string) => style(root, `.euiSwitch:has([data-test="${name}"]) .euiSwitch__label`);
    assertFont(assert, label('on').fontSize, 14, 'label');
    assert.strictEqual(label('on').lineHeight, '20px');
    assert.strictEqual(label('compressed').lineHeight, '16px');
    assertFont(assert, label('mini').fontSize, 12, 'mini label');
    assert.strictEqual(label('mini').lineHeight, '10px');
    assert.strictEqual(label('on').paddingInlineStart, '8px');
    assert.strictEqual(label('disabled').color, rgb(light.colors.textDisabled));
    assert.strictEqual(style(root, '.euiSwitch:has([data-test="on"])').cursor, 'pointer');
    assert.strictEqual(style(root, '.euiSwitch:has([data-test="disabled"])').cursor, 'not-allowed');
    assert.strictEqual(style(root, '[data-test="on"]').backgroundColor, TRANSPARENT, 'button reset');
    assert.strictEqual(style(root, '[data-test="on"]').borderTopStyle, 'none');
    assert.dom('.euiSwitch--compressed').doesNotExist();
  });

  test('EuiSwitch behavior: role, aria, label click, activation, reactive args on the same element', async function (assert) {
    class State {
      @tracked checked = false;
      @tracked mini = false;
      @tracked disabled = false;
      onChange = (event: Event) => {
        this.checked = (event.target as HTMLInputElement).checked;
      };
    }
    const state = new State();
    const labelProps = { className: 'custom-label', id: 'my-label' };
    await render(
      <template>
        <EuiSwitch
          @label="Dark mode"
          @labelProps={{labelProps}}
          @checked={{state.checked}}
          @mini={{state.mini}}
          @disabled={{state.disabled}}
          @onChange={{state.onChange}}
          data-test="sw"
        />
        <EuiSwitch @label="Hidden" @showLabel={{false}} @checked={{true}} data-test="hidden" />
      </template>
    );
    const button = el(this.element, '[data-test="sw"]') as HTMLButtonElement;
    assert.dom(button).hasAttribute('role', 'switch').hasAttribute('aria-checked', 'false');
    assert.dom(button).hasAttribute('type', 'button').hasAttribute('aria-labelledby', 'my-label');
    assert.dom('#my-label').hasClass('euiSwitch__label').hasClass('custom-label').hasText('Dark mode');
    assert.dom('[data-test="hidden"]').hasAttribute('aria-label', 'Hidden').doesNotHaveAttribute('aria-labelledby');

    await click(button);
    finishTransitions();
    assert.true(state.checked);
    assert.dom(button).hasAttribute('aria-checked', 'true');
    assert.strictEqual(
      style(this.element, '[data-test="sw"] .euiSwitch__body').backgroundColor,
      rgb(light.components.switchBackgroundOn)
    );
    assert.strictEqual(style(this.element, '[data-test="sw"] .euiSwitch__thumb').insetInlineStart, '24px', 'thumb at 44 - 20');

    await click('#my-label');
    assert.false(state.checked, 'label click toggles');

    // Space/Enter on a focused button run its activation behavior (`click()`).
    await focus(button);
    assert.strictEqual(document.activeElement, button);
    button.click();
    await settled();
    assert.true(state.checked, 'activation toggles');

    if (button.matches(':focus-visible')) {
      assert.strictEqual(getComputedStyle(button).outlineStyle, 'auto', 'upstream focus ring');
    } else {
      assert.strictEqual(getComputedStyle(button).outlineStyle, 'none');
    }

    state.mini = true;
    await settled();
    finishTransitions();
    assert.strictEqual(el(this.element, '[data-test="sw"]'), button, 'button not replaced');
    assert.deepEqual([box(this.element, '[data-test="sw"]').width, box(this.element, '[data-test="sw"]').height], [22, 10]);
    assert.dom('[data-test="sw"] .euiSwitch__icons').doesNotExist();

    state.disabled = true;
    await settled();
    assert.dom(button).isDisabled();
    await click('#my-label');
    assert.true(state.checked, 'disabled label click is ignored');
    assert.strictEqual(
      style(this.element, '[data-test="sw"] .euiSwitch__body').backgroundColor,
      rgb(light.components.switchMiniBackgroundDisabled)
    );
  });

  test('light/dark follow the nearest provider with sibling isolation', async function (assert) {
    class State {
      @tracked mode: 'light' | 'dark' = 'dark';
    }
    const state = new State();
    await render(
      <template>
        <EuiEmotionProvider @colorMode={{state.mode}}>
          <EuiCheckbox @checked={{true}} @label="Dark" data-test="dark-cb" />
          <EuiRadio @label="Dark" data-test="dark-radio" />
          <EuiSwitch @label="Dark" @checked={{false}} data-test="dark-sw" />
          <EuiEmotionProvider @colorMode="light">
            <EuiCheckbox @checked={{true}} @label="Light" data-test="nested-cb" />
          </EuiEmotionProvider>
        </EuiEmotionProvider>
        <EuiEmotionProvider @colorMode="light">
          <EuiCheckbox @checked={{true}} @label="Sibling" data-test="sibling-cb" />
          <EuiSwitch @label="Sibling" @checked={{false}} data-test="sibling-sw" />
        </EuiEmotionProvider>
      </template>
    );
    finishTransitions();
    const root = this.element;
    assertControl(assert, controlStyle(root, 'dark-cb'), states(dark).selected, 'dark checked');
    assert.strictEqual(controlStyle(root, 'dark-cb').color, rgb(dark.colors.emptyShade));
    assertControl(assert, controlStyle(root, 'dark-radio'), states(dark).unselected, 'dark radio');
    assert.strictEqual(
      style(root, '[data-test="dark-sw"] .euiSwitch__body').backgroundColor,
      rgb(dark.components.switchBackgroundOff)
    );
    assert.strictEqual(
      style(root, '.euiSwitch:has([data-test="dark-sw"]) .euiSwitch__label').color,
      rgb(dark.colors.textParagraph),
      'label inherits the dark provider color'
    );
    assertControl(assert, controlStyle(root, 'nested-cb'), states(light).selected, 'nested light');
    assertControl(assert, controlStyle(root, 'sibling-cb'), states(light).selected, 'sibling light');
    assert.strictEqual(
      style(root, '[data-test="sibling-sw"] .euiSwitch__body').backgroundColor,
      rgb(light.components.switchBackgroundOff)
    );
    assert.notStrictEqual(rgb(dark.colors.primary), rgb(light.colors.primary), 'modes differ');

    state.mode = 'light';
    await settled();
    finishTransitions();
    assertControl(assert, controlStyle(root, 'dark-cb'), states(light).selected, 'switched to light');
  });

  test('native token overrides (JS objects) and high contrast reach every factory', async function (assert) {
    class State {
      @tracked overrides: EuiBorealisOverrides = {};
      @tracked contrast: EuiBorealisHighContrastMode = false;
    }
    const state = new State();
    await render(
      <template>
        <EuiEmotionProvider @borealisOverrides={{state.overrides}} @highContrastMode={{state.contrast}}>
          <EuiCheckbox @checked={{true}} @label="On" data-test="cb-on" />
          <EuiCheckbox @label="Off" data-test="cb-off" />
          <EuiRadio @label="Off" @disabled={{true}} data-test="radio-disabled" />
          <EuiSwitch @label="Off" @checked={{false}} data-test="sw-off" />
          <EuiSwitch @label="On" @checked={{true}} data-test="sw-on" />
          <EuiCheckboxGroup
            @options={{array}}
            @idToSelectedMap={{map}}
            @onChange={{noop}}
            data-test="group"
          />
        </EuiEmotionProvider>
        <EuiCheckbox @checked={{true}} @label="Outside" data-test="outside" />
      </template>
    );
    const root = this.element;

    state.overrides = {
      colors: { LIGHT: { primary: '#663399' } },
      size: { xs: '6px' }
    };
    await settled();
    finishTransitions();
    assertControl(assert, controlStyle(root, 'cb-on'), { background: '#663399', border: '#663399' }, 'primary override');
    assert.strictEqual(style(root, '[data-test="group"]').rowGap, '6px', 'size override');
    const overridden = resolveBorealisTheme('light', state.overrides).euiTheme;
    assert.strictEqual(
      style(root, '[data-test="sw-on"] .euiSwitch__body').backgroundColor,
      rgb(overridden.components.switchBackgroundOn),
      'switch on color resolves from the overridden theme'
    );
    assertControl(assert, controlStyle(root, 'outside'), states(light).selected, 'outside is isolated');

    state.overrides = {};
    state.contrast = 'preferred';
    await settled();
    finishTransitions();
    const hc = resolveBorealisTheme('light', {}, 'preferred').euiTheme;
    assertControl(assert, controlStyle(root, 'cb-off'), states(hc, true).unselected, 'high contrast unselected border');
    assertControl(assert, controlStyle(root, 'radio-disabled'), states(hc, true).disabled, 'high contrast disabled border');
    assert.strictEqual(
      style(root, '[data-test="sw-off"] .euiSwitch__body').backgroundColor,
      rgb(hc.colors.darkShade),
      'high contrast off track'
    );
    assert.strictEqual(
      style(root, '[data-test="sw-off"] .euiSwitch__thumb').borderTopColor,
      rgb(hc.border.color),
      'high contrast thumb border'
    );
    assert.strictEqual(
      style(root, '[data-test="sw-on"] .euiSwitch__thumb').borderTopColor,
      rgb(hc.border.color)
    );
    // The faux control always draws a border (Windows high contrast themes).
    assert.strictEqual(controlStyle(root, 'cb-off').borderTopStyle, 'solid');
  });

  test('RTL: labels sit on the inline end, padding and thumbs are logical', async function (assert) {
    await render(
      <template>
        <div dir="rtl">
          <EuiCheckbox @label="תווית" data-test="cb" />
          <EuiRadio @label="תווית" data-test="radio" />
          <EuiSwitch @label="תווית" @checked={{true}} data-test="sw-on" />
          <EuiSwitch @label="תווית" @checked={{false}} data-test="sw-off" />
        </div>
      </template>
    );
    finishTransitions();
    const root = this.element;
    for (const [name, host, control, label] of [
      ['cb', '.euiCheckbox', '.euiCheckbox__square', '.euiCheckbox__label'],
      ['radio', '.euiRadio', '.euiRadio__circle', '.euiRadio__label'],
      ['sw-on', '.euiSwitch', '.euiSwitch__button', '.euiSwitch__label']
    ] as const) {
      const scope = `${host}:has([data-test="${name}"])`;
      const c = box(root, `${scope} ${control}`);
      const l = box(root, `${scope} ${label}`);
      assert.true(l.right <= c.left + 0.5, `${name}: label is left of the control in RTL`);
      const labelStyle = style(root, `${scope} ${label}`);
      assert.strictEqual(labelStyle.paddingRight, '8px', `${name}: logical label gap`);
      assert.strictEqual(labelStyle.paddingLeft, '0px');
    }
    const on = box(root, '[data-test="sw-on"]');
    const onThumb = box(root, '[data-test="sw-on"] .euiSwitch__thumb');
    const offThumb = box(root, '[data-test="sw-off"] .euiSwitch__thumb');
    const off = box(root, '[data-test="sw-off"]');
    assert.true(Math.abs(onThumb.left - on.left) < 0.5, 'checked thumb at the inline end (left in RTL)');
    assert.true(Math.abs(offThumb.right - off.right) < 0.5, 'unchecked thumb at the inline start (right in RTL)');
  });
});
