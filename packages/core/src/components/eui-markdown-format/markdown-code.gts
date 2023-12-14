import EuiCode from '../eui-code.gts';

import type { EuiCodeSignature } from '../eui-code.gts';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiMarkdownFormatMarkdownCode {
  Args: {
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
