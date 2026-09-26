import EuiCode from '../eui-code.gts';

import type { EuiCodeSignature } from '../eui-code';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** @private Inline code rendered by EuiMarkdownFormat. */
export interface EuiMarkdownFormatMarkdownCode {
  Args: {
    /** The parsed code node. */
    node: {
      language: EuiCodeSignature['Args']['language'];
      content: string;
    };
  };
}

const MarkdownCode: TemplateOnlyComponent<EuiMarkdownFormatMarkdownCode> =
  <template>
    <EuiCode @language={{@node.language}}>
      {{@node.content}}
    </EuiCode>
  </template>;

export default MarkdownCode;
