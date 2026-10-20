import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { action, get } from '@ember/object';
import { scheduleOnce } from '@ember/runloop';
import type Owner from '@ember/owner';

import {
  buildValidationMessages,
  notifyValidityChange
} from '../../utils/build-validation-messages.js';

import type { ComponentLike } from '@glint/template';

/**
 * Args every ValidatedForm field takes (on top of EuiFormRow's and its
 * control's). The form's yielded fields pass `register`, `unregister`,
 * `onValidityChange` and `formId` for you.
 */
export interface FieldBaseSignature<T = ComponentLike> {
  Args: {
    /** Id of the control; the row's label points to it. Defaults to a random id. */
    id?: string;
    /** The field's value. Update it in `@onChange`. */
    value: any;
    /** The row's label. */
    label?: string;
    /** Errors from outside (e.g. the server), shown with the validation errors. */
    error?: string[];
    /** Options, for fields with options (select, radios, checkboxes, combo box). */
    options?: any[];
    /**
     * ember-validators validations by name, e.g.
     * `(hash presence=(hash presence=true) length=(hash min=3))` or
     * `format=(hash type="email")`. Errors show once the field is touched
     * (blurred, or the form submitted).
     */
    validations?: any;
    /**
     * Each validation returns `true` when valid; otherwise `false` (generic
     * "is invalid" message), a message string, or an ember-validators result
     * (`{ type, context }`).
     */
    customValidations?: {
      validation(
        value: any,
        options?: Record<string, unknown>
      ): boolean | string | { type?: string; context?: Record<string, unknown> };
      params?: Record<string, unknown>;
    }[];
    /** Classes for the EuiFormRow. */
    rowClasses?: string;
    /** @deprecated Has no effect. */
    rowExtra?: Record<string, unknown>;
    /** Called with the new value; update `@value` here. */
    onChange: (value: any) => void;
    /** @private Set by ValidatedForm. */
    onValidityChange: (isValid: boolean) => void;
    /** @private Set by ValidatedForm. */
    register: (field: T) => void;
    /** @private Set by ValidatedForm. */
    unregister: (field: T) => void;
  };
}

export default class ValidatedFormFieldBase<
  T extends FieldBaseSignature = FieldBaseSignature
> extends Component<T> {
  validationProperty = 'args.value';

  //cache for comparing
  lastIsValid?: boolean;
  lastIsTouched?: boolean;

  @tracked isTouched = false;

  /**
   * The messages of `@validations` and `@customValidations` for the current
   * value. Derived, so a field renders once with its messages on insert and
   * once per value change (they used to be stored after each render, which
   * rendered every field twice).
   */
  @cached
  get derivedValidationErrorMessages(): string[] {
    return this.derivedValidation.messages;
  }

  // The messages with the value they were derived for (see didUpdateValue).
  @cached
  private get derivedValidation(): { messages: string[]; value: unknown } {
    void this.revision;

    return {
      messages: buildValidationMessages.call(this, this.validationProperty),
      value: get(this, this.validationProperty as keyof this)
    };
  }

  // Derives the messages again when a subclass validates a property that is
  // not tracked.
  @tracked private revision = 0;

  /**
   * An assignment (subclasses used to store the messages here) shows until
   * the value or the validations change.
   */
  @tracked private _assignedMessages?: {
    messages: null | string[];
    for: string[];
  };

  get _validationErrorMessages(): null | string[] {
    const derived = this.derivedValidationErrorMessages;
    const assigned = this._assignedMessages;

    return assigned && assigned.for === derived ? assigned.messages : derived;
  }

  set _validationErrorMessages(messages: null | string[]) {
    this._assignedMessages = {
      messages,
      for: this.derivedValidationErrorMessages
    };
  }

  formRowElement: HTMLElement | null = null;

  get validations() {
    return this.args.validations || {};
  }

  get hasErrorMessages(): boolean {
    return !!this._validationErrorMessages?.length || this.error?.length > 0;
  }

  get isValid() {
    return !this.isInvalid;
  }

  get isInvalid() {
    return this.hasErrorMessages;
  }

  get isInvalidAndTouched() {
    return !!(this.isInvalid && this.isTouched);
  }

  get formHasBeenValidated() {
    return this.isTouched;
  }

  set formHasBeenValidated(value) {
    this.isTouched = value;
  }

  get customValidations(): NonNullable<
    FieldBaseSignature['Args']['customValidations']
  > {
    return this.args.customValidations || [];
  }

  get rowClasses(): string {
    return this.args.rowClasses || '';
  }

  get rowExtra() {
    return this.args.rowExtra || {};
  }

  get label(): string {
    return this.args.label || '';
  }

  get error(): string[] {
    return this.args.error || [];
  }

  get options(): any[] {
    return this.args.options || [];
  }

  get validationErrorMessages() {
    const error = [];

    if (this.error.length > 0) {
      error.push(...this.error);
    }

    if (
      this._validationErrorMessages &&
      this._validationErrorMessages.length > 0
    ) {
      error.push(...this._validationErrorMessages);
    }

    if (error.length === 0) {
      return null;
    }

    return error;
  }

  constructor(owner: Owner, args: T['Args']) {
    super(owner, args);
    this.args.register?.(this as unknown as ComponentLike);
  }

  // Run by the field's row on insert: the form finds the field of a row.
  @action
  setValidationMessages(ele?: HTMLElement) {
    if (ele) {
      this.formRowElement = ele;
    }
  }

  // Run by the field's row when the value or the validations change. The
  // messages update with them; tell the form after this render, in the same
  // run loop.
  @action
  didUpdateValue() {
    if (
      get(this, this.validationProperty as keyof this) !==
      this.derivedValidation.value
    ) {
      this.revision++;
    }

    scheduleOnce('afterRender', this, this.notifyValidityChangeIfAlive);
  }

  private notifyValidityChangeIfAlive() {
    if (!this.isDestroyed && !this.isDestroying) {
      this.notifyValidityChange();
    }
  }

  @action
  notifyValidityChange() {
    notifyValidityChange(this, this.args.onValidityChange);
  }

  @action
  setIsTouched(val: boolean) {
    this.isTouched = val;
    this.notifyValidityChange();
  }

  /**
   * This is just a default handleChange, you should override this method
   * if you need to or use whatever mechanism to bubble the changed
   * value outside and then notifyValidityChanges
   *
   * @override
   * @param {*} e
   */
  @action
  handleChange(e: Event) {
    const value = (e.target as HTMLInputElement).value;

    this.args.onChange(value);
    this.notifyValidityChange();
  }

  willDestroy(): void {
    super.willDestroy();
    
    this.args.unregister?.(this as unknown as ComponentLike);
    this.formRowElement = null;
  }

  <template>
    {{!@glint-expect-error}}
    {{yield this}}
  </template>
}
