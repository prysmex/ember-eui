import { hash } from '@ember/helper';
import { EuiFormRow } from '@ember-eui/core/components';
import { argOrDefault } from '@ember-eui/core/helpers';

import randomId from '../../../-private/random-id';
import Base from './base';

import type { BaseSignature } from './base';
import type { EuiFormRowSignature } from '@ember-eui/core/components/eui-form-row';

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
    {{#let (argOrDefault @id (randomId)) as |theId|}}
      <EuiFormRow
        class={{this.rowClasses}}
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
