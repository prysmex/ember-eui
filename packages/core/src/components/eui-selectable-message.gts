import EuiText from './eui-text.gts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

/**
 * A message shown by `EuiSelectable` instead of its list: while loading,
 * when nothing matches the search, or when there are no options.
 */
export interface EuiSelectableMessageSignature {
  Element: HTMLDivElement;
  Args: {
    /** Adds the list's border, for bordered lists. */
    bordered?: boolean;
  };
  Blocks: {
    /** The message. */
    default: [];
  };
}

const EuiSelectableMessage: TemplateOnlyComponent<EuiSelectableMessageSignature> =
  <template>
    <EuiText
      class="euiSelectableMessage
        {{if @bordered 'euiSelectableMessage--bordered'}}"
      @color="subdued"
      @size="xs"
      ...attributes
    >{{yield}}</EuiText>
  </template>;

export default EuiSelectableMessage;
