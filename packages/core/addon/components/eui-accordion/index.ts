import Component from '@glimmer/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';
import { argOrDefaultDecorator as argOrDefault } from '../../helpers/arg-or-default';
import { paddingMapping } from '../../utils/css-mappings/eui-accordion';
import { htmlSafe } from '@ember/template';
import { CommonArgs } from '../common';

type EuiAccordionPaddingSize = keyof typeof paddingMapping;

type AccordionArgs = {
  id: string;

  element?: 'div' | 'fieldset';
  /**
   * Class that will apply to the trigger for the accordion.
   */
  buttonClassName?: string;

  buttonProps?: CommonArgs;

  /**
   * Applied to the main button receiving the `onToggle` event.
   * Anything other than the default `button` does not support removing the arrow display (for accessibility of focus).
   */
  buttonElement?: 'div' | 'legend' | 'button';
  /**
   * Extra props to pass to the EuiButtonIcon containing the arrow.
   */
  arrowProps?: 'iconType' | 'onClick' | 'aria-labelledby';
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

  isOpen?: boolean;
};

export default class EuiAccordionAccordionComponent extends Component<AccordionArgs> {
  // Defaults
  @argOrDefault(false) isLoading!: boolean;
  @argOrDefault(false) isLoadingMessage!: boolean;
  @argOrDefault(false) initialIsOpen!: boolean;
  @argOrDefault('none') paddingSize!: EuiAccordionPaddingSize;
  @argOrDefault('left') arrowDisplay!: AccordionArgs['arrowDisplay'];

  @tracked _opened;
  @tracked childWrapper: HTMLDivElement | null = null;
  @tracked childContent: HTMLDivElement | null = null;

  constructor(owner: unknown, args: AccordionArgs) {
    super(owner, args);

    this._opened = this.args.forceState
      ? this.args.forceState === 'open'
      : this.args.initialIsOpen;
  }

  get buttonElement() {
    return this.args.element === 'fieldset' ? 'legend' : 'button';
  }

  get buttonElementIsFocusable() {
    return this.buttonElement === 'button';
  }

  get _arrowDisplay() {
    return this.arrowDisplay === 'none' && !this.buttonElementIsFocusable
      ? 'left'
      : this.arrowDisplay;
  }

  get isOpen(): boolean {
    return this.args.forceState
      ? this.args.forceState === 'open'
      : this._opened;
  }

  get hasLoadingMessage(): boolean {
    return this.isLoadingMessage && this.isLoadingMessage !== true;
  }

  get buttonClasses(): string {
    return [
      'euiAccordion__button',
      this.args.buttonClassName,
      this.args.buttonProps?.className
    ].join(' ');
  }

  get buttonContentClasses(): string {
    return [
      'euiAccordion__buttonContent',
      this.args.buttonContentClassName
    ].join(' ');
  }

  get childContentStyle(): string | ReturnType<typeof htmlSafe> {
    return this._opened ? '' : htmlSafe(`height: 0px;`);
  }

  setChildContentHeight = () => {
    const { forceState } = this.args;
    requestAnimationFrame(() => {
      const height =
        this.childContent && (forceState ? forceState === 'open' : this._opened)
          ? this.childContent.clientHeight
          : 0;
      this.childWrapper &&
        this.childWrapper.setAttribute('style', `height: ${height}px`);
    });
  };

  @action
  onToggle(): void {
    if (this.args.forceState) {
      this.args.onToggle?.(this.args.forceState === 'open' ? false : true);
    } else {
      this._opened = !this._opened;
      if (this._opened && this.childWrapper) {
        this.childWrapper.focus();
      }
      this.args.onToggle?.(this._opened);
    }
  }
}
