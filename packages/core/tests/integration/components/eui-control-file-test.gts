import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, focus, render, settled, triggerEvent } from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';
import { registerDeprecationHandler } from '@ember/debug';

import EuiButtonIcon from '#src/components/eui-button-icon.gts';
import EuiControlBar from '#src/components/eui-control-bar.gts';
import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import EuiFilePicker from '#src/components/eui-file-picker.gts';
import EuiIcon from '#src/components/eui-icon.gts';
import { euiControlBarVariables } from '#src/utils/eui/control-bar.ts';
import { euiFormVariables } from '#src/utils/eui/styles.generated.ts';
import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';

import type { EuiControlBarControl } from '#src/components/eui-control-bar.gts';
import type { EuiColorMode } from '#src/utils/emotion/theme.ts';
import type { EuiBorealisOverrides } from '#src/utils/eui/theme.ts';

const lightContext = resolveBorealisTheme('light');
const darkContext = resolveBorealisTheme('dark');
const light = lightContext.euiTheme;
const dark = darkContext.euiTheme;
const forms = (theme: typeof light) =>
  theme.components.forms as unknown as Record<string, string>;
const formVars = euiFormVariables(lightContext);

/** Normalize any CSS color to the browser's computed `rgb()` form. */
function rgb(color: string) {
  const probe = document.createElement('span');
  probe.style.color = color;
  document.body.appendChild(probe);
  const value = getComputedStyle(probe).color;
  probe.remove();
  return value;
}

/** A CSS length expression (e.g. `calc(100vh - 80px)`) in computed px. */
function px(value: string) {
  const probe = document.createElement('div');
  probe.style.position = 'absolute';
  probe.style.height = value;
  document.body.appendChild(probe);
  const height = probe.getBoundingClientRect().height;
  probe.remove();
  return Math.round(height * 100) / 100;
}

