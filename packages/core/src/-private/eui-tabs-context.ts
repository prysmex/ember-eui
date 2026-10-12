import { getContext } from 'ember-provide-consume-context';

/** Upstream tab sizes. */
export type EuiTabsSize = 's' | 'm' | 'l';

/** What an EuiTabs shares with its EuiTabs (upstream `EuiTabsContext`). */
export interface EuiTabsContext {
  readonly size: EuiTabsSize;
  readonly expand: boolean;
}

export const EUI_TABS_CONTEXT = '@ember-eui/core/tabs' as const;

declare module 'ember-provide-consume-context/context-registry' {
  export default interface ContextRegistry {
    [EUI_TABS_CONTEXT]: EuiTabsContext;
  }
}

/** The nearest EuiTabs' size/expand, else upstream's defaults (`m`, no expand). */
export function euiTabsContext(component: object): EuiTabsContext {
  return getContext(component, EUI_TABS_CONTEXT) ?? { size: 'm', expand: false };
}
