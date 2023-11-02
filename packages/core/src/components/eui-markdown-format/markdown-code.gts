import type { TemplateOnlyComponent } from '@ember/component/template-only';
import EuiCode from '../eui-code';
import type { EuiCodeSignature } from '../eui-code';

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
