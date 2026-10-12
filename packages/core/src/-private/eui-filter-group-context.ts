import { getContext } from 'ember-provide-consume-context';

/**
 * What an EuiFilterGroup shares with its EuiFilterButtons (upstream
 * `EuiFilterGroupContext`).
 */
export interface EuiFilterGroupContext {
  readonly compressed: boolean | undefined;
  readonly display: 'regular' | 'highlighted';
  readonly showDividers: boolean | undefined;
}

export const EUI_FILTER_GROUP_CONTEXT = '@ember-eui/core/filter-group' as const;

declare module 'ember-provide-consume-context/context-registry' {
  export default interface ContextRegistry {
    [EUI_FILTER_GROUP_CONTEXT]: EuiFilterGroupContext;
  }
}

/** Upstream context default outside a group: `{}`. */
const DEFAULTS: EuiFilterGroupContext = {
  compressed: undefined,
  display: 'regular',
  showDividers: undefined
};

/** Read in a getter so changes of the parent group stay tracked. */
export function filterGroupContext(component: object): EuiFilterGroupContext {
  return getContext(component, EUI_FILTER_GROUP_CONTEXT) ?? DEFAULTS;
}
