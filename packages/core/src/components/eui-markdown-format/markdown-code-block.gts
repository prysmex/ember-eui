import type { TemplateOnlyComponent } from '@ember/component/template-only';
import EuiCodeBlock from '../eui-code-block.gts';
import type { EuiCodeBlockSignature } from '../eui-code-block.gts';

export interface MarkdownCodeBlockSignature {
  Args: {
    node: {
      paddingSize: EuiCodeBlockSignature['Args']['paddingSize'];
      fontSize: EuiCodeBlockSignature['Args']['fontSize'];
      language: EuiCodeBlockSignature['Args']['language'];
      content: string;
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
