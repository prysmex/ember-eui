import { isTextNode } from '../../utils/eui/combo-box.ts';

import type { TOC } from '@ember/component/template-only';
import type { ComponentLike } from '@glint/template';

/**
 * Text or a component: option `prepend` / `append` and EuiComboBox's
 * `@prepend` / `@append` (upstream React nodes). Components get the
 * option as `@option`.
 */
export type EuiComboBoxNode =
  | string
  | number
  | ComponentLike<{ Args: { option?: unknown } }>;

const asComponent = (node: unknown) =>
  node as ComponentLike<{ Args: { option?: unknown } }>;

const asText = (node: unknown) => node as string;

/** @private Renders an `EuiComboBoxNode`. */
const EuiComboBoxNodeComponent: TOC<{
  Args: { node: unknown; option?: unknown };
}> = <template>{{#if (isTextNode @node)}}{{asText @node}}{{else}}{{#let (asComponent @node) as |Node|}}<Node @option={{@option}} />{{/let}}{{/if}}</template>;

export default EuiComboBoxNodeComponent;
