import { cached } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { action } from '@ember/object';

import { modifier } from 'ember-modifier';
import PowerSelectInput from 'ember-power-select/components/power-select/input';

import validatableControl from '../../../modifiers/validatable-control.ts';
import { getEuiThemeContext } from '../../../utils/emotion/consume.ts';
import { euiComboBoxInputStyles } from '../../../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../../../utils/eui/styles.ts';

/** Holds the search input and the hidden validity input. */
const INPUT_CONTAINER = {
  position: 'relative',
  display: 'flex',
  flexGrow: 1,
  minInlineSize: '2px',
  maxInlineSize: '100%'
} as const;

/** @private The search input inside EuiComboBox's trigger. */
export default class EuiComboBoxTriggerInputComponent extends PowerSelectInput {
  /** Upstream `inputRef`: the search input, or `null` when it goes away. */
  registerInput = modifier((element: HTMLInputElement) => {
    // @ts-expect-error `inputRef` is passed by EuiComboBoxTrigger
    const inputRef = this.args.inputRef as
      | ((element: HTMLInputElement | null) => void)
      | undefined;

    inputRef?.(element);

    return () => inputRef?.(null);
  });

  /**
   * Shows @placeholder while nothing is selected (power-select 9's own
   * `placeholder` getter uses @searchPlaceholder instead).
   */
  get maybePlaceholder(): string | undefined {
    if (!this.args.isDefaultPlaceholder) {
      return undefined;
    }

    const selected = this.args.select.selected as unknown[] | undefined;

    // upstream: no placeholder while searching
    if (this.args.select.searchText) return '';

    // @ts-expect-error `placeholder` is passed by EuiComboBoxTrigger
    return !selected || selected.length === 0 ? this.args.placeholder || '' : '';
  }

  /**
   * Upstream `euiComboBoxInput`: transparent, borderless, the form control
   * text. Upstream measures the typed text for the input's width; here the
   * input sizes to its content (`field-sizing`) and fills the rest of the
   * row, so it wraps below the pills like upstream's. With a placeholder or
   * plain text selection it takes the whole row.
   *
   * Not upstream: under a plain text selection rendered with EuiComboBox's
   * block (`@hidesValue`), the text is transparent but the caret is not.
   * The value stays the label (screen readers, typing over it).
   */
  @cached
  get inputClass(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiComboBoxInputStyles);

    return euiClass(
      context,
      { boxSizing: 'border-box', margin: 0, padding: 0 },
      styles.euiComboBoxInput,
      {
        flexGrow: 1,
        fieldSizing: 'content',
        // @ts-expect-error `fillWidth` is passed by EuiComboBoxTrigger
        inlineSize: this.args.fillWidth ? '100%' : undefined
      },
      // @ts-expect-error `hidesValue` is passed by EuiComboBoxTrigger
      this.args.hidesValue && {
        '&, &:disabled': {
          color: 'transparent',
          caretColor: context.upstream.euiTheme.colors.textParagraph
        }
      }
    );
  }

  /** An option is highlighted in the open list (`aria-activedescendant`). */
  get hasActiveOption(): boolean {
    const select = this.args.select;

    return Boolean(select.isOpen && select.highlighted != null);
  }

  @cached
  get containerClass(): string {
    const context = getEuiThemeContext(this);

    return euiClass(context, INPUT_CONTAINER);
  }

  /**
   * Keys go to EuiComboBox first (through ember-power-select's keydown
   * handler): it handles Enter, Escape, Tab, the arrows and Backspace
   * like upstream.
   */
  @action
  handleKeydown(e: KeyboardEvent): false | void {
    if (e.target === null) return;

    if (this.args.onKeydown && this.args.onKeydown(e) === false) {
      e.stopPropagation();

      return false;
    }

    if (
      e.key === 'Backspace' ||
      (e.key?.length === 1 && /[a-z0-9 ]/i.test(e.key))
    ) {
      // Backspace, keys 0-9, a-z or SPACE edit the text
      e.stopPropagation();
    }
  }

  /** Upstream keeps the typed text on blur (EuiComboBox decides). */
  @action
  handleBlur(event: FocusEvent): void {
    this.args.onBlur?.(event);
  }

  /**
   * Upstream `searchValue`: plain text single selection shows the search
   * text, else the selected option's label, as the input's value.
   */
  get value(): string {
    const search = this.args.select.searchText;
    // @ts-expect-error `plainTextValue` is passed by EuiComboBoxTrigger
    const plainText = this.args.plainTextValue as string | undefined;

    if (plainText === undefined) return search;

    return search || plainText;
  }

  /** Upstream re-opens the list on every click of a plain text input. */
  @action
  handleClick(event: MouseEvent): void {
    // @ts-expect-error `onPlainTextClick` is passed by EuiComboBoxTrigger
    const onClick = this.args.onPlainTextClick as
      | ((event: MouseEvent) => void)
      | undefined;

    // @ts-expect-error `asPlainText` is passed by EuiComboBoxTrigger
    if (this.args.asPlainText) onClick?.(event);
  }

  /** The id of the options list while it is open (upstream `aria-controls`). */
  get ariaControls(): string | undefined {
    return this.args.select.isOpen ? this.args.listboxId : undefined;
  }

  <template>
    <div class={{this.containerClass}}>
      <input
        tabindex="-1"
        aria-hidden="true"
        style="opacity: 0; width:0px; height:0px; position: absolute; top: 40%; border:solid 1px transparent !important; margin:0px !important; padding: 0; pointer-events: none;"
        class="fake-input-for-html-form-validity"
        {{!@glint-expect-error}}
        {{validatableControl @isInvalid}}
      />
      <input
        class="ember-power-select-trigger-multiple-input euiComboBox__input
          {{this.inputClass}}"
        autocomplete="off"
        autocorrect="off"
        autocapitalize="off"
        {{!@glint-expect-error}}
        autofocus={{@autoFocus}}
        spellcheck={{false}}
        id="ember-power-select-trigger-multiple-input-{{@select.uniqueId}}"
        data-test-subj="comboBoxSearchInput"
        value={{this.value}}
        role={{if @role @role "combobox"}}
        aria-autocomplete="list"
        aria-haspopup="listbox"
        aria-expanded={{if @select.isOpen "true" "false"}}
        aria-controls={{this.ariaControls}}
        {{! @glint-expect-error `required` is passed by EuiComboBoxTrigger }}
        aria-required={{if @required "true"}}
        aria-activedescendant={{if this.hasActiveOption @ariaActiveDescendant}}
        aria-label={{@ariaLabel}}
        aria-labelledby={{@ariaLabelledBy}}
        aria-describedby={{@ariaDescribedBy}}
        {{! @glint-expect-error `isInvalid` is passed by EuiComboBoxTrigger }}
        aria-invalid={{if @isInvalid "true"}}
        placeholder={{this.maybePlaceholder}}
        disabled={{@select.disabled}}
        tabindex={{@tabindex}}
        form="power-select-fake-form"
        {{on "focus" this.handleFocus}}
        {{on "blur" this.handleBlur}}
        {{on "input" this.handleInput}}
        {{on "keydown" this.handleKeydown}}
        {{on "click" this.handleClick}}
        {{this.registerInput}}
      />
    </div>
  </template>
}
