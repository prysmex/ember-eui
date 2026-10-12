import { getContext } from 'ember-provide-consume-context';

import type { EuiBreakpointSize } from '../utils/breakpoint.ts';

/**
 * What an EuiSplitPanelOuter shares with its EuiSplitPanelInner sections
 * (upstream `SplitPanelInnerBorderDirection` context): the direction of the
 * high-contrast dividers between sections, and the breakpoints on which a
 * row stacks into a column.
 */
export interface EuiSplitPanelContext {
  /** `undefined` when the outer panel renders no high-contrast border. */
  readonly borderDirection: 'row' | 'column' | undefined;
  /** Breakpoints on which `'row'` collapses to `'column'`. */
  readonly collapseOn: readonly EuiBreakpointSize[];
}

export const EUI_SPLIT_PANEL_CONTEXT = '@ember-eui/core/split-panel' as const;

declare module 'ember-provide-consume-context/context-registry' {
  export default interface ContextRegistry {
    [EUI_SPLIT_PANEL_CONTEXT]: EuiSplitPanelContext;
  }
}

/** The nearest EuiSplitPanelOuter's context, if any. */
export function euiSplitPanelContext(
  component: object
): EuiSplitPanelContext | undefined {
  return getContext(component, EUI_SPLIT_PANEL_CONTEXT) ?? undefined;
}
