import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import MarkdownLogoComponent from './icons/markdown-logo';

export interface EuiMarkdownEditorFooterArgs {}

export default class EuiMarkdownEditorFooterComponent extends Component<EuiMarkdownEditorFooterArgs> {
  @tracked isPopoverOpen = false;
  @tracked isShowingHelp = false;

  get markdownLogo() {
    return MarkdownLogoComponent;
  }
}
