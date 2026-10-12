import { tracked } from '@glimmer/tracking';
import {
  blur,
  clearRender,
  click,
  focus,
  render,
  settled,
  triggerEvent
} from '@ember/test-helpers';
import { setupRenderingTest } from 'ember-qunit';
import { module, test } from 'qunit';

import EuiButton from '#src/components/eui-button.gts';
import EuiCheckboxGroup from '#src/components/eui-checkbox-group.gts';
import EuiDescribedFormGroup from '#src/components/eui-described-form-group.gts';
import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import EuiFieldText from '#src/components/eui-field-text.gts';
import EuiForm from '#src/components/eui-form.gts';
import EuiFormErrorText from '#src/components/eui-form-error-text.gts';
import EuiFormFieldset from '#src/components/eui-form-fieldset.gts';
import EuiFormHelpText from '#src/components/eui-form-help-text.gts';
import EuiFormLabel from '#src/components/eui-form-label.gts';
import EuiFormLegend from '#src/components/eui-form-legend.gts';
import EuiFormRow from '#src/components/eui-form-row.gts';
import EuiTitle from '#src/components/eui-title.gts';
import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';

import type { EuiDescribedFormGroupRatio } from '#src/components/eui-described-form-group.gts';
import type { EuiFormRowDisplay } from '#src/components/eui-form-row.gts';
import type { EuiColorMode } from '#src/utils/emotion/theme.ts';
import type { EuiBorealisOverrides } from '#src/utils/eui/theme.ts';

const light = resolveBorealisTheme('light').euiTheme;
const dark = resolveBorealisTheme('dark').euiTheme;
const CHECKBOX_OPTIONS = [
  { id: 'layout-apple', label: 'Apple' },
  { id: 'layout-pear', label: 'Pear' }
];
const NO_CHECKS = {};
const ERRORS = ['Too short', 'Taken'];
const RATIOS: EuiDescribedFormGroupRatio[] = ['half', 'third', 'quarter'];
const noop = () => {};

