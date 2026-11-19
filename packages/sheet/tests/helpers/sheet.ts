/** Helpers of the sheet's integration tests (from the spike's test, PACKAGE-DESIGN.md 3.4). */
import {
  focus,
  settled,
  triggerEvent,
  triggerKeyEvent
} from '@ember/test-helpers';

import type { ChangeSet } from '#src/core/index.ts';

export function el(selector: string, root: ParentNode = document): HTMLElement {
  const element = root.querySelector<HTMLElement>(selector);
  if (!element) throw new Error(`Missing ${selector}`);
  return element;
}

/**
 * Leading control columns of the sheet's grid: the row-number column
 * (v0.2 batch 2, C8). `cell(row, col)` takes the data column.
 */
export const COL_OFFSET = 1;

export function cell(
  row: number,
  col: number,
  root: ParentNode = document
): HTMLElement {
  return el(
    `[role=gridcell][data-gridcell-visible-row-index="${row}"][data-gridcell-column-index="${col + COL_OFFSET}"]`,
    root
  );
}

export function text(row: number, col: number): string {
  return (
    cell(row, col)
      .querySelector('[data-datagrid-cellcontent]')
      ?.textContent?.trim() ?? ''
  );
}

/** The editor's input (the text, number or date input; the select's search field). */
export function editor(): HTMLInputElement | null {
  return document.querySelector<HTMLInputElement>(
    '[data-test-subj=euiSheetEditor] input'
  );
}

export function editorFrame(): HTMLElement | null {
  return document.querySelector<HTMLElement>('[data-test-subj=euiSheetEditor]');
}

export function selected(): string[] {
  return Array.from(
    document.querySelectorAll<HTMLElement>('.euiSheet__cell--selected')
  )
    .map(
      (element) =>
        `${element.dataset['gridcellVisibleRowIndex']}:${Number(element.dataset['gridcellColumnIndex']) - COL_OFFSET}`
    )
    .sort();
}

export function cellTitle(row: number, col: number): string | null {
  return cell(row, col).getAttribute('title');
}

export function isInvalid(row: number, col: number): boolean {
  const element = cell(row, col);
  return (
    element.classList.contains('euiSheet__cell--invalid') &&
    element.getAttribute('aria-invalid') === 'true'
  );
}

/** A change set with the arrays a partial one leaves out. */
export function changeSet(
  partial: Partial<ChangeSet> & Pick<ChangeSet, 'source'>
): ChangeSet {
  return {
    patches: [],
    inserts: [],
    rejected: [],
    newOptions: [],
    ...partial
  };
}

export async function press(
  key: string,
  modifiers: { shiftKey?: boolean; ctrlKey?: boolean } = {}
): Promise<void> {
  await triggerKeyEvent(
    document.activeElement as HTMLElement,
    'keydown',
    key,
    modifiers
  );
}

/** A printable key: a key code, so the event's `key` is lowercase like a real press. */
export async function type(char: string): Promise<void> {
  await triggerKeyEvent(
    document.activeElement as HTMLElement,
    'keydown',
    char.toUpperCase().charCodeAt(0)
  );
}

/** A keydown on the focused element; returns whether it was prevented. */
export async function pressed(
  key: string,
  modifiers: {
    shiftKey?: boolean;
    ctrlKey?: boolean;
    metaKey?: boolean;
    altKey?: boolean;
  } = {}
): Promise<boolean> {
  // the sheet stops the events it handles in the capture phase, so no
  // listener would see them: dispatch our own and read the flag after
  const event = new KeyboardEvent('keydown', {
    key,
    bubbles: true,
    cancelable: true,
    ...modifiers
  });
  (document.activeElement as HTMLElement).dispatchEvent(event);
  await settled();
  return event.defaultPrevented;
}

/** `focus()` already waits for `settled()`. */
export async function focusCell(row: number, col: number): Promise<void> {
  await focus(cell(row, col));
}

export async function clipboard(
  kind: 'copy' | 'paste',
  value = '',
  target: Element = document.activeElement!
): Promise<{ text: string; prevented: boolean }> {
  const clipboardData = new DataTransfer();
  if (value) clipboardData.setData('text/plain', value);
  const event = new ClipboardEvent(kind, {
    clipboardData,
    bubbles: true,
    cancelable: true
  });
  target.dispatchEvent(event);
  await settled();
  return {
    text: clipboardData.getData('text/plain'),
    prevented: event.defaultPrevented
  };
}

export async function scrollTo(top: number): Promise<void> {
  const outer = el('.euiDataGrid__virtualized');
  outer.scrollTop = top;
  await triggerEvent(outer, 'scroll');
}
