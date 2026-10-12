import EuiFlyout from './eui-flyout.gts';

import type { EuiFlyoutArgs, EuiFlyoutSignature } from './eui-flyout.gts';

export type EuiFlyoutResizableArgs = Omit<EuiFlyoutArgs, 'resizable'>;

/**
 * An `EuiFlyout` with a resize handle at its inner edge, dragged or moved
 * with the arrow keys. Takes all of `EuiFlyout`'s args plus `@minWidth`,
 * `@maxWidth` (a number in px) and `@onResize`.
 */
export interface EuiFlyoutResizableSignature {
  Element: EuiFlyoutSignature['Element'];
  Args: EuiFlyoutResizableArgs;
  Blocks: EuiFlyoutSignature['Blocks'];
}

/**
 * Upstream's `EuiFlyoutResizable` is `EuiFlyout` with `resizable` set; here
 * it is the same component, so it shares its template and behavior.
 */
export default class EuiFlyoutResizable extends EuiFlyout {
  get resizable() {
    return true;
  }
}
