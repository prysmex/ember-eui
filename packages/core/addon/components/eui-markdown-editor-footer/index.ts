import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { getOwner } from '@ember/application';

export interface EuiMarkdownEditorFooterArgs {}

export default class EuiMarkdownEditorFooterComponent extends Component<EuiMarkdownEditorFooterArgs> {
  @tracked isPopoverOpen = false;
  @tracked isShowingHelp = false;

  get svgPath() {
    const config = getOwner(this).resolveRegistration('config:environment');
    const svgPath = config?.['@ember-eui/core']?.svgPath || 'svg';
    return svgPath;
  }

  get markdownLogo() {
    return `${this.svgPath}/markdown-logo`;
  }
}
