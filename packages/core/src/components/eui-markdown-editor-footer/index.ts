import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';

export interface EuiMarkdownEditorFooterArgs {}

export default class EuiMarkdownEditorFooterComponent extends Component<EuiMarkdownEditorFooterArgs> {
  @tracked isPopoverOpen = false;
  @tracked isShowingHelp = false;
}
