import { on } from '@ember/modifier';
import { action } from '@ember/object';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import { scheduleOnce } from '@ember/runloop';
import { htmlSafe } from '@ember/template';
import { isBlank } from '@ember/utils';

import EmberPowerSelectPowerSelectMultipleInputComponent from 'ember-power-select/components/power-select-multiple/input';
import { and, not } from 'ember-truth-helpers';

import validatableControl from '../../../modifiers/validatable-control.ts';

export default class EuiComboBoxTriggerInputComponent extends EmberPowerSelectPowerSelectMultipleInputComponent {
  get triggerMultipleInputStyle() {
    scheduleOnce('actions', null, this.args.select.actions.reposition);

    let textWidth = 0;

    // @ts-expect-error
    if (this.inputFont) {
      textWidth = this.textMeasurer.width(
        this.args.select.searchText,
        // @ts-expect-error
        this.inputFont
      );
    }

    return htmlSafe(`box-sizing: content-box; width: ${textWidth + 2}px`);
  }

  @action
  handleKeydown(e: KeyboardEvent): false | void {
    if (e.target === null) return;

    if (this.args.onKeydown && this.args.onKeydown(e) === false) {
      if (
        // @ts-expect-error
        this.args.onCreateOption && //if user wants to create an option and
        e.keyCode === 13 && //presses [Enter] and
        (this.args.select.options.length === 0 || //If There are no options or
          this.args.select.results.length === 0) && //Last search made returned no results and
        this.args.select.searchText.length >= 1 //There's something in the searchText box
      ) {
        // @ts-expect-error
        this.args.onCreateOption();

        return false;
      }

      e.stopPropagation();

      return false;
    }

    if (e.keyCode === 8) {
      e.stopPropagation();

      if (isBlank((e.target as HTMLInputElement).value)) {
        let lastSelection =
          this.args.select.selected[this.args.select.selected.length - 1];

        if (lastSelection) {
          this.args.select.actions.select(
            this.args.buildSelection(lastSelection, this.args.select),
            e
          );
          this.args.select.actions.search('');
          this.args.select.actions.open(e);
        }
      }
    } else if ((e.keyCode >= 48 && e.keyCode <= 90) || e.keyCode === 32) {
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
        {{!@glint-expect-error}}
        aria-controls={{@listboxId}}
        style={{this.triggerMultipleInputStyle}}
        disabled={{@select.disabled}}
        {{!@glint-expect-error}}
        tabindex={{@tabindex}}
        form="power-select-fake-form"
        {{!@glint-expect-error}}
        {{on "focus" @onFocus}}
        {{!@glint-expect-error}}
        {{on "blur" @onBlur}}
        {{!@glint-expect-error}}
        {{on "input" this.handleInput}}
        {{on "keydown" this.handleKeydown}}
        {{didInsert this.storeInputStyles}}
      />
    </div>
  </template>
}
