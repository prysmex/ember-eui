import { getContext } from 'ember-provide-consume-context';

/** What an EuiForm shares with the rows and groups rendered inside it. */
export interface EuiFormContext {
  /** Default `@fullWidth` of EuiFormRow and EuiDescribedFormGroup. */
  readonly defaultFullWidth: boolean;
}

export const EUI_FORM_CONTEXT = '@ember-eui/core/form' as const;

declare module 'ember-provide-consume-context/context-registry' {
  export default interface ContextRegistry {
    [EUI_FORM_CONTEXT]: EuiFormContext;
  }
}

/**
 * The `@fullWidth` a form row or group uses: its own argument, else the
 * nearest EuiForm's `@fullWidth`, else `false` (upstream `useFormContext`).
 * Read it in a getter so changes stay tracked.
 */
export function euiFormFullWidth(
  component: object,
  fullWidth: boolean | undefined
): boolean {
  return (
    fullWidth ??
    getContext(component, EUI_FORM_CONTEXT)?.defaultFullWidth ??
    false
  );
}
