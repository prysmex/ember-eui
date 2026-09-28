import type { TemplateOnlyComponent } from '@ember/component/template-only';

/**
 * Hides its content visually but keeps it for screen readers, e.g. a
 * table caption or the text of an icon-only control. To hide one element
 * without a wrapper, use the `screenReaderOnly` modifier instead.
 */
export interface EuiScreenReaderOnlySignature {
  Element: HTMLSpanElement;
  Args: {
    /**
     * Shows the content while something in it has keyboard focus, e.g. a
     * "Skip to content" link.
     */
    showOnFocus?: boolean;
  };
  Blocks: {
    /** The content read by screen readers. */
    default: [];
  };
}

const EuiScreenReaderOnly: TemplateOnlyComponent<EuiScreenReaderOnlySignature> =
  <template>
    <span
      class={{if
        @showOnFocus
        "euiScreenReaderOnly--showOnFocus"
        "euiScreenReaderOnly"
      }}
      ...attributes
    >{{yield}}</span>
  </template>;

export default EuiScreenReaderOnly;
