import { isHTMLSafe } from '@ember/template';

import type { TemplateOnlyComponent } from '@ember/component/template-only';
import type { SafeString } from '@ember/template';
import type { ComponentLike } from '@glint/template';

/**
 * Ember's stand-in for a React node passed as a prop: plain text, or a
 * component (a template-only component, a class, or `(component …)`).
 */
export type EuiRenderNode = string | number | SafeString | ComponentLike<any>;

/**
 * True when the value is text rather than something to invoke. An `htmlSafe`
 * string is text too (rendered as HTML), as @ember-eui/core 14's toasts
 * rendered it; invoked, it is not a component and the render fails.
 */
export function isTextNode(value: unknown): value is string | number | SafeString {
  return typeof value === 'string' || typeof value === 'number' || isHTMLSafe(value);
}

export interface EuiRenderNodeSignature {
  Args: {
    /** Text, or a component to render. Nothing renders for `null`/`undefined`. */
    value?: EuiRenderNode | null;
  };
}

/** Renders a `EuiRenderNode`: text as is, a component invoked without args. */
const EuiRenderNodeView: TemplateOnlyComponent<EuiRenderNodeSignature> = <template>
  {{#if (isTextNode @value)}}
    {{@value}}
  {{else if @value}}
    {{#let @value as |Node|}}<Node />{{/let}}
  {{/if}}
</template>;

export default EuiRenderNodeView;
