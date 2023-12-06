import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import validatableControl from '../modifiers/validatable-control';

import optional from 'ember-composable-helpers/helpers/optional';

import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';
import uniqueId from 'ember-unique-id-helper-polyfill/helpers/unique-id';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

import { resizeMapping } from '../utils/css-mappings/eui-text-area';

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
    (argOrDefault @id (uniqueId))
    as |classes definedRows id|
  }}
    <textarea
      id={{id}}
      value={{@value}}
      class={{classes}}
      rows={{definedRows}}
      disabled={{@disabled}}
      ...attributes
      {{validatableControl @isInvalid}}
      {{didInsert (optional @inputRef)}}
    >
      {{yield}}
    </textarea>
  {{/let}}
</template>;

export default EuiTextArea;
