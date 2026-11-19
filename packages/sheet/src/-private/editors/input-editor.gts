/**
 * The text input editor (text, number; date when opened by typing). Stays
 * `type="text"` for numbers: a number input reports '' for `abc`, so the
 * rejection could not show the text (PACKAGE-DESIGN.md 8.2). The sheet
 * handles Enter, Tab and Escape.
 */
import Component from '@glimmer/component';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { modifier } from 'ember-modifier';

import type { SheetEditorSignature } from '../../types.ts';

export default class InputEditor extends Component<
  SheetEditorSignature<any, any>
> {
  get label(): string {
    return this.args.field.label ?? this.args.field.id;
  }

  get inputMode(): string | undefined {
    return this.args.field.type === 'number' ? 'decimal' : undefined;
  }

  @action
  onInput(event: Event): void {
    this.args.onDraftChange((event.target as HTMLInputElement).value);
  }

  setup = modifier((input: HTMLInputElement) => {
    input.focus();
    const end = input.value.length;
    input.setSelectionRange(end, end);
    // the typed character counts as a change: a blur right after opening saves it
    if (this.args.initialKey !== null) this.args.onDraftChange(this.args.draft);
  });

  <template>
    <input
      type="text"
      class="euiSheet__input"
      aria-label={{this.label}}
      inputmode={{this.inputMode}}
      value={{@draft}}
      {{on "input" this.onInput}}
      {{this.setup}}
    />
  </template>
}
