import { getContext } from 'ember-provide-consume-context';

/**
 * What an EuiFormControlLayout shares with the EuiFormAppend /
 * EuiFormPrepend / EuiFormControlButton rendered in it (upstream
 * `EuiFormControlLayoutContext`).
 */
export interface EuiFormControlLayoutContext {
  readonly compressed: boolean;
  readonly inputId: string | undefined;
  readonly isDisabled: boolean | undefined;
  readonly isInvalid: boolean | undefined;
  readonly isLoading: boolean | undefined;
  readonly readOnly: boolean | undefined;
}

export const EUI_FORM_CONTROL_LAYOUT_CONTEXT =
  '@ember-eui/core/form-control-layout' as const;

declare module 'ember-provide-consume-context/context-registry' {
  export default interface ContextRegistry {
    [EUI_FORM_CONTROL_LAYOUT_CONTEXT]: EuiFormControlLayoutContext;
  }
}

/** Upstream context default outside a layout. */
const DEFAULTS: EuiFormControlLayoutContext = {
  compressed: false,
  inputId: '',
  isDisabled: false,
  isInvalid: false,
  isLoading: false,
  readOnly: false
};

/** Read in a getter so changes of the parent layout stay tracked. */
export function formControlLayoutContext(
  component: object
): EuiFormControlLayoutContext {
  return getContext(component, EUI_FORM_CONTROL_LAYOUT_CONTEXT) ?? DEFAULTS;
}
