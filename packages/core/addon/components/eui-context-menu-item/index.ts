import Component from '@glimmer/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';

export default class EuiContextMenuItemComponent extends Component {
  @tracked link: HTMLAnchorElement | HTMLButtonElement | null = null;

  @action
  registerLink(e: HTMLAnchorElement | HTMLButtonElement) {
    this.link = e;
  }
}
