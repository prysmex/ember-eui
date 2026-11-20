/** Touch: the long press and the click after it (V03C-DESIGN.md 3.2). */
import { action } from '@ember/object';
import { cancel, later } from '@ember/runloop';

import { stop } from './util.ts';

import type EuiSheet from '../../components/eui-sheet.gts';

/** A long press on a touch screen opens the row menu (8.5). */
const LONG_PRESS_MS = 500;
/** A touch that moves farther than this is a scroll, not a long press. */
const LONG_PRESS_SLOP = 10;

export default class SheetTouch<T extends object> {
  sheet: EuiSheet<T>;

  constructor(sheet: EuiSheet<T>) {
    this.sheet = sheet;
  }

  /** `pointerType` of the last press: touch presses do not drag a range. */
  lastPointerType = 'mouse';
  /** A touch long press in progress (its timer and where it started). */
  longPress: {
    timer: ReturnType<typeof later>;
    x: number;
    y: number;
    target: Element;
  } | null = null;
  /** A long press opened the menu: the click (and contextmenu) that follow are its own. */
  longPressOpened = false;

  /* -------------------------------------------------------------------- */
  /* Touch (V02-DESIGN.md 8.5)                                             */
  /* -------------------------------------------------------------------- */

  /**
   * A press: its pointer type (touch presses do not drag a range); a touch
   * on a record's cell or row number starts the long-press timer.
   */
  @action
  onPointerDown(event: PointerEvent): void {
    this.lastPointerType = event.pointerType || 'mouse';
    this.longPressOpened = false;
    this.cancelLongPress();
    if (
      event.pointerType !== 'touch' ||
      !event.isPrimary ||
      this.sheet.edit.editing
    ) {
      return;
    }
    const target = event.target as Element;
    if (this.sheet.rowMenu.menuRowOf(target) < 0) return;
    this.longPress = {
      x: event.clientX,
      y: event.clientY,
      target,
      timer: later(this, this.onLongPress, LONG_PRESS_MS)
    };
  }

  /** A touch that moves is a scroll: no long press. */
  @action
  onPointerMove(event: PointerEvent): void {
    const press = this.longPress;
    if (!press || event.pointerType !== 'touch') return;
    const moved = Math.hypot(event.clientX - press.x, event.clientY - press.y);
    if (moved > LONG_PRESS_SLOP) this.cancelLongPress();
  }

  /** `pointerup` and `pointercancel` (a native pan) end a long press. */
  @action
  onPointerEnd(): void {
    this.cancelLongPress();
  }

  cancelLongPress(): void {
    const press = this.longPress;
    if (!press) return;
    cancel(press.timer);
    this.longPress = null;
  }

  /** The long press opens the row menu there, like a right-click; the click that follows is swallowed. */
  onLongPress(): void {
    const press = this.longPress;
    this.longPress = null;
    if (!press || this.sheet.edit.editing) return;
    if (this.sheet.rowMenu.openContextMenu(press.target, press.x, press.y)) {
      this.longPressOpened = true;
    }
  }

  /** The click (and the compatibility events) after a long press are the press's own: no link, no star, no edit. */
  @action
  onClickCapture(event: MouseEvent): void {
    if (!this.longPressOpened || this.sheet.dom.isInMenu(event.target)) return;
    this.longPressOpened = false;
    stop(event);
  }
}