function el(root: ParentNode, selector: string): HTMLElement {
  const element = root.querySelector<HTMLElement>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

function style(root: ParentNode, selector: string, pseudo?: string) {
  return getComputedStyle(el(root, selector), pseudo);
}

/** ember-qunit may scale #ember-testing; measure in layout pixels. */
function measure(element: Element) {
  const container = element.closest<HTMLElement>('#ember-testing');
  const factor =
    container && container.offsetWidth
      ? container.getBoundingClientRect().width / container.offsetWidth
      : 1;
  const box = element.getBoundingClientRect();
  return {
    left: box.left / factor,
    right: box.right / factor,
    top: box.top / factor,
    bottom: box.bottom / factor,
    width: box.width / factor,
    height: box.height / factor
  };
}

function rect(root: ParentNode, selector: string) {
  return measure(el(root, selector));
}

/**
 * Labels transition their color (upstream `euiCanAnimate`); finish running
 * transitions so a reactive change is read at its end value.
 */
function settledStyle(root: ParentNode, selector: string) {
  const element = el(root, selector);
  element.getAnimations({ subtree: true }).forEach((animation) => animation.finish());
  return getComputedStyle(element);
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

function px(value: string) {
  return parseFloat(value);
}

function near(
  assert: Assert,
  actual: number,
  expected: number,
  message: string,
  tolerance = 0.6
) {
  assert.true(
    Math.abs(actual - expected) <= tolerance,
    `${message} (expected ${expected}, got ${actual})`
  );
}

/** WCAG relative luminance contrast of two computed `rgb()` colors. */
function contrast(a: string, b: string) {
  const lum = (color: string) => {
    const [r, g, bl] = color
      .match(/\d+(\.\d+)?/g)!
      .slice(0, 3)
      .map((c) => {
        const v = Number(c) / 255;
        return v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4;
      });
    return 0.2126 * r! + 0.7152 * g! + 0.0722 * bl!;
  };
  const [hi, lo] = [lum(a), lum(b)].sort((x, y) => y - x);
  return (hi! + 0.05) / (lo! + 0.05);
}

/**
 * Copies the rendered markup and every stylesheet rule (including Emotion's
 * inserted rules) into an iframe of the given width, so media queries are
 * evaluated against a real narrow viewport.
 */
function inViewport(width: number, html: string) {
  const iframe = document.createElement('iframe');
  iframe.style.cssText = `position:fixed;top:0;left:0;width:${width}px;height:800px;border:0;visibility:hidden`;
  document.body.appendChild(iframe);
  const css = Array.from(document.styleSheets)
    .map((sheet) => {
      try {
        return Array.from(sheet.cssRules)
          .map((rule) => rule.cssText)
          .join('\n');
      } catch {
        return '';
      }
    })
    .join('\n');
  const doc = iframe.contentDocument!;
  doc.open();
  doc.write(
    `<!doctype html><html><head><style>${css}</style></head><body style="margin:0">${html}</body></html>`
  );
  doc.close();
  const win = iframe.contentWindow!;
  return {
    matches: (query: string) => win.matchMedia(query).matches,
    rect: (selector: string) => el(doc, selector).getBoundingClientRect(),
    remove: () => iframe.remove()
  };
}

module('Integration | Component | Borealis form layout', function (hooks) {
  setupRenderingTest(hooks);

  test('row display: column stack, xs gap, form max width, sibling and button spacing', async function (assert) {
    await render(
      <template>
        <div style="width: 900px">
          <EuiFormRow @label="First" @labelAppend="Optional" data-first>
            <EuiFieldText />
          </EuiFormRow>
          <EuiFormRow @label="Second" @display="rowCompressed" data-second>
            <EuiFieldText />
          </EuiFormRow>
          <EuiButton data-button>Save</EuiButton>
          <EuiFormRow @label="Wide" @fullWidth={{true}} data-wide>
            <EuiFieldText @fullWidth={{true}} />
          </EuiFormRow>
        </div>
      </template>
    );

    const first = style(this.element, '[data-first]');
    assert.strictEqual(first.display, 'flex');
    assert.strictEqual(first.flexDirection, 'column');
    assert.strictEqual(first.rowGap, light.size.xs, 'label to field gap is size.xs');
    assert.strictEqual(first.maxWidth, light.components.forms.maxWidth);
    near(
      assert,
      rect(this.element, '[data-first]').width,
      px(light.components.forms.maxWidth),
      'rows are capped at the form max width'
    );
    const wrapper = style(this.element, '[data-first] .euiFormRow__labelWrapper');
    assert.strictEqual(wrapper.display, 'flex');
    assert.strictEqual(wrapper.justifyContent, 'space-between');
    assert.strictEqual(wrapper.flexWrap, 'wrap');
    near(
      assert,
      rect(this.element, '[data-first] .euiFormRow__labelAppend').right,
      rect(this.element, '[data-first]').right,
      'label append sits at the end of the label line'
    );
    near(
      assert,
      rect(this.element, '[data-first] .euiFormRow__fieldWrapper').top -
        rect(this.element, '[data-first] .euiFormRow__labelWrapper').bottom,
      px(light.size.xs),
      'measured gap between label and field'
    );

    assert.strictEqual(first.marginTop, '0px', 'first row has no top margin');
    const second = style(this.element, '[data-second]');
    assert.strictEqual(second.marginTop, light.size.base, 'row + row is size.base');
    assert.strictEqual(second.rowGap, first.rowGap, 'rowCompressed looks like row');
    assert.strictEqual(second.flexDirection, 'column');
    assert.strictEqual(
      style(this.element, '[data-button]').marginTop,
      light.size.base,
      'row + button gets size.base'
    );

    const wide = style(this.element, '[data-wide]');
    assert.strictEqual(wide.maxWidth, '100%');
    near(assert, rect(this.element, '[data-wide]').width, 900, 'fullWidth fills its container');
    assert.strictEqual(wide.marginTop, '0px', 'a button between rows breaks the sibling rule');
  });

  test('columnCompressed display: label beside the field, compressed line height, s spacing, switches', async function (assert) {
    const displays: EuiFormRowDisplay[] = ['columnCompressed', 'columnCompressedSwitch'];
    await render(
      <template>
        <div dir="ltr" style="width: 400px">
          {{#each displays as |display|}}
            <EuiFormRow @label="A fairly long label" @display={{display}} data-display={{display}}>
              <EuiFieldText @compressed={{true}} />
            </EuiFormRow>
          {{/each}}
          <EuiFormRow @label="Switch" @display="columnCompressed" data-switch>
            <span class="euiSwitch">switch</span>
          </EuiFormRow>
          <EuiFormRow @label="After" @display="columnCompressed" data-after>
            <EuiFieldText @compressed={{true}} />
          </EuiFormRow>
        </div>
        <div dir="rtl" style="width: 400px">
          <EuiFormRow @label="RTL" @display="columnCompressed" data-rtl>
            <EuiFieldText @compressed={{true}} />
          </EuiFormRow>
        </div>
      </template>
    );

    const row = style(this.element, '[data-display="columnCompressed"]');
    assert.strictEqual(row.flexDirection, 'row');
    assert.strictEqual(row.alignItems, 'stretch');
    assert.strictEqual(row.columnGap, light.size.s);
    const label = style(this.element, '[data-display="columnCompressed"] .euiFormRow__labelWrapper');
    assert.strictEqual(label.lineHeight, light.size.xl, 'label line height is the compressed control height');
    assert.strictEqual(label.minWidth, '0px');
    assert.strictEqual(
      style(this.element, '[data-display="columnCompressed"] .euiFormRow__label').hyphens,
      'auto'
    );
    assert.strictEqual(
      style(this.element, '[data-display="columnCompressed"] .euiFormRow__fieldWrapper').flexBasis,
      '67%'
    );
    const labelBox = rect(this.element, '[data-display="columnCompressed"] .euiFormRow__labelWrapper');
    const fieldBox = rect(this.element, '[data-display="columnCompressed"] .euiFormRow__fieldWrapper');
    near(assert, fieldBox.left - labelBox.right, px(light.size.s), 'label then field, s apart (LTR)');
    near(assert, labelBox.top, fieldBox.top, 'same line');
    near(assert, labelBox.width, 400 * 0.33 - px(light.size.s), 'label column is 33% - s');

    const alias = style(this.element, '[data-display="columnCompressedSwitch"]');
    assert.strictEqual(alias.flexDirection, 'row', 'columnCompressedSwitch is an alias');
    assert.strictEqual(alias.columnGap, row.columnGap);
    assert.strictEqual(alias.marginTop, light.size.s, 'column rows are s apart');

    const withSwitch = style(this.element, '[data-switch]');
    assert.strictEqual(withSwitch.marginTop, light.size.m, 'rows containing a switch get m around them');
    assert.strictEqual(withSwitch.marginBottom, light.size.m);
    assert.strictEqual(
      style(this.element, '[data-switch] .euiFormRow__labelWrapper').lineHeight,
      light.size.base,
      'switch rows use a base line height'
    );

    const rtlLabel = rect(this.element, '[data-rtl] .euiFormRow__labelWrapper');
    const rtlField = rect(this.element, '[data-rtl] .euiFormRow__fieldWrapper');
    near(assert, rtlLabel.left - rtlField.right, px(light.size.s), 'RTL puts the label on the right');
  });

  test('center displays vertically center short content at control heights', async function (assert) {
    await render(
      <template>
        <EuiFormRow @display="center" data-center><span class="short">short</span></EuiFormRow>
        <EuiFormRow @display="centerCompressed" data-compressed><span class="short">short</span></EuiFormRow>
        <EuiFormRow @label="Labelled" @display="center" data-labelled><span>content</span></EuiFormRow>
      </template>
    );

    for (const [selector, height] of [
      ['[data-center]', light.size.xxl],
      ['[data-compressed]', light.size.xl]
    ] as const) {
      const wrapper = style(this.element, `${selector} .euiFormRow__fieldWrapper`);
      assert.strictEqual(wrapper.display, 'flex', `${selector} field wrapper is flex`);
      assert.strictEqual(wrapper.alignItems, 'center');
      assert.strictEqual(wrapper.minHeight, height, `${selector} min height`);
      const box = rect(this.element, `${selector} .euiFormRow__fieldWrapper`);
      const content = rect(this.element, `${selector} .short`);
      near(
        assert,
        content.top - box.top,
        box.bottom - content.bottom,
        `${selector} content is vertically centered`
      );
      assert.strictEqual(style(this.element, selector).flexDirection, 'column', 'center keeps the row stack');
    }
    assert.dom('.euiFormRow__fieldWrapperDisplayOnly').doesNotExist('legacy class is gone');
    assert.strictEqual(
      style(this.element, '[data-labelled]').marginTop,
      light.size.base,
      'center rows keep the sibling spacing'
    );
  });

  test('labels: title xxxs typography, semibold, heading color, pointer only with for', async function (assert) {
    await render(
      <template>
        <EuiTitle @size="xxxs" data-title>Reference</EuiTitle>
        <EuiFormLabel @for="x" data-for>For</EuiFormLabel>
        <EuiFormLabel data-plain>Plain</EuiFormLabel>
        <EuiFormLabel @for="x" @isDisabled={{true}} data-disabled>Disabled</EuiFormLabel>
        <EuiFormLabel @for="x" @isInvalid={{true}} data-invalid>Invalid</EuiFormLabel>
        <EuiFormLabel @type="legend" data-legend>Legend</EuiFormLabel>
        <input id="x" />
      </template>
    );

    const title = style(this.element, '[data-title]');
    const label = style(this.element, '[data-for]');
    assert.strictEqual(label.fontSize, title.fontSize, 'xxxs title font size');
    assert.strictEqual(label.lineHeight, title.lineHeight, 'xxxs title line height');
    assert.strictEqual(label.letterSpacing, title.letterSpacing);
    assert.strictEqual(label.fontWeight, String(light.font.weight.semiBold));
    assert.strictEqual(label.color, rgb(light.colors.textHeading));
    assert.strictEqual(label.display, 'inline-block');
    assert.true(label.fontFamily.includes('Inter'), 'scoped reset supplies the Borealis font');
    assert.strictEqual(label.cursor, 'pointer', 'labels pointing at a control are clickable');
    // (Chromium's UA sheet gives labels `cursor: default`)
    assert.notStrictEqual(style(this.element, '[data-plain]').cursor, 'pointer', 'no pointer without for');
    assert.notStrictEqual(style(this.element, '[data-disabled]').cursor, 'pointer', 'no pointer when disabled');
    assert.dom('[data-disabled]').hasClass('euiFormLabel-isDisabled');
    assert.strictEqual(style(this.element, '[data-invalid]').color, rgb(light.colors.textDanger));
    assert.dom('[data-invalid]').hasClass('euiFormLabel-isInvalid');
    const legend = style(this.element, '[data-legend]');
    assert.dom('[data-legend]').hasTagName('legend');
    assert.strictEqual(legend.fontSize, label.fontSize);
    assert.strictEqual(legend.paddingLeft, '0px', 'browser legend padding is reset');
    assert.true(
      contrast(label.color, rgb(light.colors.emptyShade)) >= 4.5,
      'label text meets AA contrast on the page background'
    );
  });

  test('help and error text: xs size, xs padding, subdued and danger colors', async function (assert) {
    await render(
      <template>
        <EuiTitle @size="xxxs" data-title>Reference</EuiTitle>
        <EuiFormHelpText @id="help" data-help>Help</EuiFormHelpText>
        <EuiFormErrorText data-error>Error</EuiFormErrorText>
      </template>
    );

    const title = style(this.element, '[data-title]');
    for (const [selector, color] of [
      ['[data-help]', light.colors.darkShade],
      ['[data-error]', light.colors.textDanger]
    ] as const) {
      const text = style(this.element, selector);
      assert.strictEqual(text.fontSize, title.fontSize, `${selector} xs font size`);
      assert.strictEqual(text.lineHeight, title.lineHeight, `${selector} xs line height`);
      assert.strictEqual(text.paddingTop, light.size.xs);
      assert.strictEqual(text.color, rgb(color));
      assert.true(
        contrast(text.color, rgb(light.colors.emptyShade)) >= 4.5,
        `${selector} meets AA contrast`
      );
    }
    assert.dom('[data-help]').hasAttribute('id', 'help').hasClass('euiFormHelpText');
    assert.dom('[data-error]').hasAttribute('aria-live', 'polite').hasClass('euiFormErrorText');
  });

  test('row accessibility: ids, label for, describedby, invalid and focus states', async function (assert) {
    await render(
      <template>
        <EuiFormRow
          @id="acc"
          @label="Account"
          @helpText="Help line"
          @isInvalid={{true}}
          @error={{ERRORS}}
          data-row
        >
          <EuiFieldText />
        </EuiFormRow>
        <EuiFormRow @id="multi" @label="Multi" @helpText={{ERRORS}} data-multi>
          <EuiFieldText />
        </EuiFormRow>
        <EuiFormRow @id="off" @label="Off" @isDisabled={{true}} data-disabled>
          <EuiFieldText @disabled={{true}} />
        </EuiFormRow>
      </template>
    );

    const input = el(this.element, '[data-row] input');
    assert.dom('[data-row]').hasAttribute('id', 'acc-row').hasClass('euiFormRow--hasLabel');
    assert
      .dom('[data-row] label.euiFormRow__label')
      .hasAttribute('id', 'acc-label')
      .hasAttribute('for', input.id)
      .hasAria('invalid', 'true')
      .hasClass('euiFormLabel-isInvalid');
    assert.dom('[data-row] .euiFormErrorText').exists({ count: 2 });
    assert.dom('#acc-error-0').hasText('Too short').hasClass('euiFormRow__text');
    assert.dom('#acc-error-1').hasText('Taken');
    assert.dom('#acc-help-0').hasText('Help line').hasClass('euiFormRow__text');
    assert.dom(input).hasAria('describedby', 'acc-error-0 acc-error-1 acc-help-0');
    assert.strictEqual(
      style(this.element, '[data-row] .euiFormRow__label').color,
      rgb(light.colors.textDanger),
      'invalid label is danger colored'
    );
    assert.dom('[data-multi] .euiFormHelpText').exists({ count: 2 });
    assert.dom('[data-multi] input').hasAria('describedby', 'multi-help-0 multi-help-1');

    const before = style(this.element, '[data-multi] .euiFormRow__label').color;
    await focus('[data-multi] input');
    assert.dom('[data-multi] .euiFormRow__label').hasClass('euiFormLabel-isFocused');
    assert.strictEqual(
      style(this.element, '[data-multi] .euiFormRow__label').color,
      before,
      'Borealis does not recolor focused labels'
    );
    await blur('[data-multi] input');
    assert.dom('[data-multi] .euiFormRow__label').doesNotHaveClass('euiFormLabel-isFocused');

    assert.dom('[data-disabled] .euiFormRow__label').hasClass('euiFormLabel-isDisabled');
    assert.notStrictEqual(style(this.element, '[data-disabled] .euiFormRow__label').cursor, 'pointer');
    await triggerEvent('[data-disabled] .euiFormRow__fieldWrapper', 'focusin');
    assert.dom('[data-disabled] .euiFormRow__label').doesNotHaveClass('euiFormLabel-isFocused');

    await click('[data-row] label');
    assert.strictEqual(document.activeElement, input, 'clicking the label focuses the field');
  });

  test('row label variants: append, empty label space, child label, fieldset legend', async function (assert) {
    await render(
      <template>
        <EuiFormRow @label="Name" @labelAppend="Optional" data-append><EuiFieldText /></EuiFormRow>
        <EuiFormRow @label="Name" data-block>
          <:labelAppend><a href="#h" class="help">Help</a></:labelAppend>
          <:field><EuiFieldText /></:field>
        </EuiFormRow>
        <EuiFormRow @hasEmptyLabelSpace={{true}} data-empty><EuiButton>Go</EuiButton></EuiFormRow>
        <EuiFormRow @label="Self" @hasChildLabel={{false}} data-child><EuiFieldText @id="self" /></EuiFormRow>
        <EuiFormRow @id="fs" @label="Fruits" @labelType="legend" @legendType="legend" @helpText="Pick" data-fieldset>
          <EuiCheckboxGroup @options={{CHECKBOX_OPTIONS}} @idToSelectedMap={{NO_CHECKS}} @onChange={{noop}} />
        </EuiFormRow>
        <EuiFormRow data-nolabel><EuiFieldText /></EuiFormRow>
      </template>
    );

    const append = style(this.element, '[data-append] .euiFormRow__labelAppend');
    assert.dom('[data-append] .euiFormRow__labelAppend').hasClass('euiFormLabelAppend').hasTagName('span');
    assert.strictEqual(append.color, rgb(light.colors.textSubdued));
    assert.strictEqual(append.fontSize, style(this.element, '[data-append] label').fontSize, 'xs text');
    assert.dom('[data-block] .euiFormRow__labelAppend.euiText a.help').exists('block content is wrapped in xs EuiText');
    assert.strictEqual(
      style(this.element, '[data-block] .euiFormRow__labelAppend').fontSize,
      append.fontSize
    );

    assert.dom('[data-empty]').hasClass('euiFormRow--hasEmptyLabelSpace').doesNotHaveClass('euiFormRow--hasLabel');
    near(
      assert,
      rect(this.element, '[data-empty] .euiFormRow__labelWrapper').height,
      px(light.size.base),
      'empty label space is an m spacer'
    );
    assert.dom('[data-empty] .euiFormRow__labelWrapper label').doesNotExist();

    assert.dom('[data-child] label').doesNotHaveAttribute('for');
    assert.notStrictEqual(style(this.element, '[data-child] label').cursor, 'pointer');

    assert.dom('[data-fieldset]').hasTagName('fieldset').hasAria('describedby', 'fs-help');
    assert.dom('[data-fieldset] legend.euiFormRow__label').hasText('Fruits').doesNotHaveAttribute('for');
    assert.dom('[data-fieldset] #fs-help').exists('fieldset rows keep the single -help id');
    const fieldset = style(this.element, '[data-fieldset]');
    assert.strictEqual(fieldset.borderTopStyle, 'none', 'fieldset border reset');
    assert.strictEqual(fieldset.paddingTop, '0px');
    assert.strictEqual(fieldset.marginLeft, '0px');
    assert.strictEqual(fieldset.display, 'flex');
    assert.strictEqual(fieldset.maxWidth, light.components.forms.maxWidth);

    assert.dom('[data-nolabel] .euiFormRow__labelWrapper').doesNotExist();
    assert.dom('[data-nolabel]').doesNotHaveClass('euiFormRow--hasLabel');
  });

  test('fieldset and legend: reset box, s / xs spacing, hidden legend', async function (assert) {
    class State {
      @tracked compressed = false;
    }
    const state = new State();
    await render(
      <template>
        <EuiFormFieldset @legend="Visible" @compressed={{state.compressed}} data-fieldset>
          <span class="inside">inside</span>
        </EuiFormFieldset>
        <EuiFormFieldset data-hidden-fs @display="hidden">
          <:legend>Hidden legend</:legend>
          <:fieldset><span>controls</span></:fieldset>
        </EuiFormFieldset>
        <EuiFormLegend data-legend>Standalone</EuiFormLegend>
        <EuiFormLabel data-label>Label</EuiFormLabel>
      </template>
    );

    const fieldset = style(this.element, '[data-fieldset]');
    assert.strictEqual(fieldset.borderTopStyle, 'none');
    assert.strictEqual(fieldset.paddingTop, '0px');
    assert.strictEqual(fieldset.marginTop, '0px');
    assert.notStrictEqual(fieldset.minInlineSize, 'min-content', 'UA min-content width is reset');

    const legendEl = el(this.element, '[data-fieldset] legend');
    const legend = getComputedStyle(legendEl);
    assert.dom(legendEl).hasClass('euiFormLegend').hasText('Visible');
    assert.strictEqual(legend.marginBottom, light.size.s, 'uncompressed legends have s below');
    assert.strictEqual(legend.fontSize, style(this.element, '[data-label]').fontSize, 'label typography');
    assert.strictEqual(legend.fontWeight, String(light.font.weight.semiBold));
    assert.strictEqual(legend.color, rgb(light.colors.textHeading));
    near(
      assert,
      rect(this.element, '[data-fieldset] .inside').top - measure(legendEl).bottom,
      px(light.size.s),
      'content starts s below the legend'
    );

    state.compressed = true;
    await settled();
    assert.strictEqual(el(this.element, '[data-fieldset] legend'), legendEl, 'legend is not replaced');
    assert.strictEqual(getComputedStyle(legendEl).marginBottom, light.size.xs, 'compressed legends have xs below');
    assert.dom(legendEl).doesNotHaveClass('euiFormLegend--compressed', 'no legacy modifier');

    assert.dom('[data-hidden-fs] legend').hasClass('euiFormLegend-isHidden');
    assert.dom('[data-hidden-fs] legend .euiScreenReaderOnly').hasText('Hidden legend');
    assert.strictEqual(style(this.element, '[data-hidden-fs] legend').marginBottom, '0px', 'hidden legends take no space');
    assert.ok(rect(this.element, '[data-hidden-fs] legend .euiScreenReaderOnly').width <= 1, 'visually hidden');
    assert.strictEqual(style(this.element, '[data-legend]').marginBottom, light.size.s);
  });

  test('described form group: layout, ratios, title/description styles and naming', async function (assert) {
    await render(
      <template>
        <div style="width: 1200px">
          <EuiDescribedFormGroup data-default>
            <:title>Settings</:title>
            <:description><p>Configure things</p></:description>
            <:default>
              <EuiFormRow @label="Name"><EuiFieldText /></EuiFormRow>
            </:default>
          </EuiDescribedFormGroup>
          <span data-sibling>after</span>
          {{#each RATIOS as |ratio|}}
            <EuiDescribedFormGroup @ratio={{ratio}} @fullWidth={{true}} data-ratio={{ratio}} style="width: 1000px">
              <:title>{{ratio}}</:title>
              <:default><EuiFormRow><EuiFieldText /></EuiFormRow></:default>
            </EuiDescribedFormGroup>
          {{/each}}
          <EuiDescribedFormGroup aria-label="Own label" data-aria-label>
            <:title>Ignored</:title>
            <:default><EuiFormRow><EuiFieldText /></EuiFormRow></:default>
          </EuiDescribedFormGroup>
          <EuiDescribedFormGroup aria-labelledby="custom-title" data-aria-labelledby>
            <:title>Ignored</:title>
            <:default><EuiFormRow><EuiFieldText /></EuiFormRow></:default>
          </EuiDescribedFormGroup>
          <EuiDescribedFormGroup @titleSize="s" @titleTagName="h3" @gutterSize="s" data-custom>
            <:title>Custom</:title>
            <:default><EuiFormRow @hasEmptyLabelSpace={{true}}><EuiFieldText /></EuiFormRow></:default>
          </EuiDescribedFormGroup>
          <EuiTitle @size="xs" data-ref-xs>Reference</EuiTitle>
          <EuiTitle @size="s" data-ref-s>Reference</EuiTitle>
        </div>
      </template>
    );

    const root = el(this.element, '[data-default]');
    const titleEl = el(root, '.euiDescribedFormGroup__title');
    assert.dom(root).hasAttribute('role', 'group');
    assert.ok(titleEl.id.startsWith('euiDescribedFormGroupTitle-'), 'generated title id');
    assert.dom(root).hasAria('labelledby', titleEl.id, 'the title names the group');
    assert.strictEqual(getComputedStyle(root).maxWidth, `${px(light.components.forms.maxWidth) * 2}px`);
    near(assert, measure(root).width, px(light.components.forms.maxWidth) * 2, 'group width');
    assert.strictEqual(
      style(this.element, '[data-sibling]').marginTop,
      light.size.l,
      'the next sibling is l below'
    );

    const group = style(root, '.euiFlexGroup');
    assert.strictEqual(group.alignItems, 'baseline');
    assert.strictEqual(group.columnGap, light.size.l, 'default gutter l');
    const descColumn = rect(root, '.euiDescribedFormGroup__descriptionColumn');
    const fieldColumn = rect(root, '.euiDescribedFormGroup__fields');
    near(assert, fieldColumn.left - descColumn.right, px(light.size.l), 'description then fields');
    near(assert, descColumn.width, fieldColumn.width, 'half ratio: equal columns');

    const title = getComputedStyle(titleEl);
    assert.strictEqual(titleEl.tagName, 'H2');
    assert.strictEqual(title.fontSize, style(this.element, '[data-ref-xs]').fontSize, 'title defaults to xs');
    const description = style(root, '.euiDescribedFormGroup__description');
    assert.strictEqual(description.paddingTop, light.size.s);
    assert.strictEqual(description.color, rgb(light.colors.textSubdued));
    assert.strictEqual(
      style(root, '.euiDescribedFormGroup__fields > .euiFormRow:first-child', '::before').content,
      'none',
      'labelled first rows need no anchor'
    );
    assert.strictEqual(
      style(this.element, '[data-ratio="half"] .euiDescribedFormGroup__fields > .euiFormRow:first-child', '::before').content,
      '""',
      'unlabelled first rows get a baseline anchor'
    );

    for (const [ratio, grow] of [['half', 1], ['third', 2], ['quarter', 3]] as const) {
      const box = el(this.element, `[data-ratio="${ratio}"]`);
      assert.strictEqual(getComputedStyle(box).maxWidth, '100%', `${ratio}: fullWidth`);
      const fields = style(box, '.euiDescribedFormGroup__fields');
      assert.strictEqual(fields.flexGrow, String(grow), `${ratio}: field grow ${grow}`);
      const desc = rect(box, '.euiDescribedFormGroup__descriptionColumn').width;
      const field = rect(box, '.euiDescribedFormGroup__fields').width;
      if (ratio === 'quarter') {
        near(assert, desc, 20 * px(getComputedStyle(document.documentElement).fontSize), 'quarter: description keeps its 20rem minimum');
      } else {
        near(assert, field / desc, grow, `${ratio}: field/description ratio`, 0.02);
      }
    }

    assert.dom('[data-aria-label]').hasAria('label', 'Own label').doesNotHaveAttribute('aria-labelledby');
    assert.dom('[data-aria-labelledby]').hasAria('labelledby', 'custom-title');

    const custom = el(this.element, '[data-custom]');
    assert.dom('.euiDescribedFormGroup__title', custom).hasTagName('h3');
    assert.strictEqual(style(custom, '.euiDescribedFormGroup__title').fontSize, style(this.element, '[data-ref-s]').fontSize);
    assert.strictEqual(style(custom, '.euiFlexGroup').columnGap, light.size.s);
    assert.strictEqual(style(custom, '.euiFormRow--hasEmptyLabelSpace').marginTop, '0px');
    assert.dom('.euiDescribedFormGroup__description', custom).doesNotExist('no empty description');
  });

  test('described form group collapses below the m breakpoint', async function (assert) {
    await render(
      <template>
        <EuiDescribedFormGroup @fullWidth={{true}} data-group>
          <:title>Title</:title>
          <:description>Text</:description>
          <:default><EuiFormRow @fullWidth={{true}}><EuiFieldText /></EuiFormRow></:default>
        </EuiDescribedFormGroup>
      </template>
    );

    const html = el(this.element, '[data-group]').outerHTML;
    const narrow = inViewport(light.breakpoint.m - 1, html);
    const wide = inViewport(light.breakpoint.m, html);
    try {
      const query = `(max-width: ${light.breakpoint.m - 1}px)`;
      assert.true(narrow.matches(query));
      assert.false(wide.matches(query));
      const nDesc = narrow.rect('.euiDescribedFormGroup__descriptionColumn');
      const nFields = narrow.rect('.euiDescribedFormGroup__fields');
      near(assert, nDesc.width, light.breakpoint.m - 1, 'narrow: description is full width');
      near(assert, nFields.width, light.breakpoint.m - 1, 'narrow: fields are full width');
      assert.true(nFields.top >= nDesc.bottom, 'narrow: fields stack under the description');
      const wDesc = wide.rect('.euiDescribedFormGroup__descriptionColumn');
      const wFields = wide.rect('.euiDescribedFormGroup__fields');
      assert.true(wFields.left > wDesc.right, 'wide: fields to the right');
      assert.true(wFields.top < wDesc.bottom, 'wide: side by side');
    } finally {
      narrow.remove();
      wide.remove();
    }
  });

  test('EuiForm: fullWidth context, error callout list and spacing', async function (assert) {
    class State {
      @tracked fullWidth = true;
    }
    const state = new State();
    await render(
      <template>
        <div style="width: 1000px">
          <EuiForm @tagName="form" @fullWidth={{state.fullWidth}} @isInvalid={{true}} @error={{ERRORS}} data-form>
            <EuiFormRow @label="Inherits" data-inherits><EuiFieldText /></EuiFormRow>
            <EuiFormRow @label="Own" @fullWidth={{false}} data-own><EuiFieldText /></EuiFormRow>
            <EuiDescribedFormGroup data-group><:title>G</:title><:default>x</:default></EuiDescribedFormGroup>
          </EuiForm>
          <EuiFormRow @label="Outside" data-outside><EuiFieldText /></EuiFormRow>
        </div>
      </template>
    );

    assert.dom('form[data-form].euiForm').exists();
    assert.dom('.euiForm__errors').hasAttribute('role', 'alert').hasAria('live', 'assertive');
    assert.dom('.euiForm__errors ul > li.euiForm__error').exists({ count: 2 });
    assert.dom('.euiForm__errors + .euiBorealisSpacer').exists('an m spacer follows the callout');
    near(assert, rect(this.element, '.euiForm__errors + .euiBorealisSpacer').height, px(light.size.base), 'spacer height');

    const inherits = el(this.element, '[data-inherits]');
    assert.strictEqual(getComputedStyle(inherits).maxWidth, '100%', 'rows inherit the form fullWidth');
    assert.strictEqual(style(this.element, '[data-own]').maxWidth, light.components.forms.maxWidth, 'own @fullWidth wins');
    assert.strictEqual(style(this.element, '[data-group]').maxWidth, '100%', 'groups inherit too');
    assert.strictEqual(style(this.element, '[data-outside]').maxWidth, light.components.forms.maxWidth, 'rows outside are unaffected');

    state.fullWidth = false;
    await settled();
    assert.strictEqual(el(this.element, '[data-inherits]'), inherits, 'row is not replaced');
    assert.strictEqual(getComputedStyle(inherits).maxWidth, light.components.forms.maxWidth, 'context changes are tracked');
  });

  test('reactive args update rows in place', async function (assert) {
    class State {
      @tracked display: EuiFormRowDisplay = 'row';
      @tracked fullWidth = false;
      @tracked isInvalid = false;
      @tracked label = 'First';
      @tracked helpText = 'Help';
    }
    const state = new State();
    await render(
      <template>
        <EuiFormRow
          @id="re"
          @label={{state.label}}
          @display={{state.display}}
          @fullWidth={{state.fullWidth}}
          @isInvalid={{state.isInvalid}}
          @error="Bad"
          @helpText={{state.helpText}}
          data-row
        >
          <EuiFieldText />
        </EuiFormRow>
      </template>
    );

    const row = el(this.element, '[data-row]');
    const label = el(row, 'label');
    const input = el(row, 'input');

    state.display = 'columnCompressed';
    await settled();
    assert.strictEqual(getComputedStyle(row).flexDirection, 'row');
    state.display = 'centerCompressed';
    await settled();
    assert.strictEqual(getComputedStyle(row).flexDirection, 'column');
    assert.strictEqual(style(row, '.euiFormRow__fieldWrapper').minHeight, light.size.xl);

    state.fullWidth = true;
    await settled();
    assert.strictEqual(getComputedStyle(row).maxWidth, '100%');

    state.isInvalid = true;
    state.label = 'Renamed';
    await settled();
    assert.strictEqual(settledStyle(row, 'label').color, rgb(light.colors.textDanger));
    assert.dom(label).hasText('Renamed').hasAria('invalid', 'true');
    assert.dom(input).hasAria('describedby', 're-error-0 re-help-0');

    state.isInvalid = false;
    state.helpText = 'Other help';
    await settled();
    assert.strictEqual(settledStyle(row, 'label').color, rgb(light.colors.textHeading));
    assert.dom(input).hasAria('describedby', 're-help-0');
    assert.dom('#re-help-0').hasText('Other help');

    assert.strictEqual(el(this.element, '[data-row]'), row, 'row element kept');
    assert.strictEqual(el(row, 'label'), label, 'label element kept');
    assert.strictEqual(el(row, 'input'), input, 'field element kept');

    await clearRender();
    assert.dom('[data-row]').doesNotExist();
  });

  test('light/dark follow the nearest provider with sibling isolation', async function (assert) {
    class State {
      @tracked mode: EuiColorMode = 'dark';
    }
    const state = new State();
    await render(
      <template>
        <EuiEmotionProvider @colorMode="light">
          <EuiFormRow @label="L" @helpText="h" @isInvalid={{true}} @error="e" data-light>
            <EuiFieldText />
          </EuiFormRow>
          <EuiFormRow @label="L2" @labelAppend="opt" data-light-valid><EuiFieldText /></EuiFormRow>
          <EuiEmotionProvider @colorMode={{state.mode}}>
            <EuiFormRow @label="D" @helpText="h" @isInvalid={{true}} @error="e" data-dark>
              <EuiFieldText />
            </EuiFormRow>
            <EuiFormRow @label="D2" @labelAppend="opt" data-dark-valid><EuiFieldText /></EuiFormRow>
            <EuiDescribedFormGroup data-dark-group>
              <:title>T</:title>
              <:description>Desc</:description>
              <:default>x</:default>
            </EuiDescribedFormGroup>
            <EuiFormFieldset @legend="Legend" data-dark-fieldset>x</EuiFormFieldset>
          </EuiEmotionProvider>
        </EuiEmotionProvider>
      </template>
    );

    const expectations = [
      ['light', light],
      ['dark', dark]
    ] as const;
    for (const [name, theme] of expectations) {
      const selector = `[data-${name}]`;
      assert.strictEqual(style(this.element, `${selector} .euiFormRow__label`).color, rgb(theme.colors.textDanger), `${selector} invalid label`);
      assert.strictEqual(style(this.element, `${selector} .euiFormHelpText`).color, rgb(theme.colors.darkShade), `${selector} help`);
      assert.strictEqual(style(this.element, `${selector} .euiFormErrorText`).color, rgb(theme.colors.textDanger), `${selector} error`);
      assert.strictEqual(style(this.element, `[data-${name}-valid] .euiFormRow__label`).color, rgb(theme.colors.textHeading), `${name} label`);
      assert.strictEqual(style(this.element, `[data-${name}-valid] .euiFormRow__labelAppend`).color, rgb(theme.colors.textSubdued), `${name} append`);
    }
    assert.strictEqual(style(this.element, '[data-dark-group] .euiDescribedFormGroup__description').color, rgb(dark.colors.textSubdued));
    assert.strictEqual(style(this.element, '[data-dark-fieldset] legend').color, rgb(dark.colors.textHeading));
    assert.true(
      contrast(style(this.element, '[data-dark] .euiFormHelpText').color, rgb(dark.colors.emptyShade)) >= 4.5,
      'dark help text keeps AA contrast'
    );

    state.mode = 'light';
    await settled();
    assert.strictEqual(style(this.element, '[data-dark] .euiFormHelpText').color, rgb(light.colors.darkShade), 'mode switch is reactive');
    assert.strictEqual(style(this.element, '[data-light] .euiFormHelpText').color, rgb(light.colors.darkShade), 'sibling untouched');
  });

  test('native token overrides from JS objects', async function (assert) {
    const overrides: EuiBorealisOverrides = {
      components: { forms: { maxWidth: '300px' } },
      size: { xs: '6px', base: '20px' },
      colors: { LIGHT: { textDanger: '#aa0055', textHeading: '#123456' } }
    };
    class State {
      @tracked overrides: EuiBorealisOverrides | undefined = overrides;
    }
    const state = new State();
    await render(
      <template>
        <EuiEmotionProvider @colorMode="light" @borealisOverrides={{state.overrides}}>
          <EuiFormRow @label="A" @isInvalid={{true}} @error="e" data-a><EuiFieldText /></EuiFormRow>
          <EuiFormRow @label="B" data-b><EuiFieldText /></EuiFormRow>
          <EuiDescribedFormGroup data-group><:title>T</:title><:default>x</:default></EuiDescribedFormGroup>
        </EuiEmotionProvider>
        <EuiFormRow @label="Outside" data-outside><EuiFieldText /></EuiFormRow>
      </template>
    );

    assert.strictEqual(style(this.element, '[data-a]').maxWidth, '300px', 'forms.maxWidth override');
    assert.strictEqual(style(this.element, '[data-group]').maxWidth, '600px', 'group is twice the form width');
    assert.strictEqual(style(this.element, '[data-a]').rowGap, '6px', 'size.xs override');
    assert.strictEqual(style(this.element, '[data-a] .euiFormErrorText').paddingTop, '6px');
    assert.strictEqual(style(this.element, '[data-b]').marginTop, '20px', 'size.base override');
    assert.strictEqual(style(this.element, '[data-a] .euiFormRow__label').color, rgb('#aa0055'));
    assert.strictEqual(style(this.element, '[data-a] .euiFormErrorText').color, rgb('#aa0055'));
    assert.strictEqual(style(this.element, '[data-b] .euiFormRow__label').color, rgb('#123456'));
    assert.strictEqual(style(this.element, '[data-outside]').maxWidth, light.components.forms.maxWidth, 'outside the provider unchanged');

    state.overrides = undefined;
    await settled();
    assert.strictEqual(style(this.element, '[data-a]').maxWidth, light.components.forms.maxWidth, 'removing overrides restores tokens');
    assert.strictEqual(settledStyle(this.element, '[data-b] .euiFormRow__label').color, rgb(light.colors.textHeading));
  });

  test('logical properties in RTL', async function (assert) {
    await render(
      <template>
        <div dir="rtl" style="width: 800px">
          <EuiFormRow @label="Label" @labelAppend="Optional" @helpText="help" data-row><EuiFieldText /></EuiFormRow>
          <EuiDescribedFormGroup data-group>
            <:title>T</:title>
            <:default><EuiFormRow><EuiFieldText /></EuiFormRow></:default>
          </EuiDescribedFormGroup>
        </div>
      </template>
    );

    const row = rect(this.element, '[data-row]');
    assert.strictEqual(row.right, rect(this.element, '[dir="rtl"]').right, 'capped rows start on the right');
    near(assert, rect(this.element, '[data-row] .euiFormRow__label').right, row.right, 'label starts at the right');
    near(assert, rect(this.element, '[data-row] .euiFormRow__labelAppend').left, row.left, 'append at the inline end (left)');
    const group = el(this.element, '[data-group]');
    assert.true(
      rect(group, '.euiDescribedFormGroup__fields').right < rect(group, '.euiDescribedFormGroup__descriptionColumn').left,
      'RTL groups put the description on the right'
    );
  });
});
