/**
 * Positions the open editor over its cell ('cell') or beside it ('panel'),
 * inside the sheet's wrapper, and turns focus leaving it into a commit
 * (PACKAGE-DESIGN.md 8.1). Not a popover: no `euiPopover__panel` class.
 */
import Component from '@glimmer/component';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { cancel, next } from '@ember/runloop';
import { htmlSafe } from '@ember/template';
import { modifier } from 'ember-modifier';

import type { SheetEditorRect } from '../types.ts';

/**
 * The editor, and any element an editor renders elsewhere (a wormholed
 * list or calendar) marked with the class or the attribute.
 */
export const EDITOR_SURFACE_SELECTOR =
  '.euiSheet__editor, .euiSheetEditorSurface, [data-eui-sheet-editor-surface]';

/** Only the parts an editor renders elsewhere. */
const SURFACE_SELECTOR =
  '.euiSheetEditorSurface, [data-eui-sheet-editor-surface]';

/** Where focus goes back to when an editor removed its own focused element. */
const FOCUSABLE_SELECTOR =
  'input:not([type=hidden]), textarea, select, button, [tabindex]:not([tabindex="-1"])';

interface EditorFrameSignature {
  Args: {
    rect: SheetEditorRect;
    layout: 'cell' | 'panel';
    placement: 'below' | 'above';
    onFocusOut: () => void;
  };
  Blocks: { default: [] };
}

export default class EditorFrame extends Component<EditorFrameSignature> {
  get layoutClass(): string {
    return this.args.layout === 'panel'
      ? 'euiSheet__editor--panel'
      : 'euiSheet__editor--cell';
  }

  get style() {
    const { top, left, width, height, wrapperHeight } = this.args.rect;
    if (this.args.layout === 'cell') {
      return htmlSafe(
        `top:${top}px;left:${left}px;width:${width}px;height:${height}px;`
      );
    }
    const minWidth = Math.max(width, 240);
    const vertical =
      this.args.placement === 'above'
        ? `bottom:${wrapperHeight - top}px;`
        : `top:${top + height}px;`;
    return htmlSafe(`left:${left}px;min-width:${minWidth}px;${vertical}`);
  }

  frame: HTMLElement | null = null;

  /** Whether focus moving to `next` stays in the editor. */
  staysInEditor(next: EventTarget | null): boolean {
    if (!(next instanceof Element)) return false;
    return (
      !!this.frame?.contains(next) || !!next.closest(EDITOR_SURFACE_SELECTOR)
    );
  }

  /** A deferred focusout decision (see `focusOut`). */
  pending: ReturnType<typeof next> | null = null;

  /**
   * Focus left `from`, towards `to`. A focusout with no `relatedTarget` is
   * ambiguous: focus went nowhere (a click on the page, another window), or
   * the focused element was removed from the DOM, e.g. a calendar redrawing
   * its days when one is picked (flatpickr). Those are decided once the
   * browser has settled focus: still in the editor, or its focused element
   * was removed, keeps editing; anything else closes the editor.
   */
  focusOut(from: EventTarget | null, to: EventTarget | null): void {
    if (this.staysInEditor(to)) return;
    if (to) {
      this.args.onFocusOut();
      return;
    }
    if (this.pending) cancel(this.pending);
    this.pending = next(() => {
      this.pending = null;
      const frame = this.frame;
      if (this.isDestroying || this.isDestroyed || !frame) return;
      if (this.staysInEditor(document.activeElement)) return;
      if (from instanceof Element && !from.isConnected) {
        // the editor removed its own focused element: keep editing, and
        // give focus back so the sheet's keys (Enter, Tab, Escape) work
        frame.querySelector<HTMLElement>(FOCUSABLE_SELECTOR)?.focus();
        return;
      }
      this.args.onFocusOut();
    });
  }

  @action
  onFocusOut(event: FocusEvent): void {
    this.focusOut(event.target, event.relatedTarget);
  }

  willDestroy(): void {
    super.willDestroy();
    if (this.pending) cancel(this.pending);
  }

  /**
   * Focus leaving a part the editor renders elsewhere (outside the frame)
   * closes the editor too: the frame's own focusout does not see it.
   */
  watchSurfaces = modifier((frame: HTMLElement) => {
    this.frame = frame;
    const onDocumentFocusOut = (event: FocusEvent) => {
      const from = event.target;
      if (!(from instanceof Element) || frame.contains(from)) return;
      if (!from.closest(SURFACE_SELECTOR)) return;
      this.focusOut(from, event.relatedTarget);
    };
    document.addEventListener('focusout', onDocumentFocusOut, true);
    return () => {
      document.removeEventListener('focusout', onDocumentFocusOut, true);
      this.frame = null;
    };
  });

  <template>
    <div
      class="euiSheet__editor {{this.layoutClass}}"
      data-test-subj="euiSheetEditor"
      style={{this.style}}
      {{on "focusout" this.onFocusOut}}
      {{this.watchSurfaces}}
    >
      {{yield}}
    </div>
  </template>
}
