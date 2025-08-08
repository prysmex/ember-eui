import didInsert from '@ember/render-modifiers/modifiers/did-insert';

import optional from 'ember-composable-helpers/helpers/optional';

import randomId from '../-private/random-id';
import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';
import validatableControl from '../modifiers/validatable-control';

import type { resizeMapping } from '../utils/css-mappings/eui-text-area';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiTextAreaSignature {
  Element: HTMLTextAreaElement;
  Args: {
    id?: string;
    value?: string;
    fullWidth?: boolean;
    compressed?: boolean;
    disabled?: boolean;
    isInvalid?: boolean;
    inputRef?: (element: HTMLTextAreaElement | null) => void;
    rows?: number;
    resize?: keyof typeof resizeMapping;
    readOnly?: boolean;
  };
  Blocks: {
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
