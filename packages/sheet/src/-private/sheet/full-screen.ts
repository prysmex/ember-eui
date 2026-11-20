/**
 * Full screen (v0.4 02): the sheet's own wrapper fills the window, with
 * its toolbar and footer (the grid's own full screen traps focus in the
 * grid only, so the editor beside it would be outside). Controlled with
 * `@onFullScreenChange`, local without it.
 */
import { tracked } from '@glimmer/tracking';
import { modifier } from 'ember-modifier';

import { afterRender } from './util.ts';

import type EuiSheet from '../../components/eui-sheet.gts';

export default class SheetFullScreen<T extends object> {
  sheet: EuiSheet<T>;

  constructor(sheet: EuiSheet<T>) {
    this.sheet = sheet;
  }

  /** Full screen without `@onFullScreenChange`; null: `@fullScreen`. */
  @tracked localOn: boolean | null = null;

  /** `@fullScreen` with the handler; else the sheet's own state. */
  get isOn(): boolean {
    if (this.sheet.args.onFullScreenChange) return !!this.sheet.args.fullScreen;
    return this.localOn ?? !!this.sheet.args.fullScreen;
  }

  /** The block API's and `api.setFullScreen`: the handler, or the sheet's own state. */
  set = (on: boolean): void => {
    const handler = this.sheet.args.onFullScreenChange;
    if (handler) {
      if (on !== this.isOn) handler(on);
      return;
    }
    this.localOn = on;
  };

  /** The grid's height: all of the box it gets while full screen (`@height` is ignored then). */
  get gridHeight(): string | number | undefined {
    return this.isOn ? '100%' : this.sheet.args.height;
  }

  /**
   * On the wrapper, with `isOn`: the page behind does not scroll while the
   * sheet is full screen (restored on exit and on destroy), and the parts
   * placed over the grid (range outline, copy mark, fill handle) are
   * placed again once the layout changed.
   */
  lockPage = modifier((_element: HTMLElement, [on]: [boolean]) => {
    const relayout = () =>
      afterRender(this.sheet, () => this.sheet.scroll.layoutTick++);
    if (!on) return;
    const body = document.body;
    const overflow = body.style.overflow;
    body.style.overflow = 'hidden';
    relayout();
    return () => {
      body.style.overflow = overflow;
      if (!this.sheet.isDestroying && !this.sheet.isDestroyed) relayout();
    };
  });

  /**
   * The last step of Escape on a cell (after an open editor or menu, a
   * lifted column, the copy mark and a range): it ends full screen.
   * Whether it did.
   */
  endOnEscape(): boolean {
    if (!this.isOn) return false;
    this.set(false);
    return true;
  }
}
