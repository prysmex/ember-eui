import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { action } from '@ember/object';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';

import randomId from '../-private/random-id.ts';
import argOrDefault from '../helpers/arg-or-default.ts';
import validatableControl from '../modifiers/validatable-control.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { formControlReset } from '../utils/eui/form-controls.ts';
import { euiTextAreaStyles } from '../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import EuiFormControlLayout from './eui-form-control-layout.gts';

import type { EuiFormControlLayoutSignature } from './eui-form-control-layout';

type EuiTextAreaResize = 'vertical' | 'horizontal' | 'both' | 'none';

/**
 * A multi-line text input, inside an EuiFormControlLayout like upstream.
 * Attributes (`placeholder`, `maxlength`…) go to the `<textarea>`.
 */
export interface EuiTextAreaSignature {
  Element: HTMLTextAreaElement;
  Args: {
    /** Id of the textarea. Defaults to a random id. */
    id?: string;
    /** The value; `null` leaves it empty. Update it from `{{on "input" …}}`. */
    value?: string | null;
    /** Stretches the textarea to its container's width. */
    fullWidth?: boolean;
    /** Tighter padding (8px instead of 12px) and 3 default rows, for dense forms. */
    compressed?: boolean;
    /** Disables the textarea. */
    disabled?: boolean;
    /**
     * Shows the invalid state (danger border), sets `aria-invalid` and marks
     * it invalid for native form validation.
     */
    isInvalid?: boolean;
    /** Icon inside the textarea, anything `EuiIcon`'s `@type` accepts. */
    icon?: EuiFormControlLayoutSignature['Args']['icon'];
    /** Shows a spinner inside the textarea. */
    isLoading?: boolean;
    /**
     * Shows a button that clears the textarea. It empties the value, fires
     * an `input` event (so your `{{on "input"}}` handler sees it) and
     * focuses the textarea.
     */
    isClearable?: boolean;
    /** Called with the `<textarea>` element once rendered. */
    inputRef?: (element: HTMLTextAreaElement | null) => void;
    /** Visible number of lines. Defaults to 6, or 3 when `@compressed`. */
    rows?: number;
    /**
     * Which way the user can resize it: `'vertical'`, `'horizontal'`,
     * `'both'` or `'none'`. Defaults to `'vertical'`.
     */
    resize?: EuiTextAreaResize;
    /** Makes the textarea read-only. */
    readOnly?: boolean;
  };
  Blocks: {
    /** Unused. */
    default: [];
  };
}

/** A textarea on the upstream EUI 123 / Borealis form control styles. */
export default class EuiTextArea extends Component<EuiTextAreaSignature> {
  textArea: HTMLTextAreaElement | null = null;

  @cached
  get layoutCss() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiTextAreaStyles);

    return styles.formControlLayout.euiTextArea;
  }

  clear = {
    onClick: () => this.clearValue(),
    'data-test-subj': 'clearTextAreaButton'
  };

  clearValue() {
    const textArea = this.textArea;

    if (!textArea) return;

    // updates the displayed value and fires the `input` listeners
    const setValue = Object.getOwnPropertyDescriptor(
      window.HTMLTextAreaElement.prototype,
      'value'
    )!.set!;

    setValue.call(textArea, '');
    textArea.dispatchEvent(
      new Event('input', { bubbles: true, cancelable: false })
    );
    textArea.focus();
  }

  @action
  registerTextArea(element: HTMLTextAreaElement) {
    this.textArea = element;
    this.args.inputRef?.(element);
  }

  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiTextAreaStyles);
    const { compressed, fullWidth, resize } = this.args;
    return `euiTextArea ${euiClass(
      context,
      formControlReset,
      styles.euiTextArea,
      styles.resize[resize ?? 'vertical'] ?? styles.resize.vertical,
      compressed ? styles.compressed : styles.uncompressed,
      fullWidth ? styles.fullWidth : styles.formWidth
    )}`;
  }
  get rows() {
    return this.args.rows ? this.args.rows : this.args.compressed ? 3 : 6;
  }

  <template>
    {{#let (argOrDefault @id (randomId)) as |id|}}
      <EuiFormControlLayout
        class="euiFormControlLayout--euiTextArea"
        @fullWidth={{@fullWidth}}
        @isLoading={{@isLoading}}
        @isInvalid={{@isInvalid}}
        @isDisabled={{@disabled}}
        @clear={{if @isClearable this.clear}}
        @icon={{@icon}}
        @css={{this.layoutCss}}
      >
        <textarea
          id={{id}}
          value={{@value}}
          class={{this.classes}}
          rows={{this.rows}}
          disabled={{@disabled}}
          readonly={{@readOnly}}
          aria-invalid={{if @isInvalid "true"}}
          ...attributes
          {{validatableControl @isInvalid}}
          {{didInsert this.registerTextArea}}
        >
          {{yield}}
        </textarea>
      </EuiFormControlLayout>
    {{/let}}
  </template>
}
