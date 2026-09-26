import { on } from '@ember/modifier';
import { action } from '@ember/object';

import PowerSelectInput from 'ember-power-select/components/power-select/input';
import { and, not } from 'ember-truth-helpers';

import validatableControl from '../../../modifiers/validatable-control.ts';

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
    {{#if (and this.maybePlaceholder (not @select.searchText))}}
      <p class="euiComboBoxPlaceholder">
        {{this.maybePlaceholder}}
      </p>
    {{/if}}
    <div
      class="euiComboBox__input"
      style="font-size: 14px; display: inline-block; position: relative;"
    >
      <input
        tabindex="-1"
        style="opacity: 0px; width:0px; height:0px; position: absolute; top: 40%; border:solid 1px transparent !important; margin:0px !important;"
        class="fake-input-for-html-form-validity"
        {{!@glint-expect-error}}
        {{validatableControl @isInvalid}}
      />
      <input
        class="ember-power-select-trigger-multiple-input euiComboBox__input"
        autocomplete="off"
        autocorrect="off"
        autocapitalize="off"
        {{!@glint-expect-error}}
        autofocus={{@autoFocus}}
        spellcheck={{false}}
        id="ember-power-select-trigger-multiple-input-{{@select.uniqueId}}"
        value={{@select.searchText}}
        aria-controls={{@listboxId}}
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
