import didInsert from '@ember/render-modifiers/modifiers/did-insert';

import optional from '@nullvoxpopuli/ember-composable-helpers/helpers/optional';

import randomId from '../-private/random-id.ts';
import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import validatableControl from '../modifiers/validatable-control.ts';

import type { resizeMapping } from '../utils/css-mappings/eui-text-area.ts';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

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
    /** Smaller textarea, for dense forms. */
    compressed?: boolean;
    /** Disables the textarea. */
    disabled?: boolean;
    /** Shows the invalid state and marks it invalid for native form validation. */
    isInvalid?: boolean;
    /** Called with the `<textarea>` element once rendered. */
    inputRef?: (element: HTMLTextAreaElement | null) => void;
    /** Visible number of lines. */
    rows?: number;
    /**
     * Which way the user can resize it: `'vertical'`, `'horizontal'`,
     * `'both'` or `'none'`. Defaults to `'vertical'`.
     */
    resize?: keyof typeof resizeMapping;
    /** Makes the textarea read-only. */
    readOnly?: boolean;
  };
  Blocks: {
    /** Unused. */
    default: [];
  };
}

const EuiTextArea: TemplateOnlyComponent<EuiTextAreaSignature> = <template>
  {{#let
    (classNames
      (if @fullWidth "euiTextArea--fullWidth")
      (if @compressed "euiTextArea--compressed")
      componentName="EuiTextArea"
      resize=(argOrDefault @resize "vertical")
    )
    (if @rows @rows (if @compressed 3 6))
    (argOrDefault @id (randomId))
    as |classes definedRows id|
  }}
    <textarea
      id={{id}}
      value={{@value}}
      class={{classes}}
      rows={{definedRows}}
      disabled={{@disabled}}
      readonly={{@readOnly}}
      ...attributes
      {{validatableControl @isInvalid}}
      {{didInsert (optional @inputRef)}}
    >
      {{yield}}
    </textarea>
  {{/let}}
</template>;

export default EuiTextArea;
