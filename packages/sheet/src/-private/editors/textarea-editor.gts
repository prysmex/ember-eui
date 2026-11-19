/**
 * The long text editor: a `<textarea>` in an 'expand' frame (it starts at
 * the cell's box, at least 240 px wide, and grows with its lines up to
 * 240 px, then scrolls). Enter saves and moves down (the sheet's key);
 * Shift+Enter and Alt+Enter insert a line break (the type's `handlesKey`).
 */
import Component from '@glimmer/component';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { modifier } from 'ember-modifier';

import type { SheetEditorSignature } from '../../types.ts';

/** The textarea's tallest size before it scrolls. */
const MAX_HEIGHT = 240;

export function isLineBreakKey(event: KeyboardEvent): boolean {
  return (
    event.key === 'Enter' &&
    (event.shiftKey || event.altKey) &&
    !event.ctrlKey &&
    !event.metaKey
  );
}

export default class TextareaEditor extends Component<
  SheetEditorSignature<any, any>
> {
  get label(): string {
    return this.args.field.label ?? this.args.field.id;
  }

  grow(textarea: HTMLTextAreaElement): void {
    textarea.style.height = 'auto';
    textarea.style.height = `${Math.min(textarea.scrollHeight + 4, MAX_HEIGHT)}px`;
  }

  @action
  onInput(event: Event): void {
    const textarea = event.target as HTMLTextAreaElement;
    this.grow(textarea);
    this.args.onDraftChange(textarea.value);
  }

  @action
  onKeyDown(event: KeyboardEvent): void {
    if (!isLineBreakKey(event)) return;
    // the same line break for Shift+Enter and Alt+Enter on every platform
    event.preventDefault();
    const textarea = event.target as HTMLTextAreaElement;
    textarea.setRangeText(
      '\n',
      textarea.selectionStart,
      textarea.selectionEnd,
      'end'
    );
    this.grow(textarea);
    this.args.onDraftChange(textarea.value);
  }

  setup = modifier((textarea: HTMLTextAreaElement) => {
    textarea.focus();
    const end = textarea.value.length;
    textarea.setSelectionRange(end, end);
    this.grow(textarea);
    // the typed character counts as a change: a blur right after opening saves it
    if (this.args.initialKey !== null) this.args.onDraftChange(this.args.draft);
  });

  <template>
    <textarea
      class="euiSheet__textarea"
      aria-label={{this.label}}
      rows="1"
      value={{@draft}}
      data-test-subj="euiSheetTextarea"
      {{on "input" this.onInput}}
      {{on "keydown" this.onKeyDown}}
      {{this.setup}}
    ></textarea>
  </template>
}
