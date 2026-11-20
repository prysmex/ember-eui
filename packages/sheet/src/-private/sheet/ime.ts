/** Composition: the IME catcher over the focused cell (V03C-DESIGN.md 3.2). */
import { tracked } from '@glimmer/tracking';

import { stop } from './util.ts';

import type EuiSheet from '../../components/eui-sheet.gts';
import type { Pos } from '../../core/index.ts';
import type { SheetEditorRect } from '../../types.ts';

export default class SheetIme<T extends object> {
  sheet: EuiSheet<T>;

  constructor(sheet: EuiSheet<T>) {
    this.sheet = sheet;
  }

  /** The composition catcher (`ime-catcher.gts`) and the cell it is over. */
  imeInput: HTMLInputElement | null = null;
  imePos: Pos | null = null;
  imeComposing = false;
  @tracked imeActive = false;

  /* -------------------------------------------------------------------- */
  /* Composition: dead keys and IMEs (V02-DESIGN.md 8.6)                   */
  /* -------------------------------------------------------------------- */

  /** Moves the catcher over the cell and focuses it, inside the `keydown`. */
  startIme(pos: Pos, cell: HTMLElement): void {
    const input = this.imeInput;
    const rect = this.sheet.dom.rectOf(cell);
    if (!input || !rect) return;
    this.imePos = pos;
    this.imeComposing = false;
    input.value = '';
    this.placeIme(rect);
    input.classList.add('euiSheet__input', 'euiSheet__ime--active');
    input.focus({ preventScroll: true });
    this.imeActive = true;
  }

  /** Puts the catcher over a cell's box. */
  placeIme(rect: SheetEditorRect): void {
    const input = this.imeInput;
    if (!input) return;
    input.style.top = `${rect.top}px`;
    input.style.left = `${rect.left}px`;
    input.style.width = `${rect.width}px`;
    input.style.height = `${rect.height}px`;
  }

  onImeCompositionStart(): void {
    if (this.imePos) this.imeComposing = true;
  }

  onImeCompositionEnd(event: CompositionEvent): void {
    if (!this.imePos) return;
    this.imeComposing = false;
    this.finishIme(this.imeInput?.value || event.data || '');
  }

  /** A dead key that fires no composition events types its character as a plain `input`. */
  onImeInput(event: InputEvent): void {
    if (!this.imePos || event.isComposing || this.imeComposing) return;
    this.finishIme(this.imeInput?.value ?? '');
  }

  /** Escape (or Tab) outside a composition: back to the cell. */
  onImeKeyDown(event: KeyboardEvent): void {
    if (event.isComposing || event.keyCode === 229) return;
    if (event.key !== 'Escape' && event.key !== 'Tab') return;
    stop(event);
    const pos = this.imePos;
    this.endIme();
    if (pos) this.sheet.dom.focusGridCell(pos);
  }

  /** Hides and clears the catcher (its own blur, a scroll, the end of a composition). */
  endIme(): void {
    const input = this.imeInput;
    this.imePos = null;
    this.imeComposing = false;
    if (input) {
      input.value = '';
      input.classList.remove('euiSheet__input', 'euiSheet__ime--active');
      input.removeAttribute('style');
    }
    if (this.imeActive) this.imeActive = false;
  }

  /**
   * The composed text opens the cell's editor with it (as a typed key
   * does); empty text, or a type whose `opensOnKey` refuses it: focus goes
   * back to the cell.
   */
  finishIme(text: string): void {
    const pos = this.imePos;
    this.endIme();
    if (!pos) return;
    const cell = this.sheet.dom.cellElement(pos);
    const field = this.sheet.fields.visibleFields[pos.col];
    const open =
      !!text &&
      !!cell &&
      !!field &&
      this.sheet.cells.canEdit(pos) &&
      (this.sheet.fields.typeOf(field).opensOnKey?.(text) ?? true);
    if (open) this.sheet.startEdit(pos, cell, text);
    else this.sheet.dom.focusGridCell(pos);
  }
}