function el<T extends Element = HTMLElement>(
  root: Element | Document,
  selector: string
) {
  const element = root.querySelector<T>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

function style(root: Element | Document, selector: string, pseudo?: string) {
  return getComputedStyle(el(root, selector), pseudo);
}

/** Layout box in CSS pixels (the ember-qunit container may be scaled). */
function box(element: Element) {
  const container = document.querySelector<HTMLElement>('#ember-testing')!;
  const scale = container.getBoundingClientRect().width / container.offsetWidth;
  const rect = element.getBoundingClientRect();
  const round = (n: number) => Math.round((n / scale) * 100) / 100;
  return {
    width: round(rect.width),
    height: round(rect.height),
    left: round(rect.left),
    right: round(rect.right),
    top: round(rect.top),
    bottom: round(rect.bottom)
  };
}

function finishAnimations(element: Element) {
  element.getAnimations({ subtree: true }).forEach((a) => a.finish());
}

/** The `translateY` of a computed `transform` matrix. */
function translateY(element: Element) {
  const matrix = new DOMMatrixReadOnly(getComputedStyle(element).transform);
  return Math.round(matrix.m42 * 100) / 100;
}

/** CSS rules (in any sheet) inside `@media` blocks that target `className`. */
function mediaRulesFor(className: string) {
  const found: { media: string; css: string }[] = [];
  for (const sheet of Array.from(document.styleSheets)) {
    let rules: CSSRuleList;
    try {
      rules = sheet.cssRules;
    } catch {
      continue;
    }
    for (const rule of Array.from(rules)) {
      if (rule instanceof CSSMediaRule) {
        for (const inner of Array.from(rule.cssRules)) {
          if (inner.cssText.includes(`.${className}`)) {
            found.push({ media: rule.conditionText, css: inner.cssText });
          }
        }
      }
    }
  }
  return found;
}

/** Deprecations seen while `captured` is set (handlers cannot be unregistered). */
let captured: { message: string; options: Record<string, unknown> }[] | undefined;
registerDeprecationHandler((message, options, next) => {
  captured?.push({ message, options: options as unknown as Record<string, unknown> });
  next(message, options);
});

function files(...names: string[]) {
  return names.map((name) => new File([name], name, { type: 'text/plain' }));
}

module('Integration | Component | Borealis control bar and file picker', function (hooks) {
  setupRenderingTest(hooks);

  hooks.afterEach(function () {
    document.body.style.paddingBottom = '';
  });

  // ---------------------------------------------------------------------
  // EuiFilePicker
  // ---------------------------------------------------------------------

  test('file picker default display: control height, padding, icon, dashed border and form width', async function (assert) {
    await render(
      <template>
        <EuiEmotionProvider>
          <div style="width: 800px">
            <EuiFilePicker id="fp" data-c="normal" />
            <EuiFilePicker @compressed={{true}} data-c="compressed" />
            <EuiFilePicker @fullWidth={{true}} data-c="full" />
          </div>
          <EuiIcon @type="importAction" @color="text" data-c="icon-text" />
        </EuiEmotionProvider>
      </template>
    );
    const input = el<HTMLInputElement>(this.element, '[data-c="normal"]');
    const root = input.closest('.euiFilePicker')!;
    const prompt = el(root, '.euiFilePicker__prompt');
    const rootStyle = getComputedStyle(root);
    const promptStyle = getComputedStyle(prompt);

    assert.strictEqual(input.type, 'file');
    assert.dom(root).hasClass('euiFilePicker');
    assert.strictEqual(root.querySelector('.euiFilePicker__wrap'), null, 'no legacy wrap element');
    assert.strictEqual(rootStyle.position, 'relative');
    assert.strictEqual(rootStyle.maxWidth, formVars.maxWidth, 'form width');
    assert.strictEqual(box(root).width, 400);
    assert.strictEqual(rootStyle.borderRadius, formVars.controlBorderRadius);

    // invisible input covers the whole drop zone
    const inputStyle = getComputedStyle(input);
    assert.strictEqual(inputStyle.position, 'absolute');
    assert.strictEqual(inputStyle.opacity, '0');
    assert.deepEqual(box(input), box(root), 'input spans the picker');

    // prompt: control height and upstream padding with one left icon
    assert.strictEqual(box(prompt).height, parseFloat(formVars.controlHeight));
    assert.strictEqual(promptStyle.boxSizing, 'border-box');
    assert.strictEqual(promptStyle.paddingInlineStart, '36px', '12px + 24px icon affordance');
    assert.strictEqual(promptStyle.paddingInlineEnd, '12px');
    assert.strictEqual(promptStyle.pointerEvents, 'none');
    assert.strictEqual(promptStyle.borderTopStyle, 'dashed');
    assert.strictEqual(promptStyle.borderTopWidth, '1px');
    assert.strictEqual(promptStyle.borderTopColor, rgb(light.colors.borderBaseProminent));
    assert.strictEqual(promptStyle.color, rgb(light.colors.textParagraph));
    assert.strictEqual(promptStyle.lineHeight, promptStyle.fontSize, 'line-height: 1');
    assert.strictEqual(promptStyle.textOverflow, 'ellipsis');
    assert.strictEqual(promptStyle.whiteSpace, 'nowrap');

    // icon on the start side, vertically filling the prompt
    const icon = el(root, '.euiFilePicker__icon');
    const iconStyle = getComputedStyle(icon);
    assert.dom(icon).hasAttribute('aria-hidden', 'true');
    assert.strictEqual(iconStyle.position, 'absolute');
    assert.strictEqual(iconStyle.insetInlineStart, light.size.m);
    assert.strictEqual(iconStyle.top, '0px');
    assert.strictEqual(box(icon).height, box(prompt).height);
    assert.strictEqual(iconStyle.color, style(this.element, '[data-c="icon-text"]').color, 'text icon color');

    const compressed = el(this.element, '[data-c="compressed"]').closest('.euiFilePicker')!;
    const cPrompt = el(compressed, '.euiFilePicker__prompt');
    assert.strictEqual(box(cPrompt).height, parseFloat(formVars.controlCompressedHeight));
    assert.strictEqual(getComputedStyle(cPrompt).paddingInlineStart, '32px', '8px + 24px');
    const cIcon = getComputedStyle(el(compressed, '.euiFilePicker__icon'));
    assert.strictEqual(cIcon.insetInlineStart, light.size.s);
    assert.strictEqual(cIcon.width, light.size.m);

    const full = el(this.element, '[data-c="full"]').closest('.euiFilePicker')!;
    assert.strictEqual(getComputedStyle(full).maxWidth, '100%');
    assert.strictEqual(box(full).width, 800);
  });

  test('file picker large display: drop zone heights, centered column, interactive icon', async function (assert) {
    await render(
      <template>
        <EuiEmotionProvider>
          <EuiFilePicker @display="large" data-c="large" />
          <EuiFilePicker @display="large" @compressed={{true}} data-c="large-s" />
        </EuiEmotionProvider>
      </template>
    );
    const root = el(this.element, '[data-c="large"]').closest('.euiFilePicker')!;
    const prompt = el(root, '.euiFilePicker__prompt');
    const promptStyle = getComputedStyle(prompt);
    const base = parseFloat(light.size.base);

    assert.strictEqual(box(prompt).height, base * 8);
    assert.strictEqual(promptStyle.display, 'flex');
    assert.strictEqual(promptStyle.flexDirection, 'column');
    assert.strictEqual(promptStyle.alignItems, 'center');
    assert.strictEqual(promptStyle.justifyContent, 'center');
    assert.strictEqual(promptStyle.paddingInlineStart, light.size.l);
    assert.strictEqual(promptStyle.paddingInlineEnd, light.size.l);
    assert.strictEqual(promptStyle.borderTopStyle, 'dashed');
    assert.strictEqual(promptStyle.borderRadius, formVars.controlBorderRadius);

    const icon = el(root, '.euiFilePicker__icon');
    assert.strictEqual(getComputedStyle(icon).position, 'static');
    assert.strictEqual(getComputedStyle(icon).marginBottom, light.size.base);
    assert.strictEqual(getComputedStyle(el(root, '.euiFilePicker__promptText')).textOverflow, 'ellipsis');

    // focusing the invisible input scales the icon (largeInteractive)
    await focus(el(root, 'input'));
    finishAnimations(root);
    const transform = new DOMMatrixReadOnly(getComputedStyle(icon).transform);
    assert.strictEqual(Math.round(transform.a * 100) / 100, 1.05, 'icon scales on focus');

    const compressed = el(this.element, '[data-c="large-s"]').closest('.euiFilePicker')!;
    assert.strictEqual(box(el(compressed, '.euiFilePicker__prompt')).height, base * 6.5);
  });

  test('file picker selection: prompt text, hasFiles, clear button and onChange', async function (assert) {
    const received: (FileList | null)[] = [];
    const onChange = (list: FileList | null) => received.push(list);
    await render(
      <template>
        <EuiEmotionProvider>
          <EuiFilePicker
            @initialPromptText="Pick files"
            @multiple={{true}}
            @onChange={{onChange}}
          />
        </EuiEmotionProvider>
      </template>
    );
    const root = el(this.element, '.euiFilePicker');
    const prompt = el(root, '.euiFilePicker__prompt');
    assert.dom('.euiFilePicker__promptText').hasText('Pick files');
    assert.dom('.euiFilePicker__clearButton').doesNotExist();
    assert.strictEqual(getComputedStyle(prompt).fontWeight, '400');

    await triggerEvent('input[type="file"]', 'change', { files: files('a.txt') });
    assert.dom('.euiFilePicker__promptText').hasText('a.txt');
    assert.dom(root).hasClass('euiFilePicker-hasFiles');
    assert.strictEqual(getComputedStyle(prompt).fontWeight, String(light.font.weight.bold));
    assert.strictEqual(getComputedStyle(prompt).paddingInlineEnd, '36px', 'right icon affordance');

    await triggerEvent('input[type="file"]', 'change', { files: files('a.txt', 'b.txt') });
    assert.dom('.euiFilePicker__promptText').hasText('2 files selected');
    assert.strictEqual(received.length, 2);
    assert.strictEqual(received[1]!.length, 2);

    // the clear button: upstream EuiFormControlLayoutClearButton, end side
    const clear = el<HTMLButtonElement>(root, 'button.euiFilePicker__clearButton');
    assert.dom(clear).hasClass('euiFormControlLayoutClearButton');
    assert.dom(clear).hasAria('label', 'Remove selected files');
    assert.dom(clear).hasAttribute('type', 'button');
    assert.strictEqual(box(clear).width, 16);
    const wrapper = clear.parentElement!;
    const wrapperStyle = getComputedStyle(wrapper);
    assert.strictEqual(wrapperStyle.position, 'absolute');
    assert.strictEqual(wrapperStyle.top, light.size.m);
    assert.strictEqual(wrapperStyle.insetInlineEnd, light.size.m);
    assert.notStrictEqual(getComputedStyle(clear).pointerEvents, 'none', 'clickable through the prompt');
    assert.strictEqual(
      box(root).right - box(clear).right,
      parseFloat(light.size.m),
      '12px from the end'
    );
    assert.strictEqual(
      Math.round(box(clear).top + box(clear).height / 2),
      Math.round(box(root).top + box(root).height / 2),
      'vertically centered'
    );

    await click(clear);
    assert.dom('.euiFilePicker__promptText').hasText('Pick files');
    assert.dom(root).doesNotHaveClass('euiFilePicker-hasFiles');
    assert.dom('.euiFilePicker__clearButton').doesNotExist();
    assert.strictEqual(received.length, 3);
    assert.strictEqual(received[2]!.length, 0, 'removal reports an empty list');
    assert.strictEqual(el<HTMLInputElement>(root, 'input').value, '');
  });

  test('file picker large display: "Remove" button and progress bar', async function (assert) {
    class State {
      @tracked isLoading = false;
    }
    const state = new State();
    await render(
      <template>
        <EuiEmotionProvider>
          <EuiFilePicker @display="large" @isLoading={{state.isLoading}} />
        </EuiEmotionProvider>
      </template>
    );
    await triggerEvent('input[type="file"]', 'change', { files: files('report.pdf') });
    const root = el(this.element, '.euiFilePicker');
    const remove = el<HTMLButtonElement>(root, '.euiFilePicker__clearButton');
    assert.dom(remove).hasText('Remove');
    assert.dom(remove).hasAria('label', 'Remove selected files');
    assert.notStrictEqual(getComputedStyle(remove).pointerEvents, 'none');
    assert.strictEqual(getComputedStyle(remove.parentElement!).position, 'relative');
    assert.dom('.euiFilePicker__promptText').hasText('report.pdf');

    await click(remove);
    assert.dom('.euiFilePicker__clearButton').doesNotExist();

    state.isLoading = true;
    await settled();
    assert.dom(root).hasClass('euiFilePicker-isLoading');
    assert.dom('.euiFilePicker__prompt .euiProgress').exists('progress bar');
    assert.dom('.euiFilePicker__loadingSpinner').doesNotExist();
    assert.strictEqual(getComputedStyle(root).overflow, 'hidden');
  });

  test('file picker states: invalid, disabled, loading', async function (assert) {
    await render(
      <template>
        <EuiEmotionProvider>
          <EuiFilePicker @isInvalid={{true}} data-c="invalid" />
          <EuiFilePicker @disabled={{true}} data-c="disabled" />
          <EuiFilePicker @isLoading={{true}} data-c="loading" />
          <EuiFilePicker @isLoading={{true}} @compressed={{true}} data-c="loading-s" />
          <EuiIcon @type="warning" @color="danger" data-c="icon-danger" />
        </EuiEmotionProvider>
      </template>
    );
    const f = forms(light);

    const invalid = el<HTMLInputElement>(this.element, '[data-c="invalid"]');
    const invalidRoot = invalid.closest('.euiFilePicker')!;
    assert.dom(invalid).hasAria('invalid', 'true');
    assert.true(invalid.validity.customError, 'native validity');
    assert.dom(invalidRoot).hasClass('euiFilePicker-isInvalid');
    assert.strictEqual(
      style(invalidRoot, '.euiFilePicker__prompt').borderTopColor,
      rgb(f['borderInvalid']!)
    );
    assert.dom(el(invalidRoot, '.euiFilePicker__icon')).hasAttribute('data-icon-type', 'warning');
    assert.strictEqual(
      style(invalidRoot, '.euiFilePicker__icon').color,
      style(this.element, '[data-c="icon-danger"]').color
    );

    const disabled = el<HTMLInputElement>(this.element, '[data-c="disabled"]');
    const disabledRoot = disabled.closest('.euiFilePicker')!;
    assert.true(disabled.disabled);
    const dPrompt = style(disabledRoot, '.euiFilePicker__prompt');
    assert.strictEqual(dPrompt.borderTopColor, 'rgba(0, 0, 0, 0)', 'transparent border');
    assert.strictEqual(dPrompt.backgroundColor, rgb(f['backgroundDisabled']!));
    assert.strictEqual(dPrompt.color, rgb(f['colorDisabled']!));
    assert.strictEqual(getComputedStyle(disabled).cursor, 'default', 'no pointer while not hovered');
    assert.dom(el(disabledRoot, '.euiFilePicker__icon')).hasAttribute('data-icon-type', 'minusInCircle');
    assert.strictEqual(style(disabledRoot, '.euiFilePicker__icon').color, rgb(f['colorDisabled']!));

    // a programmatic selection (e.g. a form reset helper) still updates the prompt
    const transfer = new DataTransfer();
    transfer.items.add(files('x.txt')[0]!);
    disabled.files = transfer.files;
    disabled.dispatchEvent(new Event('change'));
    await settled();
    assert.dom(el(disabledRoot, '.euiFilePicker__promptText')).hasText('x.txt');
    assert.strictEqual(disabledRoot.querySelector('.euiFilePicker__clearButton'), null, 'no clear button while disabled');
    assert.strictEqual(dPrompt.fontWeight, '400', 'hasFiles weight skipped while disabled');

    const loadingRoot = el(this.element, '[data-c="loading"]').closest('.euiFilePicker')!;
    const spinner = el(loadingRoot, '.euiFilePicker__loadingSpinner');
    assert.dom(spinner).hasAttribute('role', 'progressbar');
    assert.strictEqual(spinner.offsetWidth, 16, 'spinner size m (layout box; it rotates)');
    assert.strictEqual(getComputedStyle(spinner.parentElement!).position, 'absolute');
    assert.strictEqual(style(loadingRoot, '.euiFilePicker__prompt').paddingInlineEnd, '36px');
    assert.strictEqual(getComputedStyle(loadingRoot).overflow, 'hidden');
    await triggerEvent(el(loadingRoot, 'input'), 'change', { files: files('y.txt') });
    assert.strictEqual(loadingRoot.querySelector('.euiFilePicker__clearButton'), null, 'spinner replaces the clear button');

    const loadingS = el(this.element, '[data-c="loading-s"]').closest('.euiFilePicker')!;
    const spinnerS = el(loadingS, '.euiFilePicker__loadingSpinner');
    assert.strictEqual(spinnerS.offsetWidth, 12, 'spinner size s');
    const wrapperS = getComputedStyle(spinnerS.parentElement!);
    assert.strictEqual(wrapperS.insetInlineEnd, light.size.s);
    assert.strictEqual(
      Math.round(box(spinnerS).top + box(spinnerS).height / 2),
      Math.round(box(loadingS).top + box(loadingS).height / 2),
      'compressed spinner vertically centered (top: 50%)'
    );
  });

  test('file picker drag over, focus and native attributes', async function (assert) {
    let instance: unknown;
    const ref = (c: unknown) => (instance = c);
    await render(
      <template>
        <EuiEmotionProvider>
          <EuiFilePicker
            @id="upload"
            @name="attachment"
            @ref={{ref}}
            accept=".txt"
            data-test="native"
          />
          <EuiFilePicker @disabled={{true}} data-c="disabled" />
        </EuiEmotionProvider>
      </template>
    );
    const input = el<HTMLInputElement>(this.element, '#upload');
    const root = input.closest('.euiFilePicker')!;
    const prompt = el(root, '.euiFilePicker__prompt');

    assert.dom(input).hasAttribute('name', 'attachment');
    assert.dom(input).hasAttribute('accept', '.txt');
    assert.dom(input).hasAttribute('data-test', 'native');
    assert.dom(input).hasClass('euiFilePicker__input');
    assert.dom(input).hasAria('describedby', 'upload-filePicker__prompt');
    assert.dom(prompt).hasAttribute('id', 'upload-filePicker__prompt');
    assert.dom(input).doesNotHaveAria('invalid');

    await triggerEvent(input, 'dragover');
    assert.dom(root).hasClass('euiFilePicker-isDroppingFile');
    assert.true(
      getComputedStyle(prompt).transitionProperty.includes('border-color') ||
        matchMedia('(prefers-reduced-motion: reduce)').matches,
      'border color transitions (euiCanAnimate)'
    );
    finishAnimations(root);
    assert.strictEqual(getComputedStyle(root).backgroundColor, rgb(forms(light)['backgroundDropping']!));
    assert.strictEqual(getComputedStyle(prompt).borderTopColor, rgb(light.colors.borderStrongSuccess));
    assert.strictEqual(getComputedStyle(prompt).borderTopStyle, 'dashed');
    await triggerEvent(input, 'dragleave');
    assert.dom(root).doesNotHaveClass('euiFilePicker-isDroppingFile');
    await triggerEvent(input, 'dragover');
    await triggerEvent(input, 'drop');
    assert.dom(root).doesNotHaveClass('euiFilePicker-isDroppingFile');

    const disabled = el(this.element, '[data-c="disabled"]');
    disabled.dispatchEvent(new Event('dragover'));
    await settled();
    assert.dom(disabled.closest('.euiFilePicker')).doesNotHaveClass('euiFilePicker-isDroppingFile');

    await focus(input);
    finishAnimations(root);
    assert.strictEqual(getComputedStyle(prompt).borderTopColor, rgb(forms(light)['borderFocused']!), 'focus color');

    // ref exposes removeFiles
    await triggerEvent(input, 'change', { files: files('a.txt') });
    assert.dom(root).hasClass('euiFilePicker-hasFiles');
    (instance as { removeFiles: () => void }).removeFiles();
    await settled();
    assert.dom(root).doesNotHaveClass('euiFilePicker-hasFiles');
  });

  test('file picker reactive args update in place', async function (assert) {
    class State {
      @tracked compressed = false;
      @tracked display: 'default' | 'large' = 'default';
      @tracked isInvalid = false;
      @tracked disabled = false;
      @tracked fullWidth = false;
    }
    const state = new State();
    await render(
      <template>
        <EuiEmotionProvider>
          <div style="width: 800px">
            <EuiFilePicker
              @compressed={{state.compressed}}
              @display={{state.display}}
              @isInvalid={{state.isInvalid}}
              @disabled={{state.disabled}}
              @fullWidth={{state.fullWidth}}
            />
          </div>
        </EuiEmotionProvider>
      </template>
    );
    const root = el(this.element, '.euiFilePicker');
    const input = el<HTMLInputElement>(root, 'input');
    const prompt = el(root, '.euiFilePicker__prompt');
    assert.strictEqual(box(prompt).height, 40);

    state.compressed = true;
    await settled();
    assert.strictEqual(box(prompt).height, 32);

    state.display = 'large';
    await settled();
    assert.strictEqual(box(prompt).height, 104);
    assert.strictEqual(getComputedStyle(prompt).display, 'flex');

    state.isInvalid = true;
    await settled();
    assert.dom(input).hasAria('invalid', 'true');
    assert.true(input.validity.customError);
    state.isInvalid = false;
    await settled();
    assert.false(input.validity.customError);
    assert.dom(input).doesNotHaveAria('invalid');

    state.disabled = true;
    state.fullWidth = true;
    await settled();
    assert.true(input.disabled);
    assert.strictEqual(box(root).width, 800);

    assert.strictEqual(el(this.element, '.euiFilePicker'), root, 'same root element');
    assert.strictEqual(el(this.element, '.euiFilePicker__input'), input, 'same input element');
  });

  test('file picker: nearest provider, sibling isolation, token overrides and RTL', async function (assert) {
    class State {
      @tracked mode: EuiColorMode = 'dark';
    }
    const state = new State();
    const own: EuiBorealisOverrides = {
      size: { xxl: '48px', m: '20px' },
      colors: { LIGHT: { borderBaseProminent: '#ff0000' } }
    };
    await render(
      <template>
        <EuiEmotionProvider @colorMode={{state.mode}}>
          <EuiFilePicker data-c="parent" />
          <EuiEmotionProvider @colorMode="light" @borealisOverrides={{own}}>
            <EuiFilePicker data-c="override" />
          </EuiEmotionProvider>
        </EuiEmotionProvider>
        <EuiEmotionProvider @colorMode="light">
          <EuiFilePicker data-c="sibling" />
          <div dir="rtl" style="width: 400px">
            <EuiFilePicker @isLoading={{true}} data-c="rtl" />
          </div>
        </EuiEmotionProvider>
      </template>
    );
    const prompt = (key: string) =>
      el(el(this.element, `[data-c="${key}"]`).closest('.euiFilePicker')!, '.euiFilePicker__prompt');

    assert.strictEqual(getComputedStyle(prompt('parent')).color, rgb(dark.colors.textParagraph));
    assert.strictEqual(getComputedStyle(prompt('parent')).borderTopColor, rgb(dark.colors.borderBaseProminent));
    assert.strictEqual(getComputedStyle(prompt('sibling')).color, rgb(light.colors.textParagraph));
    assert.strictEqual(getComputedStyle(prompt('sibling')).borderTopColor, rgb(light.colors.borderBaseProminent));

    assert.strictEqual(getComputedStyle(prompt('override')).borderTopColor, rgb('#ff0000'));
    assert.strictEqual(box(prompt('override')).height, 48, 'size.xxl drives the control height');
    assert.strictEqual(getComputedStyle(prompt('override')).paddingInlineStart, '44px', 'size.m padding + 24px');

    state.mode = 'light';
    await settled();
    assert.strictEqual(getComputedStyle(prompt('parent')).color, rgb(light.colors.textParagraph));

    // RTL: the icon is on the right, the spinner on the left
    const rtlRoot = el(this.element, '[data-c="rtl"]').closest('.euiFilePicker')!;
    const rootBox = box(rtlRoot);
    const icon = box(el(rtlRoot, '.euiFilePicker__icon'));
    const spinner = box(el(rtlRoot, '.euiFilePicker__loadingSpinner'));
    assert.strictEqual(Math.round(rootBox.right - icon.right), 12, 'icon at the inline start (right)');
    assert.strictEqual(
      Math.round((spinner.left + spinner.right) / 2 - rootBox.left),
      20,
      'spinner (16px, centered 12px + 8px in) at the inline end (left)'
    );
    assert.strictEqual(getComputedStyle(prompt('rtl')).paddingRight, '36px');
  });

  // ---------------------------------------------------------------------
  // EuiControlBar
  // ---------------------------------------------------------------------

  test('control bar: dark bar tokens inside a light page, controls row and control types', async function (assert) {
    const clicked: string[] = [];
    const controls: EuiControlBarControl[] = [
      { controlType: 'icon', id: 'logo', iconType: 'logoElastic', 'aria-label': 'Elastic' },
      { controlType: 'breadcrumbs', id: 'crumbs', breadcrumbs: [{ text: 'Root' }, { text: 'Page' }] },
      { controlType: 'spacer' },
      { controlType: 'text', id: 'status', text: 'Saved' },
      { controlType: 'divider' },
      { controlType: 'button', id: 'run', label: 'Run', onClick: () => clicked.push('run') },
      { controlType: 'icon', id: 'close', iconType: 'cross', 'aria-label': 'Close', onClick: () => clicked.push('close') }
    ];
    await render(
      <template>
        <EuiEmotionProvider @colorMode="light">
          <div style="width: 900px">
            <EuiControlBar @controls={{controls}} @position="relative" data-test="bar" />
          </div>
          <EuiEmotionProvider @colorMode="dark">
            <EuiButtonIcon @iconType="cross" @color="ghost" aria-label="Reference" data-c="reference" />
          </EuiEmotionProvider>
        </EuiEmotionProvider>
      </template>
    );
    const bar = el(this.element, 'section.euiControlBar');
    const barStyle = getComputedStyle(bar);
    const vars = euiControlBarVariables(darkContext);

    assert.dom(bar).hasAttribute('data-test', 'bar');
    assert.dom(bar).hasClass('euiControlBar--relative').hasClass('euiControlBar--large');
    assert.dom(bar).hasAria('label', 'Page level controls');
    assert.strictEqual(barStyle.backgroundColor, rgb(dark.components.bottomBarBackground));
    assert.strictEqual(barStyle.color, rgb(dark.colors.textParagraph));
    assert.strictEqual(barStyle.position, 'relative');
    assert.strictEqual(barStyle.display, 'flex');
    assert.strictEqual(barStyle.flexDirection, 'column');
    assert.strictEqual(box(bar).height, parseFloat(vars.initialHeight));
    assert.strictEqual(barStyle.maxHeight, `${px('calc(100vh - 80px)')}px`);
    assert.true(barStyle.boxShadow.includes(rgb(light.colors.body)), 'flicker guard uses the page background');
    assert.strictEqual(translateY(bar), 0);

    // SR-only heading
    const heading = el(bar, 'h2');
    assert.dom(heading).hasText('Page level controls');
    assert.strictEqual(box(heading).width <= 1, true, 'heading is visually hidden');

    const row = el(bar, '.euiControlBar__controls');
    const rowStyle = getComputedStyle(row);
    assert.strictEqual(rowStyle.display, 'flex');
    assert.strictEqual(rowStyle.alignItems, 'center');
    assert.strictEqual(rowStyle.overflowX, 'auto');
    assert.strictEqual(rowStyle.overflowY, 'hidden');
    assert.strictEqual(rowStyle.paddingInlineStart, dark.size.m);
    assert.strictEqual(box(row).height, 40);

    const icon = el(bar, '.euiControlBar__icon');
    assert.strictEqual(getComputedStyle(icon).flexShrink, '0');
    assert.strictEqual(getComputedStyle(icon).marginInlineStart, dark.size.s);
    assert.strictEqual(getComputedStyle(icon).marginInlineEnd, dark.size.s);

    assert.dom(el(bar, '.euiControlBar__breadcrumbs')).exists();
    const spacer = el(bar, '.euiControlBar__spacer');
    assert.strictEqual(getComputedStyle(spacer).flexGrow, '1');
    assert.true(box(spacer).width > 100, 'spacer fills the row');

    const text = el(bar, '.euiControlBar__text');
    assert.dom(text).hasText('Saved');
    assert.strictEqual(getComputedStyle(text).textOverflow, 'ellipsis');
    assert.strictEqual(getComputedStyle(text).paddingInlineStart, dark.size.s);
    assert.strictEqual(getComputedStyle(text).color, rgb(dark.colors.textParagraph));

    const divider = el(bar, '.euiControlBar__divider');
    assert.strictEqual(box(divider).width, 1);
    assert.strictEqual(box(divider).height, 40);
    assert.strictEqual(getComputedStyle(divider).backgroundColor, rgb(dark.border.color));

    const button = el(bar, '.euiControlBar__button');
    assert.strictEqual(getComputedStyle(button).flexShrink, '0');
    assert.strictEqual(getComputedStyle(button).marginInlineStart, dark.size.xs);

    const buttonIcon = el(bar, '.euiControlBar__buttonIcon');
    assert.true(buttonIcon.classList.contains('euiButtonIcon'));
    assert.strictEqual(box(buttonIcon).width, 40, 'min-width = bar height');
    assert.strictEqual(box(buttonIcon).height, 40);
    assert.strictEqual(getComputedStyle(buttonIcon).flexShrink, '0');
    assert.strictEqual(buttonIcon.className.split(' ').filter((c) => c.startsWith('css-')).length <= 1, true, 'one Emotion class');
    // controls render in the dark provider: same colors as a dark-mode button icon
    assert.strictEqual(
      getComputedStyle(buttonIcon).color,
      style(this.element, '[data-c="reference"]').color
    );

    await click(button);
    await click(buttonIcon);
    assert.deepEqual(clicked, ['run', 'close']);
  });

  test('control bar: tabs, content area in the page color mode and open sizes', async function (assert) {
    class State {
      @tracked showContent = false;
      @tracked size: 's' | 'm' | 'l' = 's';
    }
    const state = new State();
    let tabClicks = 0;
    const toggle = () => {
      tabClicks++;
      state.showContent = !state.showContent;
    };
    const controls: EuiControlBarControl[] = [
      { controlType: 'tab', id: 'console', label: 'Console', onClick: toggle },
      { controlType: 'tab', id: 'output', label: 'Output', onClick: toggle, className: 'extra' }
    ];
    await render(
      <template>
        <EuiEmotionProvider @colorMode="light">
          <div style="position: relative; height: 1200px">
            <EuiControlBar
              @controls={{controls}}
              @position="relative"
              @showContent={{state.showContent}}
              @size={{state.size}}
            >
              <p class="content">Output</p>
            </EuiControlBar>
          </div>
        </EuiEmotionProvider>
      </template>
    );
    const bar = el(this.element, '.euiControlBar');
    const tab = el<HTMLButtonElement>(bar, '.euiControlBar__tab');
    const tabStyle = getComputedStyle(tab);
    assert.strictEqual(tab.type, 'button');
    assert.strictEqual(tabStyle.borderTopStyle, 'none', 'button reset');
    assert.strictEqual(tabStyle.backgroundColor, 'rgba(0, 0, 0, 0)');
    assert.strictEqual(tabStyle.color, rgb(dark.colors.textParagraph));
    assert.strictEqual(tabStyle.paddingInlineStart, dark.size.base);
    assert.strictEqual(box(tab).height, 40);
    assert.strictEqual(tabStyle.textAlign, 'center');
    assert.dom('.euiControlBar__tab.extra').exists('className passes through');
    assert.dom('.euiControlBar__content').doesNotExist();

    await click(tab);
    assert.strictEqual(tabClicks, 1);
    assert.dom(bar).hasClass('euiControlBar-isOpen').hasClass('euiControlBar--small');
    assert.dom(tab).hasClass('euiControlBar__tab--active');
    assert.dom('.euiControlBar__tab.extra').doesNotHaveClass('euiControlBar__tab--active');
    const active = getComputedStyle(tab);
    assert.strictEqual(active.backgroundColor, rgb(light.colors.body), 'active tab joins the page-colored content');
    assert.strictEqual(active.color, rgb(light.colors.textPrimary));
    assert.strictEqual(active.boxShadow, `${rgb(light.colors.textPrimary)} 0px 4px 0px 0px inset`);

    const content = el(bar, '.euiControlBar__content');
    assert.dom(content.querySelector('.content')).hasText('Output');
    assert.ok(content.getAnimations().length > 0 || matchMedia('(prefers-reduced-motion: reduce)').matches, 'content fades in');
    finishAnimations(bar);
    const contentStyle = getComputedStyle(content);
    assert.strictEqual(contentStyle.backgroundColor, rgb(light.colors.body));
    assert.strictEqual(contentStyle.color, rgb(light.colors.textParagraph));
    assert.strictEqual(contentStyle.overflowY, 'auto');

    // small: 240px tall, shifted by its own height (bottom: -240px)
    const base = parseFloat(light.size.base);
    assert.strictEqual(box(bar).height, base * 15);
    assert.strictEqual(translateY(bar), -base * 15);
    assert.strictEqual(getComputedStyle(bar).bottom, `-${base * 15}px`);
    assert.strictEqual(box(content).height, base * 15 - 40);

    state.size = 'm';
    await settled();
    finishAnimations(bar);
    assert.strictEqual(el(this.element, '.euiControlBar'), bar, 'same element');
    assert.dom(bar).hasClass('euiControlBar--medium');
    assert.strictEqual(box(bar).height, base * 30);
    assert.strictEqual(translateY(bar), -base * 30);

    state.size = 'l';
    await settled();
    finishAnimations(bar);
    assert.strictEqual(box(bar).height, px('calc(100vh - 80px)'));
    assert.strictEqual(translateY(bar), -px('100vh'));

    await click(tab);
    assert.dom(bar).doesNotHaveClass('euiControlBar-isOpen');
    assert.dom(tab).doesNotHaveClass('euiControlBar__tab--active');
    assert.strictEqual(box(bar).height, 40);
    assert.strictEqual(translateY(bar), 0);
  });

  test('control bar content follows a dark page; bar stays dark in both', async function (assert) {
    const controls: EuiControlBarControl[] = [{ controlType: 'text', id: 't', text: 'Hi' }];
    await render(
      <template>
        <EuiEmotionProvider @colorMode="dark">
          <EuiControlBar @controls={{controls}} @position="relative" @showContent={{true}} @size="s" data-c="dark">
            <p>Dark page</p>
          </EuiControlBar>
        </EuiEmotionProvider>
        <EuiEmotionProvider @colorMode="light">
          <EuiControlBar @controls={{controls}} @position="relative" data-c="light" />
        </EuiEmotionProvider>
      </template>
    );
    const darkBar = el(this.element, '[data-c="dark"]');
    const lightBar = el(this.element, '[data-c="light"]');
    assert.strictEqual(getComputedStyle(darkBar).backgroundColor, rgb(dark.components.bottomBarBackground));
    assert.strictEqual(getComputedStyle(lightBar).backgroundColor, rgb(dark.components.bottomBarBackground));
    const content = el(darkBar, '.euiControlBar__content');
    assert.strictEqual(getComputedStyle(content).backgroundColor, rgb(dark.colors.body));
    assert.strictEqual(getComputedStyle(content).color, rgb(dark.colors.textParagraph));
  });

  test('control bar: fixed in a portal, offsets, z-index, body padding and announcement', async function (assert) {
    class State {
      @tracked show = true;
    }
    const state = new State();
    const controls: EuiControlBarControl[] = [{ controlType: 'text', id: 't', text: 'Fixed' }];
    await render(
      <template>
        <EuiEmotionProvider>
          {{#if state.show}}
            <EuiControlBar
              @controls={{controls}}
              @landmarkHeading="Editor controls"
              @bodyClassName="has-bar"
              @leftOffset={{250}}
              @rightOffset="2rem"
              @maxHeight="300px"
            />
          {{/if}}
          <EuiControlBar @controls={{controls}} @position="absolute" data-c="absolute" />
        </EuiEmotionProvider>
      </template>
    );
    const fixed = el(document, 'section.euiControlBar--fixed');
    assert.strictEqual(fixed.closest('#ember-testing'), null, 'rendered in a portal');
    const fixedStyle = getComputedStyle(fixed);
    assert.strictEqual(fixedStyle.position, 'fixed');
    assert.strictEqual(fixedStyle.zIndex, String(light.levels.mask));
    assert.strictEqual(fixedStyle.left, '250px');
    assert.strictEqual(fixedStyle.right, px('2rem') + 'px');
    assert.strictEqual(fixedStyle.bottom, '0px');
    assert.strictEqual(fixedStyle.maxHeight, '300px');
    assert.strictEqual(fixedStyle.backgroundColor, rgb(dark.components.bottomBarBackground));
    assert.dom(fixed).hasAria('label', 'Editor controls');
    assert.dom('h2', fixed).hasText('Editor controls');

    const live = el(document, '[aria-live="assertive"]');
    assert.dom(live).includesText('There is a new region landmark called Editor controls');
    assert.ok(live.getBoundingClientRect().width <= 1, 'announcement is visually hidden');
    assert.dom(document.body).hasClass('has-bar');
    assert.strictEqual(document.body.style.paddingBottom, '40px');

    const absolute = el(this.element, '[data-c="absolute"]');
    assert.strictEqual(getComputedStyle(absolute).position, 'absolute');
    assert.strictEqual(getComputedStyle(absolute).zIndex, String(light.levels.header));
    assert.strictEqual(document.querySelectorAll('[aria-live="assertive"]').length, 1, 'only fixed bars announce');

    state.show = false;
    await settled();
    assert.strictEqual(document.querySelector('section.euiControlBar--fixed'), null);
    assert.dom(document.body).doesNotHaveClass('has-bar');
    assert.strictEqual(document.body.style.paddingBottom, '');
  });

  test('control bar is deprecated (removed upstream)', async function (assert) {
    const controls: EuiControlBarControl[] = [{ controlType: 'text', id: 't', text: 'Text' }];
    captured = [];
    try {
      await render(
        <template>
          <EuiControlBar @controls={{controls}} @position="relative" />
        </template>
      );
    } finally {
      const seen = captured.filter(
        (d) => d.options['id'] === 'ember-eui.eui-control-bar.removed-upstream'
      );
      captured = undefined;
      assert.strictEqual(seen.length, 1, 'one deprecation per render');
      assert.deepEqual(
        {
          until: seen[0]?.options['until'],
          for: seen[0]?.options['for'],
          since: seen[0]?.options['since']
        },
        {
          until: '15.0.0',
          for: '@ember-eui/core',
          since: { available: '14.2.0', enabled: '14.2.0' }
        }
      );
      assert.true(seen[0]!.message.includes('removed from upstream Elastic UI'));
      assert.true(seen[0]!.message.includes('next major'));
    }
    assert.dom('.euiControlBar').exists('still renders');
  });

  test('control bar: hidden on small screens unless showOnMobile, RTL and overrides', async function (assert) {
    const controls: EuiControlBarControl[] = [
      { controlType: 'text', id: 't', text: 'Text' },
      { controlType: 'button', id: 'b', label: 'Go' }
    ];
    const own: EuiBorealisOverrides = { size: { xxl: '48px' } };
    await render(
      <template>
        <EuiEmotionProvider>
          <EuiControlBar @controls={{controls}} @position="relative" data-c="default" />
          <EuiControlBar @controls={{controls}} @position="relative" @showOnMobile={{true}} data-c="mobile" />
          <div dir="rtl">
            <EuiControlBar @controls={{controls}} @position="relative" data-c="rtl" />
          </div>
          <EuiEmotionProvider @borealisOverrides={{own}}>
            <EuiControlBar @controls={{controls}} @position="relative" data-c="override" />
          </EuiEmotionProvider>
        </EuiEmotionProvider>
      </template>
    );
    const bar = (key: string) => el(this.element, `[data-c="${key}"]`);
    const mobileBreakpoint = `${light.breakpoint.m - 1}px`;

    // the media rules emitted for each bar's own Emotion class
    const hiding = Array.from(bar('default').classList)
      .flatMap((c) => mediaRulesFor(c))
      .filter((r) => r.media.includes(mobileBreakpoint));
    assert.true(hiding.some((r) => r.css.includes('display: none')), 'hidden below the m breakpoint');
    assert.false(hiding.some((r) => r.css.includes('display: flex')));
    assert.dom(bar('mobile')).hasClass('euiControlBar--showOnMobile');
    const shown = Array.from(bar('mobile').classList)
      .flatMap((c) => mediaRulesFor(c))
      .filter((r) => r.media.includes(mobileBreakpoint));
    assert.true(shown.some((r) => r.css.includes('display: flex')), 'showOnMobile keeps it');

    // RTL: logical padding and margins
    const rtlRow = el(bar('rtl'), '.euiControlBar__controls');
    const rtlText = el(bar('rtl'), '.euiControlBar__text');
    const rtlButton = el(bar('rtl'), '.euiControlBar__button');
    assert.strictEqual(Math.round(box(rtlRow).right - box(rtlText).right), 12, 'text starts at the right');
    assert.strictEqual(getComputedStyle(rtlButton).marginRight, dark.size.xs);
    assert.strictEqual(getComputedStyle(rtlButton).marginLeft, dark.size.xs, 'last button end margin');
    assert.true(box(rtlButton).left < box(rtlText).left, 'button after the text (to the left)');

    // a token override reaches the nested dark bar
    assert.strictEqual(box(bar('override')).height, 48);
    assert.strictEqual(box(el(bar('override'), '.euiControlBar__controls')).height, 48);
  });
});
