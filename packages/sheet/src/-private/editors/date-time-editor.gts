/**
 * The date-and-time editor (V03 10.3): the browser's
 * `<input type="datetime-local">` when opened with Enter, F2, a
 * double-click or the opener; the text input, seeded with the digit, when
 * opened by typing. The picker works in the field's zone's wall clock: its
 * value (`YYYY-MM-DDTHH:mm`) is read as a wall clock in that zone.
 */
import Component from '@glimmer/component';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { modifier } from 'ember-modifier';

import { dateTimeLocalValue } from '../../core/index.ts';
import InputEditor from './input-editor.gts';

import type { DateTimeField } from '../../core/index.ts';
import type { SheetEditorSignature } from '../../types.ts';

export default class DateTimeEditor extends Component<
  SheetEditorSignature<string | null, DateTimeField>
> {
  get label(): string {
    return this.args.field.label ?? this.args.field.id;
  }

  /** The picker cannot show a text that is not an instant: it opens empty. */
  get localValue(): string {
    return dateTimeLocalValue(this.args.value, this.args.field);
  }

  /** Seconds in the picker only when the field keeps them. */
  get step(): string | undefined {
    return this.args.field.seconds ? '1' : undefined;
  }

  @action
  onInput(event: Event): void {
    this.args.onDraftChange((event.target as HTMLInputElement).value);
  }

  // as the date editor: no setSelectionRange, no showPicker()
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
        @themeClass={{@themeClass}}
      />
    {{else}}
      <input
        type="datetime-local"
        class="euiSheet__input"
        aria-label={{this.label}}
        value={{this.localValue}}
        step={{this.step}}
        {{on "input" this.onInput}}
        {{this.focus}}
      />
    {{/if}}
  </template>
}
