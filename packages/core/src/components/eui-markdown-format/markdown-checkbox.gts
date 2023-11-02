import EuiCheckbox from '../eui-checkbox';
import type { EuiCheckboxSignature } from '../eui-checkbox';
import { on } from '@ember/modifier';
import { fn } from '@ember/helper';
import type { TemplateOnlyComponent } from '@ember/component/template-only';
import type { EuiMarkdownAstNodePosition } from '../../utils/markdown/markdown-types';
import type { Replacer } from '../eui-markdown-format';

export interface EuiMarkdownFormatMarkdownCheckboxArgs {
  replaceNode: Replacer;
  node: {
    position: EuiMarkdownAstNodePosition;
    lead: string;
    isChecked: boolean;
    label: string;
    content: string;
  };
}

export interface EuiMarkdownFormatMarkdownCheckboxSignature {
  Element: EuiCheckboxSignature['Element'];
  Args: EuiMarkdownFormatMarkdownCheckboxArgs;
  Blocks: {
    default: [];
  };
}

const handleChange = (
  node: EuiMarkdownFormatMarkdownCheckboxArgs['node'],
  replaceNode: EuiMarkdownFormatMarkdownCheckboxArgs['replaceNode']
) => {
  const { position, lead, isChecked, label } = node;
  replaceNode(position, `${lead}[${isChecked ? ' ' : 'x'}]${label}`);
};

const EuiMarkdownFormatMarkdownCheckboxComponent: TemplateOnlyComponent<EuiMarkdownFormatMarkdownCheckboxSignature> =
  <template>
    <EuiCheckbox
      @checked={{@node.isChecked}}
      {{on "change" (fn handleChange @node @replaceNode)}}
      ...attributes
    >
      <:label>
        {{@node.content}}
      </:label>
    </EuiCheckbox>
  </template>;

export default EuiMarkdownFormatMarkdownCheckboxComponent;
