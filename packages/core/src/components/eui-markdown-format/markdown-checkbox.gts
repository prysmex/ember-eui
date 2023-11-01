import EuiCheckbox from '../eui-checkbox';
import type { EuiCheckboxSignature } from '../eui-checkbox';
import { on } from '@ember/modifier';
import { fn } from '@ember/helper';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

interface Position {
  start: Record<string, unknown>;
  end: Record<string, unknown>;
}

export interface EuiMarkdownFormatMarkdownCheckboxArgs {
  replaceNode: (position: Position, str: string) => void;
  node: {
    position: Position;
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
