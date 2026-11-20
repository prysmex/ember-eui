/**
 * Positions the open editor over its cell ('cell') or from its box,
 * growing ('expand'), inside the sheet's wrapper; beside it ('panel'), in
 * the sheet's layer (portaled, `layer.gts`: below the cell, above it when
 * there is no room below in the viewport); or in flow ('inline': the
 * expanded record's form). Turns focus leaving it into a commit
 * (PACKAGE-DESIGN.md 8.1). The grid and the form share this focus-out
 * logic. Not a popover: no `euiPopover__panel` class.
 */
import Component from '@glimmer/component';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { cancel, next } from '@ember/runloop';
import { htmlSafe } from '@ember/template';
import { modifier } from 'ember-modifier';

import SheetLayer, { placeLayer } from './layer.gts';

import type EuiSheet from '../components/eui-sheet.gts';
import type { SheetEditorRect } from '../types.ts';
import type { LayerAnchor } from './layer.gts';

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
    /** The grid's sheet: a 'panel' renders in its layer. Not given by 'inline'. */
    sheet?: EuiSheet<any>;
    /** Not used by 'inline'. */
    rect?: SheetEditorRect;
    layout: 'cell' | 'panel' | 'expand' | 'inline';
    /**
     * px the 'cell' and 'expand' frames grow past the cell on each side
     * (V03 batch 1: 2, less where the grid body's visible area ends).
     */
    grow?: { top: number; right: number; bottom: number; left: number };
    onFocusOut: () => void;
  };
  Blocks: { default: [] };
}

export default class EditorFrame extends Component<EditorFrameSignature> {
  get layoutClass(): string {
    return `euiSheet__editor--${this.args.layout}`;
  }

  /** The grid's sheet (only read when `inLayer`). */
  get sheet(): EuiSheet<any> {
    return this.args.sheet!;
  }

  /** A 'panel' of the grid: portaled, placed by the layer. */
  get inLayer(): boolean {
    return this.args.layout === 'panel' && !!this.args.sheet;
  }

  /** The cell's box in the viewport now (the layer reads it at every placement). */
  anchor = (): LayerAnchor | null => {
    const rect = this.args.rect;
    return rect && this.args.sheet
      ? this.args.sheet.dom.toViewport(rect)
      : null;
  };

  get minWidth(): number {
    return Math.max(this.args.rect?.width ?? 0, 240);
  }

  get style() {
    if (this.args.layout === 'inline' || !this.args.rect) return undefined;
    let { top, left, width, height } = this.args.rect;
    const layout = this.args.layout;
    // lifted past the cell; the padding keeps the text where it was (3 px
    // border, the cell's 6 px padding)
    let padding = '';
    if ((layout === 'cell' || layout === 'expand') && this.args.grow) {
      const grow = this.args.grow;
      top -= grow.top;
      left -= grow.left;
      width += grow.left + grow.right;
      height += grow.top + grow.bottom;
      padding = `--euiSheetEditorPadX:${3 + grow.left}px;--euiSheetEditorPadY:${3 + grow.top}px;`;
    }
    if (layout === 'cell') {
      return htmlSafe(
        `top:${top}px;left:${left}px;width:${width}px;height:${height}px;${padding}`
      );
    }
    if (layout === 'expand') {
      // starts at the cell's box; the editor grows it (long text)
      return htmlSafe(
        `top:${top}px;left:${left}px;min-width:${Math.max(width, 240)}px;min-height:${height}px;${padding}`
      );
    }
    // 'panel' without a sheet: under the cell, in the wrapper
    return htmlSafe(
      `top:${top + height}px;left:${left}px;min-width:${this.minWidth}px;`
    );
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
    {{#if this.inLayer}}
      <SheetLayer @sheet={{this.sheet}}>
        <div
          class="euiSheet__editor {{this.layoutClass}}"
          data-test-subj="euiSheetEditor"
          {{placeLayer
            anchor=this.anchor
            wrapper=this.sheet.wrapper
            minWidth=this.minWidth
            watch=@rect
          }}
          {{on "focusout" this.onFocusOut}}
          {{this.watchSurfaces}}
        >
          {{yield}}
        </div>
      </SheetLayer>
    {{else}}
      <div
        class="euiSheet__editor {{this.layoutClass}}"
        data-test-subj="euiSheetEditor"
        style={{this.style}}
        {{on "focusout" this.onFocusOut}}
        {{this.watchSurfaces}}
      >
        {{yield}}
      </div>
    {{/if}}
  </template>
}
