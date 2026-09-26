import { hash } from '@ember/helper';
import { EuiFormRow } from '@ember-eui/core/components';
import { argOrDefault } from '@ember-eui/core/helpers';

import randomId from '../../../-private/random-id.ts';
import Base from './base.gts';

import type { BaseSignature } from './base';
import type { EuiFormRowSignature } from '@ember-eui/core/components/eui-form-row';

/**
 * An EuiFormRow bound to `@fieldName` for your own control: it yields what
 * the control needs and shows the field's errors.
 */
export interface EuiChangesetFormFieldBaseSignature {
  Args: BaseSignature['Args'] & EuiFormRowSignature['Args'];
  Blocks: {
    /**
     * Yields `{ id, formId, isInvalid, validate, disabled }`: give the
     * control the `id`, set the changeset value yourself and call
     * `validate()`.
     */
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
