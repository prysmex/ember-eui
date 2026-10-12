import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';

import optional from '@nullvoxpopuli/ember-composable-helpers/helpers/optional';

import randomId from '../-private/random-id.ts';
import argOrDefault from '../helpers/arg-or-default.ts';
import validatableControl from '../modifiers/validatable-control.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { formControlReset } from '../utils/eui/form-controls.ts';
import { euiTextAreaStyles } from '../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';

type EuiTextAreaResize = 'vertical' | 'horizontal' | 'both' | 'none';

/** A multi-line text input. Attributes (`placeholder`, `maxlength`…) go to the `<textarea>`. */
export interface EuiTextAreaSignature {
  Element: HTMLTextAreaElement;
  Args: {
    /** Id of the textarea. Defaults to a random id. */
    id?: string;
    /** The value. Update it from `{{on "input" …}}`. */
    value?: string;
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
        {{didInsert (optional @inputRef)}}
      >
        {{yield}}
      </textarea>
    {{/let}}
  </template>
}
