import Component from '@glimmer/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';
import { uniqueId } from '../../helpers/unique-id';
import { argOrDefaultDecorator as argOrDefault } from '../../helpers/arg-or-default';
import { paddingMapping } from '../../utils/css-mappings/eui-accordion';

type EuiAccordionPaddingSize = keyof typeof paddingMapping;

type AccordionArgs = {
  id: string;
  /**
   * Class that will apply to the trigger for the accordion.
   */
  buttonClassName?: string;
  /**
   * Class that will apply to the trigger content for the accordion.
   */
  buttonContentClassName?: string;
  /**
   * The content of the clickable trigger
   */
  buttonContent?: Component;
  /**
   * Will appear right aligned against the button. Useful for separate actions like deletions.
   */
  extraAction?: Component;
  /**
   * The accordion will start in the open state.
   */
  initialIsOpen: boolean;
  /**
   * Optional callback method called on open and close with a single `isOpen` parameter
   */
  onToggle?: (isOpen: boolean) => void;
  /**
   * The padding around the exposed accordion content.
   */
  paddingSize?: EuiAccordionPaddingSize;
  /**
   * Placement of the arrow indicator, or 'none' to hide it.
   */
  arrowDisplay?: 'left' | 'right' | 'none';
  /**
   * Control the opening of accordion via prop
   */
  forceState?: 'closed' | 'open';
  /**
   * Change `extraAction` and children into a loading spinner
   */
  isLoading?: boolean;
  /**
   * Choose whether the loading message replaces the content. Customize the message by passing a node
   */
  isLoadingMessage?: boolean | Component;
};

export default class EuiAccordionAccordionComponent extends Component<AccordionArgs> {
  // Defaults
  @argOrDefault(false) isLoading!: boolean;
  @argOrDefault(false) isLoadingMessage!: boolean;
  @argOrDefault(false) initialIsOpen!: boolean;
  @argOrDefault('none') paddingSize!: EuiAccordionPaddingSize;
  @argOrDefault('left') arrowDisplay!: AccordionArgs['arrowDisplay'];

  @tracked _opened;

  buttonId: string = uniqueId();

  constructor(owner: unknown, args: AccordionArgs) {
    super(owner, args);

    this._opened = this.args.forceState ? this.args.forceState === 'open' : this.args.initialIsOpen;
  }

  get isOpen(): boolean {
    return this.args.forceState ? this.args.forceState === 'open' : this._opened;
  }

  get hasIconButton(): boolean | undefined {
    return this.args.extraAction && this.arrowDisplay === 'right';
  }

  get hasArrowDisplay(): boolean {
    return this.arrowDisplay !== 'none';
  }

  get buttonReverse(): boolean {
    return !this.args.extraAction && this.arrowDisplay === 'right';
  }

  get hasLoadingMessage(): boolean {
    return this.isLoadingMessage && this.isLoadingMessage !== true;
  }

  get buttonClasses(): string {
    return [
      'euiAccordion__button',
      this.buttonReverse ? 'euiAccordion__buttonReverse' : '',
      this.args.buttonClassName
    ].join(' ');
  }

  @action
  onToggle(): void {
    if (this.args.forceState) {
      this.args.onToggle && this.args.onToggle(this.args.forceState === 'open' ? false : true);
    } else {
      this._opened = !this._opened;
      this.args.onToggle && this.args.onToggle(this._opened);
    }
  }
}
