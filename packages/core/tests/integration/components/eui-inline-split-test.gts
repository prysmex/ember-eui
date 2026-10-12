import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { hash } from '@ember/helper';
import { on } from '@ember/modifier';
import {
  blur,
  click,
  fillIn,
  render,
  settled,
  triggerKeyEvent
} from '@ember/test-helpers';
import { tracked } from '@glimmer/tracking';

import EuiEmotionProvider from '#src/components/eui-emotion-provider.gts';
import EuiFieldText from '#src/components/eui-field-text.gts';
import EuiFormAppend from '#src/components/eui-form-append.gts';
import EuiFormControlButton from '#src/components/eui-form-control-button.gts';
import EuiFormControlLayout from '#src/components/eui-form-control-layout.gts';
import EuiFormPrepend from '#src/components/eui-form-prepend.gts';
import EuiInlineEditText from '#src/components/eui-inline-edit-text.gts';
import EuiInlineEditTitle from '#src/components/eui-inline-edit-title.gts';
import EuiSplitButton from '#src/components/eui-split-button.gts';
import EuiText from '#src/components/eui-text.gts';
import EuiTitle from '#src/components/eui-title.gts';
import {
  euiButtonDisplaysColors,
  getEuiButtonColorValues,
  getEuiFilledButtonColorValues
} from '#src/utils/eui/styles.generated.ts';
import { resolveBorealisTheme } from '#src/utils/eui/theme.ts';

import type { EuiColorMode } from '#src/utils/emotion/theme.ts';
import type { EuiBorealisOverrides } from '#src/utils/eui/theme.ts';

const lightContext = resolveBorealisTheme('light');
const darkContext = resolveBorealisTheme('dark');
const light = lightContext.euiTheme;
const dark = darkContext.euiTheme;

type Tokens = Record<string, string>;
const forms = (theme: typeof light) =>
  theme.components.forms as unknown as Tokens;
const colors = (theme: typeof light) => theme.colors as unknown as Tokens;
const base = (context: typeof lightContext, color: string) =>
  getEuiButtonColorValues(context, color) as {
    backgroundColor: string;
    color: string;
  };
const filled = (context: typeof lightContext, color: string) =>
  getEuiFilledButtonColorValues(context, color) as {
    backgroundColor: string;
    color: string;
  };

/** Normalize any CSS color to the browser's computed `rgb()` form. */
function rgb(color: string) {
  const probe = document.createElement('span');
  probe.style.color = color;
  document.body.appendChild(probe);
  const value = getComputedStyle(probe).color;
  probe.remove();
  return value;
}

