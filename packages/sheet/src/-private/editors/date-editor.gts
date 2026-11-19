/**
 * The date editor (PACKAGE-DESIGN.md 8.2, P6): the browser's
 * `<input type="date">` when opened with Enter, F2 or a double-click; the
 * text input, seeded with the digit, when opened by typing. Replace it with
 * `{ ...dateType, editor: YourEditor }` in `@fieldTypes` (README).
 */
import Component from '@glimmer/component';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { modifier } from 'ember-modifier';

import { validIsoDate } from '../../core/index.ts';
import InputEditor from './input-editor.gts';

import type { SheetEditorSignature } from '../../types.ts';

export default class DateEditor extends Component<
  SheetEditorSignature<any, any>
> {
  get label(): string {
    return this.args.field.label ?? this.args.field.id;
  }

  /** A date input cannot show a text that is not a date: it opens empty. */
  get isoValue(): string {
    return validIsoDate(this.args.value) ?? '';
  }

  @action
  onInput(event: Event): void {
    this.args.onDraftChange((event.target as HTMLInputElement).value);
  }

  // no setSelectionRange (it throws on a date input), no showPicker() (it
  // needs a user gesture)
  focus = modifier((input: HTMLInputElement) => {
    input.focus();
  });

  <template>
    {{#if @initialKey}}
      <InputEditor
        @value={{@value}}
        @field={{@field}}
        @record={{@record}}
        @draft={{@draft}}
        @initialKey={{@initialKey}}
        @onDraftChange={{@onDraftChange}}
        @onCommit={{@onCommit}}
        @onCancel={{@onCancel}}
        @messages={{@messages}}
      />
    {{else}}
      <input
        type="date"
        class="euiSheet__input"
        aria-label={{this.label}}
        value={{this.isoValue}}
        {{on "input" this.onInput}}
        {{this.focus}}
      />
    {{/if}}
  </template>
}
