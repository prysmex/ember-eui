import Component from '@glimmer/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';
import { argOrDefaultDecorator as argOrDefault } from '../../helpers/arg-or-default';
import { keys } from '../../utils/keys';
import { Browser } from '../../utils/browser';

let isSearchSupported = false;

/**
 * You can find more typing on the template
 */
type EuiFieldSearchArgs = {
  value?: string;
  defaultValue?: string;

  /**
   * When `true` the search will be executed (that is, the `onSearch` will be called) as the
   * user types.
   */
  incremental?: boolean;
  /**
   * Optional callback method called on open and close with a single `isOpen` parameter
   */
  onKeyUp?: (e: KeyboardEvent) => void;
  onSearch?: (value: string) => void;
};

export default class EuiFieldSearch extends Component<EuiFieldSearchArgs> {
  @tracked inputElement: HTMLInputElement | null = null;
  @tracked value: string | null =
    this.args.value || (this.args.defaultValue ? `${this.args.defaultValue}` : '');

  @argOrDefault(false) incremental = false;

  @action
  setValue(e: InputEvent): void {
    const value = (e.target as HTMLInputElement).value;
    if (this.value !== value) {
      this.value = value;
    }
    this.args.onSearch?.(this.value);
  }

  @action
  onKeyUp(incremental: boolean, onSearch: (value: string) => void, e: KeyboardEvent): void {
    this.value = (e.target as HTMLInputElement).value;
    if (this.args.onKeyUp) {
      this.args.onKeyUp(e);
      if (e.defaultPrevented) {
        return;
      }
    }

    if (
      onSearch &&
      ((e.key !== keys.ENTER && incremental) || (e.key === keys.ENTER && !isSearchSupported))
    ) {
      onSearch((e.target as HTMLInputElement).value);
    }
  }

  @action
  onClear(): void {
    const nativeInputValue = Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value');
    const nativeInputValueSetter = nativeInputValue ? nativeInputValue.set : undefined;
    if (nativeInputValueSetter) {
      nativeInputValueSetter.call(this.inputElement, '');
    }

    // dispatch input event, with IE11 support/fallback
    let event;
    if ('Event' in window && typeof Event === 'function') {
      event = new Event('input', {
        bubbles: true,
        cancelable: false
      });
    } else {
      // IE11
      event = document.createEvent('Event');
      event.initEvent('input', true, false);
    }

    if (this.inputElement) {
      if (event) {
        this.inputElement.dispatchEvent(event);
      }
      // set focus on the search field
      this.inputElement.focus();
      this.inputElement.dispatchEvent(new Event('change'));
    }
    this.value = '';

    if (this.args.onSearch && this.incremental) {
      this.args.onSearch('');
    }
  }

  @action
  didInsertInput(inputRef: HTMLInputElement): void {
    this.inputElement = inputRef;
    isSearchSupported = Browser.isEventSupported('search', this.inputElement);
  }
}
