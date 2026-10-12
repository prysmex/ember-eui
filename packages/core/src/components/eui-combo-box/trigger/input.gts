import { cached } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { action } from '@ember/object';

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
  /**
   * Shows @placeholder while nothing is selected (power-select 9's own
   * `placeholder` getter uses @searchPlaceholder instead).
   */
  get maybePlaceholder(): string | undefined {
    if (!this.args.isDefaultPlaceholder) {
      return undefined;
    }

    const selected = this.args.select.selected as unknown[] | undefined;

    // @ts-expect-error `placeholder` is passed by EuiComboBoxTrigger
    return !selected || selected.length === 0 ? this.args.placeholder || '' : '';
  }

  /**
   * Upstream `euiComboBoxInput`: transparent, borderless, the form control
   * text. Upstream measures the typed text for the input's width; here the
   * input sizes to its content (`field-sizing`) and fills the rest of the
   * row, so it wraps below the pills like upstream's. With a placeholder or
   * plain text selection it takes the whole row.
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

  @action
  handleKeydown(e: KeyboardEvent): false | void {
    if (e.target === null) return;

    if (this.args.onKeydown && this.args.onKeydown(e) === false) {
      if (
        // @ts-expect-error `onCreateOption` is passed by EuiComboBoxTrigger
        this.args.onCreateOption && //if user wants to create an option and
        e.key === 'Enter' && //presses [Enter] and
        (this.args.select.options.length === 0 || //If There are no options or
          this.args.select.results.length === 0) && //Last search made returned no results and
        this.args.select.searchText.length >= 1 //There's something in the searchText box
      ) {
        // @ts-expect-error `onCreateOption` is passed by EuiComboBoxTrigger
        this.args.onCreateOption();

        return false;
      }

      e.stopPropagation();

      return false;
    }

    if (e.key === 'Backspace') {
      e.stopPropagation();

      if (!(e.target as HTMLInputElement).value.trim()) {
        const selected = this.args.select.selected as unknown[];
        const lastSelection = selected[selected.length - 1];

        if (lastSelection && this.args.buildSelection) {
          this.args.select.actions.select(
            this.args.buildSelection(lastSelection, this.args.select),
            e
          );
          this.args.select.actions.search('');
          this.args.select.actions.open(e);
        }
      }
    } else if (e.key?.length === 1 && /[a-z0-9 ]/i.test(e.key)) {
      // Keys 0-9, a-z or SPACE
      e.stopPropagation();
    }
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
        value={{@select.searchText}}
        aria-controls={{@listboxId}}
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
      />
    </div>
  </template>
}
