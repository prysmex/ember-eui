import Base from './base';
import type { BaseSignature } from './base';
import { EuiFormRow } from '@ember-eui/core/components';
import type { EuiFormRowSignature } from '@ember-eui/core/components/eui-form-row';
import { argOrDefault } from '@ember-eui/core/helpers';
import uniqueId from 'ember-unique-id-helper-polyfill/helpers/unique-id';
import { hash } from '@ember/helper';

export interface EuiChangesetFormFieldBaseSignature {
  Args: BaseSignature['Args'] & EuiFormRowSignature['Args'];
  Blocks: {
    default: [
      {
        id: string;
        formId?: string;
        isInvalid: boolean;
        validate: (value: unknown) => void;
        disabled?: boolean;
      }
    ];
  };
}

export default class EuiChangesetFormFieldCheckbox extends Base<EuiChangesetFormFieldBaseSignature> {
  <template>
    {{#let (argOrDefault @id (uniqueId)) as |theId|}}
      <EuiFormRow
        class={{@rowClasses}}
        @labelType={{@labelType}}
        @display={{@display}}
        @hasEmptyLabelSpace={{@hasEmptyLabelSpace}}
        @fullWidth={{@fullWidth}}
        @hasChildLabel={{@hasChildLabel}}
        @label={{@label}}
        @labelAppend={{@labelAppend}}
        @id={{theId}}
        @isInvalid={{this.isInvalid}}
        @error={{this.errors}}
        @helpText={{@helpText}}
        @errorClasses={{@errorClasses}}
      >
        {{yield
          (hash
            id=theId
            formId=@formId
            isInvalid=this.isInvalid
            validate=this.validate
            disabled=@disabled
          )
        }}
      </EuiFormRow>
    {{/let}}
  </template>
}
