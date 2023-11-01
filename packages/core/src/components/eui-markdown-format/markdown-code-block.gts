import type { TemplateOnlyComponent } from '@ember/component/template-only';
import EuiCodeBlock from '../eui-code-block';

export interface MarkdownCodeBlockSignature {
  Args: {
    node: {
      paddingSize: string;
      fontSize: string;
      language: string;
    };
  };
}

const MarkdownCodeBlock: TemplateOnlyComponent<MarkdownCodeBlockSignature> =
  <template>
    <EuiCodeBlock
      @paddingSize={{@node.paddingSize}}
      @fontSize={{@node.fontSize}}
      @language={{@node.language}}
      @isCopyable={{true}}
    >
      {{@node.content}}
    </EuiCodeBlock>
  </template>;

export default MarkdownCodeBlock;
