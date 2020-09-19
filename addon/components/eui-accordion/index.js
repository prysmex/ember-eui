import Component from '@glimmer/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';

import htmlIdGenerator from '../../utils/html-id-generator';

const paddingSizeToClassNameMap = {
  none: '',
  xs: 'euiAccordion__padding--xs',
  s: 'euiAccordion__padding--s',
  m: 'euiAccordion__padding--m',
  l: 'euiAccordion__padding--l',
  xl: 'euiAccordion__padding--xl'
};
export default class EuiAccordionAccordionComponent extends Component {
  @tracked _opened;
  buttonId = htmlIdGenerator();

  constructor () {
    super(...arguments);

    this._opened = this.args.forceState
      ? this.args.forceState === 'open'
      : this.args.initialIsOpen;
  }

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

  get classes () {
    return [
      'euiAccordion',
      this.isOpen ? 'euiAccordion-isOpen' : '',
      this.args.className
    ].join(' ');
  }

  get isOpen () {
    return this.args.forceState ? this.args.forceState === 'open' : this._opened;
  }

  get paddingClass () {
    return paddingSizeToClassNameMap[this.paddingSize];
  }

  get hasIconButton () {
    return this.args.extraAction && this.arrowDisplay === 'right';
  }

  get hasArrowDisplay () {
    return this.arrowDisplay !== 'none';
  }

  get buttonReverse () {
    return !this.args.extraAction && this.arrowDisplay === 'right';
  }

  get hasLoadingMessage () {
    return this.isLoadingMessage && this.isLoadingMessage !== true;
  }

  get buttonClasses () {
    return [
      'euiAccordion__button',
      this.buttonReverse ? 'euiAccordion__buttonReverse' : '',
      this.args.buttonClassName
    ].join(' ');
  }

  @action
  onToggle () {
    if (this.args.forceState) {
      this.args.onToggle && this.args.onToggle(this.args.forceState === 'open' ? false : true);
    } else {
      this._opened = !this._opened;
      this.args.onToggle && this.args.onToggle(this._opened);
    }
  }
}