function el<T extends Element = HTMLElement>(
  selector: string,
  root: ParentNode = document
): T {
  const element = root.querySelector<T>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

function css(target: string | Element, pseudo?: string) {
  return getComputedStyle(typeof target === 'string' ? el(target) : target, pseudo);
}

function inside(key: string, selector: string) {
  return `[data-p="${key}"] ${selector}, [data-p="${key}"]${selector}`;
}

/** Measured box in CSS pixels (the ember-qunit container is scaled). */
function box(target: string | Element) {
  const container = el('#ember-testing');
  const scale = container.getBoundingClientRect().width / container.offsetWidth;
  const rect = (typeof target === 'string' ? el(target) : target).getBoundingClientRect();
  const round = (value: number) => Math.round((value / scale) * 100) / 100;
  return {
    width: round(rect.width),
    height: round(rect.height),
    left: round(rect.left),
    right: round(rect.right)
  };
}

const READ = '[data-test-subj="euiInlineReadModeButton"]';
const INPUT = '[data-test-subj="euiInlineEditModeInput"]';
const SAVE = '[data-test-subj="euiInlineEditModeSaveButton"]';
const CANCEL = '[data-test-subj="euiInlineEditModeCancelButton"]';

module('Integration | Component | Borealis inline edit, split button, form append/prepend', function (hooks) {
  setupRenderingTest(hooks);

  module('EuiInlineEditText / EuiInlineEditTitle', function () {
    test('read mode button, edit mode field, sizes and focus management', async function (assert) {
      await render(
        <template>
          <EuiEmotionProvider @colorMode="light">
            <EuiInlineEditText
              @inputAriaLabel="Edit name"
              @defaultValue="Hello world"
              class="custom"
              data-p="m"
            />
            <EuiInlineEditText
              @size="s"
              @inputAriaLabel="Edit small"
              @defaultValue="Small"
              data-p="s"
            />
            <EuiText @size="m" data-p="ref-m">x</EuiText>
            <EuiText @size="s" data-p="ref-s">x</EuiText>
          </EuiEmotionProvider>
        </template>
      );
      const root = el('[data-p="m"]');
      assert.dom(root).hasClass('euiInlineEdit').hasClass('euiInlineEditText').hasClass('custom');
      const button = el(inside('m', READ));
      assert.strictEqual(button.tagName, 'BUTTON');
      assert.dom(button).hasClass('euiButtonEmpty').hasAttribute('title', 'Hello world');
      assert.strictEqual(box(button).height, 40, 'medium button');
      assert.strictEqual(box(inside('s', READ)).height, 32, 'small button');
      assert.strictEqual(css(button).paddingInlineStart, '0px', 'flush both');
      assert.dom('[data-icon-type="pencil"]', button).exists('pencil affordance');
      const text = el('.euiText', button);
      assert.dom(text).hasClass('eui-textTruncate').hasText('Hello world');
      assert.strictEqual(css(text).textOverflow, 'ellipsis');
      assert.strictEqual(css(text).whiteSpace, 'nowrap');
      assert.strictEqual(css(text).fontSize, css('[data-p="ref-m"]').fontSize);
      assert.strictEqual(css(text).color, rgb(light.colors.textParagraph));
      const describedBy = button.getAttribute('aria-describedby')!;
      const description = document.getElementById(describedBy)!;
      assert.true(description.hidden);
      assert.strictEqual(description.textContent!.trim(), 'Click to edit this text inline.');

      await click(button);
      const input = el<HTMLInputElement>(inside('m', INPUT));
      assert.strictEqual(document.activeElement, input, 'input focused');
      assert.strictEqual(input.value, 'Hello world');
      assert.dom(input).hasAttribute('aria-label', 'Edit name').hasClass('euiFieldText');
      const instructions = document.getElementById(
        input.getAttribute('aria-describedby')!.split(' ')[0]!
      )!;
      assert.strictEqual(
        instructions.textContent!.trim(),
        'Press Enter to save your edited text. Press Escape to cancel your edit.'
      );
      assert.strictEqual(box(input).height, 40);
      assert.strictEqual(css(input).fontSize, css('[data-p="ref-m"]').fontSize, 'input uses the text size');
      assert.dom(inside('m', SAVE)).hasAttribute('aria-label', 'Save edit');
      assert.dom(inside('m', CANCEL)).hasAttribute('aria-label', 'Cancel edit');
      assert.strictEqual(box(inside('m', SAVE)).height, 40, 'medium icon buttons');
      assert.strictEqual(css(inside('m', SAVE)).backgroundColor, rgb(base(lightContext, 'success').backgroundColor));
      assert.strictEqual(css(inside('m', CANCEL)).backgroundColor, rgb(base(lightContext, 'danger').backgroundColor));
      assert.dom(inside('m', '[data-icon-type="check"]')).exists();
      assert.dom(inside('m', '[data-icon-type="cross"]')).exists();
      assert.dom(inside('m', '[aria-busy="false"]')).exists('skeleton wrapper not busy');

      await click(inside('s', READ));
      const small = el<HTMLInputElement>(inside('s', INPUT));
      assert.strictEqual(box(small).height, 32, 'compressed field for small sizes');
      assert.strictEqual(css(small).fontSize, css('[data-p="ref-s"]').fontSize);
      assert.strictEqual(box(inside('s', SAVE)).height, 32);
    });

    test('keyboard save and cancel, buttons, callbacks and focus return', async function (assert) {
      const calls: unknown[][] = [];
      const onSave = (value: string) => calls.push(['save', value]);
      const onCancel = (value: string) => calls.push(['cancel', value]);
      await render(
        <template>
          <EuiInlineEditText
            @inputAriaLabel="Edit"
            @defaultValue="One"
            @onSave={{onSave}}
            @onCancel={{onCancel}}
          />
        </template>
      );
      await click(READ);
      await fillIn(INPUT, 'Two');
      await triggerKeyEvent(INPUT, 'keydown', 'Enter');
      assert.dom(INPUT).doesNotExist('back to read mode');
      assert.dom(READ).hasText('Two');
      assert.strictEqual(document.activeElement, el(READ), 'focus returns to the button');

      await click(READ);
      await fillIn(INPUT, 'Three');
      await triggerKeyEvent(INPUT, 'keydown', 'Escape');
      assert.dom(READ).hasText('Two', 'escape reverts');
      assert.strictEqual(document.activeElement, el(READ));

      await click(READ);
      assert.strictEqual(el<HTMLInputElement>(INPUT).value, 'Two', 'cancelled text discarded');
      await fillIn(INPUT, 'Four');
      await click(SAVE);
      assert.dom(READ).hasText('Four');

      await click(READ);
      await fillIn(INPUT, 'Five');
      await click(CANCEL);
      assert.dom(READ).hasText('Four');
      assert.deepEqual(calls, [
        ['save', 'Two'],
        ['cancel', 'Two'],
        ['save', 'Four'],
        ['cancel', 'Four']
      ]);
    });

    test('onSave validation, async save with loading and invalid states', async function (assert) {
      class State {
        @tracked isLoading = false;
        @tracked isInvalid = false;
        resolve?: (value: boolean) => void;
        onSave = (value: string) => {
          if (value === '') {
            this.isInvalid = true;
            return false;
          }
          this.isLoading = true;
          return new Promise<boolean>((resolve) => (this.resolve = resolve));
        };
      }
      const state = new State();
      const editModeProps = { formRowProps: { error: 'Required field' } };
      await render(
        <template>
          <EuiEmotionProvider @colorMode="light">
            <EuiInlineEditText
              @inputAriaLabel="Edit"
              @defaultValue="Value"
              @onSave={{state.onSave}}
              @isLoading={{state.isLoading}}
              @isInvalid={{state.isInvalid}}
              @editModeProps={{editModeProps}}
            />
          </EuiEmotionProvider>
        </template>
      );
      await click(READ);
      await fillIn(INPUT, '');
      await triggerKeyEvent(INPUT, 'keydown', 'Enter');
      assert.dom(INPUT).exists('false keeps edit mode');
      const input = el<HTMLInputElement>(INPUT);
      assert.dom(input).hasAttribute('aria-invalid', 'true');
      assert.dom('.euiFormErrorText').hasText('Required field');
      const errorId = el('.euiFormErrorText').id;
      assert.true(input.getAttribute('aria-describedby')!.split(' ').includes(errorId), 'error describes the input');
      assert.strictEqual(css(input).outlineColor, rgb(forms(light)['borderFocused']!), 'focus wins over invalid (upstream :not(:focus))');
      await blur(input);
      assert.strictEqual(css(input).outlineColor, rgb(forms(light)['borderInvalid']!), 'invalid outline once blurred');
      assert.dom('.euiFormControlLayoutIcons [data-icon-type="warning"]').exists('invalid icon');

      state.isInvalid = false;
      await settled();
      assert.dom('.euiFormErrorText').doesNotExist();
      assert.strictEqual(el(INPUT), input, 'same input');

      await fillIn(INPUT, 'Saved later');
      await triggerKeyEvent(INPUT, 'keydown', 'Enter');
      assert.dom(INPUT).exists('pending promise keeps edit mode');
      const busy = el('[data-test-subj="euiSkeletonLoadingAriaWrapper"]');
      assert.dom(busy).hasAttribute('aria-busy', 'true');
      assert.dom(SAVE).doesNotExist('buttons replaced by skeletons');
      const skeletons = busy.querySelectorAll<HTMLElement>('.euiSkeletonRectangle');
      assert.strictEqual(skeletons.length, 2);
      assert.deepEqual([box(skeletons[0]!).width, box(skeletons[0]!).height], [40, 40]);
      assert.strictEqual(css(skeletons[0]!).borderTopLeftRadius, (light.border.radius as unknown as Tokens)['inline']);
      assert.dom('[role="progressbar"]', busy).exists();
      assert.dom('[role="status"]', busy).hasText('Loading');
      assert.dom('.euiBorealisLoadingSpinner', input.parentElement!).exists('field spinner');

      state.resolve!(true);
      state.isLoading = false;
      await settled();
      assert.dom(INPUT).doesNotExist();
      assert.dom(READ).hasText('Saved later');
    });

    test('read-only, placeholder, controlled value and startWithEditOpen', async function (assert) {
      class State {
        @tracked isReadOnly = true;
        @tracked value = 'Controlled';
        cancelled: string[] = [];
        onChange = (event: Event) => {
          this.value = (event.target as HTMLInputElement).value;
        };
        onCancel = (previous: string) => {
          this.cancelled.push(previous);
          this.value = previous;
        };
      }
      const state = new State();
      await render(
        <template>
          <EuiEmotionProvider @colorMode="light">
            <EuiInlineEditText @inputAriaLabel="ro" @defaultValue="Locked" @isReadOnly={{state.isReadOnly}} data-p="ro" />
            <EuiInlineEditText @inputAriaLabel="ph" @placeholder="Add a name" data-p="ph" />
            <EuiInlineEditText @inputAriaLabel="ctl" @value={{state.value}} @onChange={{state.onChange}} @onCancel={{state.onCancel}} data-p="ctl" />
            <EuiInlineEditText @inputAriaLabel="open" @defaultValue="Open" @startWithEditOpen={{true}} data-p="open" />
          </EuiEmotionProvider>
        </template>
      );
      const ro = el<HTMLButtonElement>(inside('ro', READ));
      assert.true(ro.disabled);
      assert.dom(ro).hasAttribute('role', 'paragraph');
      assert.dom('[data-icon-type="pencil"]', ro).doesNotExist('no pencil');
      assert.strictEqual(css(ro).cursor, 'text');
      assert.strictEqual(css(ro).userSelect, 'text');
      assert.strictEqual(css(ro).color, rgb(light.colors.textParagraph));
      assert.strictEqual(document.getElementById(ro.getAttribute('aria-describedby')!)!.textContent!.trim(), '');

      state.isReadOnly = false;
      await settled();
      assert.strictEqual(el(inside('ro', READ)), ro, 'same button');
      assert.false(ro.disabled);
      assert.dom(ro).doesNotHaveAttribute('role');
      await click(ro);
      assert.dom(inside('ro', INPUT)).exists();
      state.isReadOnly = true;
      await settled();
      assert.dom(inside('ro', INPUT)).doesNotExist('read-only switches back to read mode');
      state.isReadOnly = false;
      await settled();
      assert.dom(inside('ro', INPUT)).doesNotExist('and stays there');

      const ph = el(inside('ph', READ));
      assert.dom(ph).hasText('Add a name');
      assert.strictEqual(css(el('.euiText', ph)).color, rgb(forms(light)['colorHasPlaceholder']!));
      await click(ph);
      assert.dom(inside('ph', INPUT)).hasAttribute('placeholder', 'Add a name').hasValue('');

      await click(inside('ctl', READ));
      await fillIn(inside('ctl', INPUT), 'Changed');
      assert.strictEqual(state.value, 'Changed', 'onChange');
      await triggerKeyEvent(inside('ctl', INPUT), 'keydown', 'Escape');
      assert.strictEqual(state.cancelled.join(','), 'Controlled', 'onCancel gets the read mode value');
      assert.dom(inside('ctl', READ)).hasText('Controlled', 'controlled value restored');

      assert.dom(inside('open', INPUT)).hasValue('Open', 'starts in edit mode');
    });

    test('EuiInlineEditTitle heading levels, sizes and read-only semantics', async function (assert) {
      class State {
        @tracked heading: 'h1' | 'h2' | 'h3' | 'h4' | 'h5' | 'h6' | 'span' = 'h1';
        @tracked isReadOnly = false;
      }
      const state = new State();
      await render(
        <template>
          <EuiEmotionProvider @colorMode="light">
            <EuiInlineEditTitle
              @inputAriaLabel="Title"
              @heading={{state.heading}}
              @isReadOnly={{state.isReadOnly}}
              @defaultValue="My title"
              data-p="t"
            />
            <EuiInlineEditTitle @inputAriaLabel="small" @heading="h3" @size="xs" @defaultValue="Small" data-p="xs" />
            <EuiTitle @size="m" data-p="ref-m">x</EuiTitle>
            <EuiTitle @size="xs" data-p="ref-xs">x</EuiTitle>
          </EuiEmotionProvider>
        </template>
      );
      const root = el('[data-p="t"]');
      assert.dom(root).hasClass('euiInlineEdit').hasClass('euiInlineEditTitle');
      for (const heading of ['h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'span'] as const) {
        state.heading = heading;
        await settled();
        const title = el(`${READ} .euiTitle`, root);
        assert.strictEqual(title.tagName.toLowerCase(), heading, heading);
      }
      state.heading = 'h2';
      await settled();
      const title = el(`${READ} .euiTitle`, root);
      assert.dom(title).hasClass('eui-textTruncate').doesNotHaveAttribute('role');
      assert.strictEqual(css(title).fontSize, css('[data-p="ref-m"]').fontSize);
      assert.strictEqual(css(title).fontWeight, css('[data-p="ref-m"]').fontWeight);
      assert.strictEqual(css(title).marginTop, '0px');
      assert.strictEqual(css(title).textOverflow, 'ellipsis');
      assert.strictEqual(box(el(READ, root)).height, 40);
      assert.strictEqual(box(inside('xs', READ)).height, 32, 'small title sizes use small buttons');

      state.isReadOnly = true;
      await settled();
      assert.dom(READ, root).hasAttribute('role', 'heading').hasAttribute('aria-level', '2');
      assert.dom(`${READ} h2`, root).hasAttribute('role', 'presentation');
      state.heading = 'span';
      await settled();
      assert.dom(READ, root).hasAttribute('role', 'paragraph').doesNotHaveAttribute('aria-level');

      await click(inside('xs', READ));
      const input = el(inside('xs', INPUT));
      assert.strictEqual(box(input).height, 32, 'compressed');
      assert.strictEqual(css(input).fontSize, css('[data-p="ref-xs"]').fontSize, 'input uses the title size');
      assert.strictEqual(css(input).fontWeight, css('[data-p="ref-xs"]').fontWeight);
    });
  });

  module('EuiSplitButton', function () {
    test('sizes, colors, fill, divider and group semantics', async function (assert) {
      class State {
        @tracked color = 'primary';
        @tracked fill = false;
        @tracked size: 's' | 'm' = 'm';
      }
      const state = new State();
      await render(
        <template>
          <EuiEmotionProvider @colorMode="light">
            <EuiSplitButton @color={{state.color}} @fill={{state.fill}} @size={{state.size}} data-p="a" as |split|>
              <split.ActionPrimary @iconType="save" data-test-subj="primary">Save</split.ActionPrimary>
              <split.ActionSecondary @iconType="gear" aria-label="More" data-test-subj="secondary" />
            </EuiSplitButton>
            <EuiSplitButton @color="text" data-p="text" as |split|>
              <split.ActionPrimary @isIconOnly={{true}} @iconType="refresh" aria-label="Refresh" />
              <split.ActionSecondary @iconType="gear" aria-label="More" />
            </EuiSplitButton>
          </EuiEmotionProvider>
        </template>
      );
      const root = el('[data-p="a"]');
      assert.dom(root).hasClass('euiSplitButton').hasAttribute('role', 'group').hasAttribute('data-size', 'm').doesNotHaveAttribute('data-fill');
      const primary = el('[data-test-subj="primary"]');
      const secondary = el('[data-test-subj="secondary"]');
      assert.dom(primary).hasClass('euiButton').hasClass('euiSplitButtonActionPrimary').hasText('Save');
      assert.dom(secondary).hasClass('euiButtonIcon').hasClass('euiSplitButtonActionSecondary');
      const divider = el('.euiSplitButton__divider', root);
      assert.dom(divider).hasAttribute('aria-hidden', 'true');
      assert.strictEqual(primary.nextElementSibling, divider, 'primary, divider, secondary');
      assert.strictEqual(divider.nextElementSibling, secondary);

      assert.strictEqual(box(root).height, 40);
      assert.strictEqual(css(root).paddingTop, '4px');
      assert.strictEqual(css(root).borderTopLeftRadius, (light.border.radius as unknown as Tokens)['control']);
      assert.strictEqual(css(root).display, 'inline-flex');
      assert.strictEqual(box(primary).height, 32, 'inset action');
      assert.deepEqual([box(secondary).width, box(secondary).height], [32, 32]);
      assert.strictEqual(css(root).backgroundColor, rgb(base(lightContext, 'primary').backgroundColor));
      assert.strictEqual(css(divider).borderInlineStartColor, rgb(colors(light)['borderBasePrimary']!));
      assert.strictEqual(css(divider).borderInlineStartWidth, '1px');
      assert.strictEqual(root.style.getPropertyValue('--euiSplitButtonBorderColor').trim(), colors(light)['borderBasePrimary']);
      assert.strictEqual(css(root, '::after').content, 'none', 'no border outside text color');

      state.size = 's';
      state.fill = true;
      state.color = 'warning';
      await settled();
      assert.strictEqual(el('[data-p="a"]'), root, 'no replacement');
      assert.strictEqual(el('[data-test-subj="primary"]'), primary);
      assert.dom(root).hasAttribute('data-size', 's').hasAttribute('data-fill', 'true');
      assert.strictEqual(box(root).height, 32);
      assert.strictEqual(box(primary).height, 24);
      assert.deepEqual([box(secondary).width, box(secondary).height], [24, 24]);
      assert.strictEqual(css(root).backgroundColor, rgb(filled(lightContext, 'warning').backgroundColor));
      assert.strictEqual(css(primary).backgroundColor, rgb(filled(lightContext, 'warning').backgroundColor), 'filled actions');
      assert.strictEqual(css(divider).borderInlineStartColor, rgb(filled(lightContext, 'warning').color), 'warning fill divider');

      const text = el('[data-p="text"]');
      assert.dom('.euiSplitButtonActionPrimary', text).hasClass('euiButtonIcon', 'icon-only primary');
      assert.strictEqual(css(text, '::after').borderTopStyle, 'solid', 'text color has a border');
      assert.strictEqual(css(text, '::after').borderTopColor, rgb(light.colors.borderBasePlain));
      assert.strictEqual(css(text).backgroundColor, rgb(base(lightContext, 'text').backgroundColor));
    });

    test('disabled, loading, popover and tooltip', async function (assert) {
      class State {
        @tracked isDisabled = true;
        @tracked isLoading = false;
        @tracked isOpen = false;
        clicks = 0;
        toggle = () => (this.isOpen = !this.isOpen);
        close = () => (this.isOpen = false);
        onClick = () => this.clicks++;
      }
      const state = new State();
      await render(
        <template>
          <EuiEmotionProvider @colorMode="light">
            <EuiSplitButton @isDisabled={{state.isDisabled}} @isLoading={{state.isLoading}} data-p="d" as |split|>
              <split.ActionPrimary data-test-subj="primary" {{on "click" state.onClick}}>Run</split.ActionPrimary>
              <split.ActionSecondary
                aria-label="Options"
                data-test-subj="secondary"
                @tooltipProps={{hash content="More options"}}
                @popoverProps={{hash isOpen=state.isOpen closePopover=state.close}}
                {{on "click" state.toggle}}
              >
                <p data-test-subj="popover-content">Run later</p>
              </split.ActionSecondary>
            </EuiSplitButton>
            <EuiSplitButton @isDisabled={{true}} data-p="bare" as |split|>
              <split.ActionPrimary>Go</split.ActionPrimary>
              <split.ActionSecondary aria-label="More" @iconType="gear" />
            </EuiSplitButton>
          </EuiEmotionProvider>
        </template>
      );
      const root = el('[data-p="d"]');
      const primary = el<HTMLButtonElement>('[data-test-subj="primary"]');
      const secondary = el<HTMLButtonElement>('[data-test-subj="secondary"]');
      assert.true(primary.disabled);
      assert.true(secondary.disabled);
      assert.strictEqual(css(root).backgroundColor, rgb(light.colors.backgroundBaseDisabled), 'all-disabled background');
      // Upstream's disabled divider rule needs the secondary button as a
      // sibling (`~ .euiSplitButtonActionSecondary:disabled`): a popover or
      // tooltip wrapper keeps the color's divider, a bare action greys it.
      assert.strictEqual(css(inside('d', '.euiSplitButton__divider')).borderInlineStartColor, rgb(colors(light)['borderBasePrimary']!), 'wrapped secondary keeps the divider color');
      assert.strictEqual(css(inside('bare', '.euiSplitButton__divider')).borderInlineStartColor, rgb(light.colors.borderBaseDisabled), 'all-disabled divider');

      state.isDisabled = false;
      await settled();
      assert.false(primary.disabled);
      assert.strictEqual(css(root).backgroundColor, rgb(base(lightContext, 'primary').backgroundColor));
      await click(primary);
      assert.strictEqual(state.clicks, 1);

      assert.dom('[data-icon-type="chevronSingleDown"]', secondary).exists('popover icon is fixed');
      // Like upstream, the popover sets aria-expanded when it opens (the
      // button was disabled when the popover mounted).
      assert.dom(secondary.closest('.euiToolTipAnchor')!).exists('tooltip anchor');
      await click(secondary);
      assert.dom(secondary).hasAttribute('aria-expanded', 'true');
      assert.dom('[data-test-subj="popover-content"]', document.body).hasText('Run later', 'popover content (portalled to the body)');
      assert.strictEqual(el('[data-test-subj="popover-content"]').closest('[data-popover-panel]')!.getAttribute('role'), 'dialog');

      state.isOpen = false;
      state.isLoading = true;
      await settled();
      assert.true(primary.disabled, 'loading disables');
      assert.true(secondary.disabled);
      assert.dom('.euiBorealisLoadingSpinner', primary).exists();
      assert.dom('.euiBorealisLoadingSpinner', secondary).exists();
    });
  });

  module('EuiFormControlButton and EuiFormAppend / EuiFormPrepend', function () {
    test('form control button sizes, value, placeholder and states', async function (assert) {
      class State {
        @tracked compressed = false;
        @tracked isInvalid = false;
      }
      const state = new State();
      await render(
        <template>
          <EuiEmotionProvider @colorMode="light">
            <div style="width: 600px">
              <EuiFormControlButton @value="Selected" @compressed={{state.compressed}} @isInvalid={{state.isInvalid}} data-p="value" />
              <EuiFormControlButton @placeholder="Select an option" @fullWidth={{false}} @iconType="arrowDown" @iconSide="right" data-p="ph" />
              <EuiFormControlButton @value="Busy" @isLoading={{true}} data-p="loading" />
              <EuiFormControlButton @value="Off" @isDisabled={{true}} data-p="disabled" />
            </div>
          </EuiEmotionProvider>
        </template>
      );
      const button = el<HTMLButtonElement>('[data-p="value"]');
      assert.dom(button).hasClass('euiFormControlButton').hasClass('euiButtonEmpty').hasAttribute('type', 'button');
      assert.strictEqual(button.value, 'Selected', 'button value');
      assert.strictEqual(box(button).height, 40);
      assert.strictEqual(box(button).width, 600, 'full width by default');
      assert.strictEqual(css(button).fontWeight, String(light.font.weight.regular));
      assert.strictEqual(css(button).backgroundColor, rgb(forms(light)['background']!));
      assert.strictEqual(css(button).color, rgb(light.colors.textParagraph));
      assert.strictEqual(css(button).paddingInlineStart, '12px');
      const content = el('.euiButtonEmpty__content', button);
      assert.strictEqual(css(content).justifyContent, 'flex-start');
      assert.strictEqual(box(content).width, box(button).width - 24, 'content fills the control');
      const value = el('.eui-textTruncate', button);
      assert.strictEqual(css(value).flexGrow, '1', 'text is a content flex item (no text wrapper)');
      assert.strictEqual(css(value).textAlign, 'start');
      assert.strictEqual(css(value).textOverflow, 'ellipsis');

      state.compressed = true;
      state.isInvalid = true;
      await settled();
      assert.strictEqual(el('[data-p="value"]'), button, 'no replacement');
      assert.strictEqual(box(button).height, 32);
      assert.strictEqual(css(button).paddingInlineStart, '8px');
      assert.strictEqual(css(button).outlineColor, rgb(forms(light)['borderInvalid']!));

      const ph = el<HTMLButtonElement>('[data-p="ph"]');
      assert.strictEqual(box(ph).width, 400, 'form width');
      assert.strictEqual(ph.value, '', 'no value');
      assert.strictEqual(css(el('.eui-textTruncate', ph)).color, rgb(forms(light)['colorDisabled']!), 'placeholder color');
      const phIcon = el('[data-icon-type="arrowDown"]', ph);
      assert.true(box(phIcon).left > box(el('.eui-textTruncate', ph)).right - 1, 'icon on the right');

      const loading = el<HTMLButtonElement>('[data-p="loading"]');
      assert.true(loading.disabled);
      assert.dom('.euiBorealisLoadingSpinner', loading).exists();
      assert.strictEqual(css(loading).backgroundColor, rgb(forms(light)['background']!), 'loading keeps the form background');

      const disabled = el<HTMLButtonElement>('[data-p="disabled"]');
      assert.true(disabled.disabled);
      assert.strictEqual(css(disabled).backgroundColor, rgb(forms(light)['backgroundDisabled']!));
    });

    test('append/prepend: label vs button vs icons, layout context, compressed and disabled', async function (assert) {
      class State {
        @tracked compressed = false;
        @tracked disabled = false;
        clicks = 0;
        onClick = () => this.clicks++;
      }
      const state = new State();
      const extra = { fontStyle: 'italic' };
      await render(
        <template>
          <EuiEmotionProvider @colorMode="light">
            <EuiFieldText @id="field-a" @compressed={{state.compressed}} @disabled={{state.disabled}} data-p="field">
              <:prepend>
                <EuiFormPrepend @label="Prefix" @iconLeft="user" @css={{extra}} data-p="prepend" />
              </:prepend>
              <:append>
                <EuiFormAppend @label="Action" @iconRight="arrowDown" @onClick={{state.onClick}} data-p="append" />
              </:append>
            </EuiFieldText>
            <EuiFormControlLayout @inputId="plain" @isDisabled={{true}}>
              <:prepend><EuiFormPrepend @element="button" @label="Open" data-p="layout-button" /></:prepend>
              <:field><input id="plain" aria-label="plain" /></:field>
            </EuiFormControlLayout>
            <EuiFormAppend @label="Standalone" @inputId="other" @compressed={{true}} @isDisabled={{true}} @element="button" data-p="standalone" />
          </EuiEmotionProvider>
        </template>
      );
      const prepend = el('[data-p="prepend"]');
      assert.strictEqual(prepend.tagName, 'DIV');
      assert.dom(prepend).hasClass('euiFormPrepend');
      assert.dom(prepend.parentElement!.parentElement!).hasClass('euiFormControlLayout__prepend', 'wrapper inside the side node');
      const label = el<HTMLLabelElement>('label.euiFormLabel', prepend);
      assert.strictEqual(label.htmlFor, 'field-a', 'label points to the field id from the layout');
      assert.dom('[data-icon-type="user"]', prepend).exists();
      assert.strictEqual(prepend.firstElementChild!.getAttribute('data-icon-type'), 'user', 'left icon first');
      assert.strictEqual(css(prepend).paddingInlineStart, '8px');
      assert.strictEqual(css(prepend).paddingInlineEnd, '8px');
      assert.strictEqual(css(prepend).columnGap, '8px');
      assert.strictEqual(css(prepend).fontStyle, 'italic', '@css composed last');
      assert.strictEqual(box(el('.euiFormControlLayout__prepend')).height, 40);
      assert.strictEqual(box(prepend).height, 32, 'side content height (upstream side node pads by size.xs)');

      const append = el<HTMLButtonElement>('[data-p="append"]');
      assert.strictEqual(append.tagName, 'BUTTON', '@onClick renders a button');
      assert.dom(append).hasClass('euiFormAppend').hasAttribute('type', 'button');
      const span = el('span.euiFormLabel', append);
      assert.dom(span).hasClass('eui-textTruncate').hasText('Action');
      assert.strictEqual(css(append).color, rgb(euiButtonPrimaryText()), 'interactive primary color');
      assert.strictEqual(css(span).color, css(append).color, 'label takes the button color');
      assert.strictEqual(css(append).backgroundColor, rgb(forms(light)['background']!));
      assert.strictEqual(css(append).cursor, 'pointer');
      assert.strictEqual(append.lastElementChild!.getAttribute('data-icon-type'), 'arrowDown', 'right icon last');
      await click(append);
      assert.strictEqual(state.clicks, 1);
      const field = el('[data-p="field"]');
      assert.true(box(append).left >= box(field).right - 1, 'append after the input');
      assert.true(box(prepend).right <= box(field).left + 1, 'prepend before the input');

      state.compressed = true;
      state.disabled = true;
      await settled();
      assert.strictEqual(el('[data-p="prepend"]'), prepend, 'no replacement');
      assert.strictEqual(css(prepend).paddingInlineStart, '4px', 'compressed from the layout');
      assert.strictEqual(css(prepend).color, rgb(forms(light)['colorDisabled']!), 'static node follows the disabled layout');
      // EuiFormLabel transitions its color: finish it before reading.
      label.getAnimations().forEach((animation) => animation.finish());
      assert.strictEqual(css(label).color, rgb(forms(light)['colorDisabled']!));
      assert.false(append.disabled, 'buttons are not disabled by the layout');

      const layoutButton = el<HTMLButtonElement>('[data-p="layout-button"]');
      assert.strictEqual(layoutButton.tagName, 'BUTTON');
      assert.false(layoutButton.disabled);

      const standalone = el<HTMLButtonElement>('[data-p="standalone"]');
      assert.true(standalone.disabled);
      assert.strictEqual(css(standalone).paddingInlineStart, '4px');
      assert.strictEqual(css(standalone).color, rgb(forms(light)['colorDisabled']!));
      assert.dom('label', standalone).doesNotExist('no label element in a button');
    });

    test('form control button inherits the layout context', async function (assert) {
      class State {
        @tracked compressed = true;
        @tracked isInvalid = true;
      }
      const state = new State();
      await render(
        <template>
          <EuiEmotionProvider @colorMode="light">
            <EuiFormControlLayout @compressed={{state.compressed}} @isInvalid={{state.isInvalid}} @isDisabled={{true}} @isLoading={{true}}>
              <EuiFormControlButton @value="In layout" data-p="in" />
            </EuiFormControlLayout>
          </EuiEmotionProvider>
        </template>
      );
      const button = el<HTMLButtonElement>('[data-p="in"]');
      assert.strictEqual(box(button).height, 32, 'compressed from the layout');
      assert.true(button.disabled, 'disabled from the layout');
      assert.dom('.euiBorealisLoadingSpinner', button).doesNotExist('the layout shows the spinner');
      state.compressed = false;
      await settled();
      assert.strictEqual(box(button).height, 40);
    });
  });

  test('light/dark nearest provider, sibling isolation and JS-object overrides', async function (assert) {
    class State {
      @tracked mode: EuiColorMode = 'light';
      @tracked overrides: EuiBorealisOverrides = {};
    }
    const state = new State();
    const own: EuiBorealisOverrides = { border: { radius: { control: '13px' } } };
    await render(
      <template>
        <EuiEmotionProvider @colorMode={{state.mode}} @borealisOverrides={{state.overrides}}>
          <EuiSplitButton data-p="parent" as |split|>
            <split.ActionPrimary>A</split.ActionPrimary>
            <split.ActionSecondary @iconType="gear" aria-label="More" />
          </EuiSplitButton>
          <EuiInlineEditText @inputAriaLabel="x" @placeholder="Empty" data-p="parent-edit" />
          <EuiFormControlButton @placeholder="Pick" data-p="parent-button" />
          <EuiEmotionProvider @borealisOverrides={{own}}>
            <EuiSplitButton data-p="child" as |split|>
              <split.ActionPrimary>A</split.ActionPrimary>
              <split.ActionSecondary @iconType="gear" aria-label="More" />
            </EuiSplitButton>
          </EuiEmotionProvider>
          <EuiEmotionProvider @colorMode="light">
            <EuiSplitButton data-p="fixed" as |split|>
              <split.ActionPrimary>A</split.ActionPrimary>
              <split.ActionSecondary @iconType="gear" aria-label="More" />
            </EuiSplitButton>
          </EuiEmotionProvider>
        </EuiEmotionProvider>
        <EuiEmotionProvider @colorMode="light">
          <EuiSplitButton data-p="sibling" as |split|>
            <split.ActionPrimary>A</split.ActionPrimary>
            <split.ActionSecondary @iconType="gear" aria-label="More" />
          </EuiSplitButton>
        </EuiEmotionProvider>
      </template>
    );
    const background = (key: string) => css(`[data-p="${key}"]`).backgroundColor;
    assert.strictEqual(background('parent'), rgb(base(lightContext, 'primary').backgroundColor));
    assert.strictEqual(css(inside('parent-edit', '.euiText')).color, rgb(forms(light)['colorHasPlaceholder']!));
    assert.strictEqual(css('[data-p="parent-button"]').backgroundColor, rgb(forms(light)['background']!));

    state.mode = 'dark';
    await settled();
    assert.strictEqual(background('parent'), rgb(base(darkContext, 'primary').backgroundColor));
    assert.strictEqual(css('[data-p="parent"] .euiSplitButton__divider').borderInlineStartColor, rgb(colors(dark)['borderBasePrimary']!));
    assert.strictEqual(css(inside('parent-edit', '.euiText')).color, rgb(forms(dark)['colorHasPlaceholder']!));
    assert.strictEqual(css('[data-p="parent-button"]').backgroundColor, rgb(forms(dark)['background']!));
    assert.strictEqual(background('child'), rgb(base(darkContext, 'primary').backgroundColor), 'child inherits');
    assert.strictEqual(background('fixed'), rgb(base(lightContext, 'primary').backgroundColor), 'light island');
    assert.strictEqual(background('sibling'), rgb(base(lightContext, 'primary').backgroundColor), 'sibling isolated');
    assert.strictEqual(css('[data-p="child"]').borderTopLeftRadius, '13px', 'override');
    assert.strictEqual(css('[data-p="parent"]').borderTopLeftRadius, '8px');

    state.overrides = { border: { radius: { control: '4px' } } };
    await settled();
    assert.strictEqual(css('[data-p="parent"]').borderTopLeftRadius, '4px');
    assert.strictEqual(css('[data-p="child"]').borderTopLeftRadius, '13px', 'nearest override wins');
    assert.strictEqual(css('[data-p="sibling"]').borderTopLeftRadius, '8px');
  });

  test('RTL and high contrast', async function (assert) {
    await render(
      <template>
        <div dir="rtl">
          <EuiSplitButton data-p="rtl" as |split|>
            <split.ActionPrimary data-test-subj="rtl-primary">A</split.ActionPrimary>
            <split.ActionSecondary @iconType="gear" aria-label="More" data-test-subj="rtl-secondary" />
          </EuiSplitButton>
          <EuiFieldText @id="rtl-field" data-p="rtl-field">
            <:prepend><EuiFormPrepend @label="Pre" data-p="rtl-prepend" /></:prepend>
          </EuiFieldText>
          <EuiInlineEditText @inputAriaLabel="x" @defaultValue="RTL" data-p="rtl-edit" />
        </div>
        <EuiEmotionProvider @highContrastMode="preferred">
          <EuiSplitButton data-p="hc" as |split|>
            <split.ActionPrimary>A</split.ActionPrimary>
            <split.ActionSecondary @iconType="gear" aria-label="More" />
          </EuiSplitButton>
          <EuiSplitButton @fill={{true}} data-p="hc-fill" as |split|>
            <split.ActionPrimary>A</split.ActionPrimary>
            <split.ActionSecondary @iconType="gear" aria-label="More" />
          </EuiSplitButton>
        </EuiEmotionProvider>
        <EuiEmotionProvider @colorMode="light">
          <EuiSplitButton data-p="standard" as |split|>
            <split.ActionPrimary>A</split.ActionPrimary>
            <split.ActionSecondary @iconType="gear" aria-label="More" />
          </EuiSplitButton>
        </EuiEmotionProvider>
      </template>
    );
    assert.true(box('[data-test-subj="rtl-primary"]').left > box('[data-test-subj="rtl-secondary"]').right - 1, 'primary at the inline start (right)');
    const divider = el('[data-p="rtl"] .euiSplitButton__divider');
    assert.strictEqual(css(divider).borderRightWidth, '1px', 'logical divider border flips');
    assert.true(box('[data-p="rtl-prepend"]').left >= box('[data-p="rtl-field"]').right - 1, 'prepend on the right');
    const editButton = el(inside('rtl-edit', READ));
    const pencil = el('[data-icon-type="pencil"]', editButton);
    assert.true(box(pencil).right <= box(el('.euiText', editButton)).left + 1, 'pencil at the inline end (left)');

    const hc = css('[data-p="hc"]', '::after');
    assert.strictEqual(hc.borderTopStyle, 'solid', 'preferred contrast border');
    assert.strictEqual(hc.borderTopColor, rgb(colors(resolveBorealisTheme('light', {}, 'preferred').euiTheme)['borderBasePrimary']!));
    assert.strictEqual(css('[data-p="hc-fill"]', '::after').content, 'none', 'no border on enabled filled buttons');
    assert.strictEqual(css('[data-p="standard"]', '::after').content, 'none', 'standard contrast isolated');
  });
});

/** Upstream empty primary button text color (EuiFormPrepend `isInteractive`). */
function euiButtonPrimaryText() {
  const values = euiButtonDisplaysColors(lightContext) as unknown as Record<
    string,
    Record<string, { styles: string }>
  >;
  const match = /(?:^|;)color:([^;]+);/.exec(values['empty']!['primary']!.styles);
  return match![1]!;
}
