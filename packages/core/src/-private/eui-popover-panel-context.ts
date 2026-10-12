import { getContext } from 'ember-provide-consume-context';

/** Panel paddings of EuiPopover (upstream `EuiPopoverPanelContext`). */
export type EuiPopoverPanelPaddingSize = 'none' | 'xs' | 's' | 'm' | 'l' | 'xl';

/** What an EuiPopover shares with the titles and footers inside it. */
export interface EuiPopoverPanelContext {
  /** The popover's `@panelPaddingSize`. */
  readonly paddingSize: EuiPopoverPanelPaddingSize;
}

export const EUI_POPOVER_PANEL_CONTEXT = '@ember-eui/core/popover-panel' as const;

declare module 'ember-provide-consume-context/context-registry' {
  export default interface ContextRegistry {
    [EUI_POPOVER_PANEL_CONTEXT]: EuiPopoverPanelContext;
  }
}

/**
 * The padding of the nearest EuiPopover's panel, else upstream's default
 * `'l'`. Read it in a getter so changes stay tracked.
 */
export function euiPopoverPanelPadding(
  component: object
): EuiPopoverPanelPaddingSize {
  return getContext(component, EUI_POPOVER_PANEL_CONTEXT)?.paddingSize ?? 'l';
}
