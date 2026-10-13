import { getContext } from 'ember-provide-consume-context';

/**
 * What an EuiSplitButton shares with its two actions (upstream
 * `EuiSplitButtonContext`).
 */
export interface EuiSplitButtonContext {
  readonly size: 'xs' | 's' | 'm';
  readonly color: string;
  readonly fill: boolean;
  readonly isDisabled: boolean | undefined;
  readonly hasAriaDisabled: boolean | undefined;
  readonly isLoading: boolean | undefined;
  /** @private The divider's class, rendered before the secondary action. */
  readonly dividerClass: string | undefined;
}

export const EUI_SPLIT_BUTTON_CONTEXT = '@ember-eui/core/split-button' as const;

declare module 'ember-provide-consume-context/context-registry' {
  export default interface ContextRegistry {
    [EUI_SPLIT_BUTTON_CONTEXT]: EuiSplitButtonContext;
  }
}

/** Upstream context default outside a split button. */
const DEFAULTS: EuiSplitButtonContext = {
  size: 'm',
  color: 'primary',
  fill: false,
  isDisabled: undefined,
  hasAriaDisabled: undefined,
  isLoading: undefined,
  dividerClass: undefined
};

/** Read in a getter so changes of the parent split button stay tracked. */
export function splitButtonContext(component: object): EuiSplitButtonContext {
  return getContext(component, EUI_SPLIT_BUTTON_CONTEXT) ?? DEFAULTS;
}
