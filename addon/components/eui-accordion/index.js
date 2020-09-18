import Component from '@glimmer/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';

import htmlIdGenerator from '../../utils/html-id-generator';

export default class EuiAccordionAccordionComponent extends Component {
  @tracked isOpen;
  buttonId = htmlIdGenerator();

  // Defaults
  get isLoading () {
    return this.args.isLoading ?? false;
  }

  get isLoadingMessage () {
    return this.args.isLoadingMessage ?? false;
  }

  get initialIsOpen () {
    return this.args.initialIsOpen ?? false;
  }

  get paddingSize () {
    return this.args.paddingSize ?? 'none';
  }

  get arrowDisplay () {
    return this.args.arrowDisplay ?? 'left';
  }
  // /Defaults

  get hasIconButton () {
    return this.args.extraAction && this.arrowDisplay === 'right';
  }

  get hasArrowDisplay () {
    return this.arrowDisplay !== 'none';
  }

  get buttonReverse () {
    return !this.hasIconButton;
  }

  get showLoadingMessage () {
    return this.isLoadingMessage && this.isLoadingMessage !== true;
  }

  @action
  onToggle () {
    if (this.args.forceState) {
      this.args.onToggle &&
        this.args.onToggle(this.args.forceState === 'open' ? false : true);
    } else {
      this.isOpen = !this.isOpen;
      this.args.onToggle && this.args.onToggle(this.isOpen);
    }
  }
}
