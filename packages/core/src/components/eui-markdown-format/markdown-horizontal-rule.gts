import EuiHorizontalRule from '../eui-horizontal-rule.gts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

/**
 * @private A markdown `---` rendered by EuiMarkdownFormat. Adds upstream's
 * `euiHorizontalRule` root class (the Ember rule renders
 * `euiBorealisHorizontalRule`), which upstream's markdown format color
 * styles target.
 */
export interface MarkdownHorizontalRuleSignature {
  Args: {
    /** The parsed rule node (unused). */
    node?: unknown;
  };
}

const MarkdownHorizontalRule: TemplateOnlyComponent<MarkdownHorizontalRuleSignature> =
  <template><EuiHorizontalRule class="euiHorizontalRule" /></template>;

export default MarkdownHorizontalRule;
