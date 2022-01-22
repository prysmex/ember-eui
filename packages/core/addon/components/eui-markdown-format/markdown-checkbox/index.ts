import Component from '@glimmer/component';
import { action } from '@ember/object';

interface Position {
  start: Record<string, unknown>;
  end: Record<string, unknown>;
}
export interface EuiMarkdownFormatMarkdownCheckboxArgs {
  replaceNode(position: Position, str: string): void;
  node: {
    position: Position;
    lead: string;
    isChecked: boolean;
    label: string;
  };
}

export default class EuiMarkdownFormatMarkdownCheckboxComponent extends Component<EuiMarkdownFormatMarkdownCheckboxArgs> {
  @action
  handleChange() {
    const { position, lead, isChecked, label } = this.args.node;

    this.args.replaceNode(
      position,
      `${lead}[${isChecked ? ' ' : 'x'}]${label}`
    );
  }
}
