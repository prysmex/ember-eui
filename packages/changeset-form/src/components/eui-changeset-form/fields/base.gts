import Component from '@glimmer/component';
import { assert } from '@ember/debug';
import { action } from '@ember/object';
import { later } from '@ember/runloop';
import type Owner from '@ember/owner';

import type { BufferedChangeset } from 'ember-changeset/types';

export interface BaseSignature {
  Args: {
    changeset: BufferedChangeset;
    fieldName: string;
    errors?: string[];
    rowClasses?: string;
    formId?: string;
    disabled?: boolean;
  };
}

export interface ValidationError {
  key: string;
  value: unknown;
  validation: string[] | string;
}

export default class ChangesetFormFieldsBase<
  T extends BaseSignature = BaseSignature
> extends Component<T> {
  constructor(owner: Owner, args: T['Args']) {
    super(owner, args);

    assert(
      '<EuiChangesetForm> fields must receive @changeset',
      typeof this.args.changeset !== 'undefined'
    );

    assert(
      '<EuiChangesetForm> fields must reeceive @fieldName',
      typeof this.args.fieldName !== 'undefined'
    );
  }

  get rowClasses(): string {
    return this.args.rowClasses || '';
  }

  get value(): any {
    return this.args.changeset?.get(this.args.fieldName);
  }

  get errors(): string[] {
    if (typeof this.args.errors !== 'undefined') {
      return this.args.errors;
    }

    const fieldErrors =
      this.args.changeset?.errors.filter((error) => {
        return error.key === this.args.fieldName;
      }) || [];

    let errors: string[] = [];

    fieldErrors.forEach((error) => {
      if (Array.isArray(error.validation)) {
        errors = [...errors, ...(error.validation as string[])];
      } else {
        errors = [...errors, error.validation];
      }
    });

    return errors;
  }

  @action
  async validate(): Promise<void> {
    later(
      this,
      () => {
        this.args.changeset?.validate(this.args.fieldName);
      },
      1
    );
  }

  get isInvalid() {
    return this.errors.length > 0;
  }
}
