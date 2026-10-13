import type { TemplateOnlyComponent } from '@ember/component/template-only';
import type { SafeString } from '@ember/template';
import type { ComponentLike } from '@glint/template';

/**
 * Rich content where upstream takes a React node (a column `name`, a cards
 * header): text, an `htmlSafe` string or a component rendered without
 * arguments.
 */
export type EuiTableNode =
  | string
  | number
  | SafeString
  | ComponentLike
  | null
  | undefined;

/** Text-like content (text, numbers, `htmlSafe` strings). */
export function isTableText(
  value: unknown
): value is string | number | SafeString {
  return (
    typeof value === 'string' ||
    typeof value === 'number' ||
    (typeof value === 'object' && value !== null && 'toHTML' in value)
  );
}

/** A component (class or template-only), not text. */
export function isTableComponent(value: unknown): value is ComponentLike {
  return (
    value != null &&
    (typeof value === 'function' || typeof value === 'object') &&
    !isTableText(value)
  );
}

function asComponent(value: unknown): ComponentLike {
  return value as ComponentLike;
}

function asText(value: unknown): string | number | SafeString {
  return value as string | number | SafeString;
}

/** Renders an {@link EuiTableNode}. */
const TableNode: TemplateOnlyComponent<{ Args: { node: unknown } }> = <template>
  {{~#if (isTableComponent @node)~}}
    {{~#let (asComponent @node) as |Node|~}}<Node />{{~/let~}}
  {{~else if (isTableText @node)~}}
    {{~asText @node~}}
  {{~/if~}}
</template>;

export default TableNode;
