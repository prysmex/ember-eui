/**
 * Functions and constants more than one of the sheet's modules use
 * (V03C-DESIGN.md 3.2): moved from `components/eui-sheet.gts` as they were.
 */
import { isDestroyed, isDestroying } from '@ember/destroyable';
import { schedule } from '@ember/runloop';
import { buildWaiter } from '@ember/test-waiters';

import type {
  ChangeSet,
  EuiSheetField,
  Pos,
  Range,
  RowModel,
  SheetGroup
} from '../../core/index.ts';
import type { UploadField } from './types.ts';

/** Id of the row-number control column. */
export const ROW_COLUMN_ID = 'euiSheetRow';

/** Id of the "+" add-field column: a trailing control column (V03 6.3, W8). */
export const ADD_FIELD_COLUMN_ID = 'euiSheet-addField';
export const ADD_FIELD_WIDTH = 40;

/** One counter per page: `localRecords` uses the tempId as the record id, so it is never reused. */
let tempIdCounter = 0;
export const nextTempId = (): string => `new-${++tempIdCounter}`;
export const resolveWaiter = buildWaiter('@ember-eui/sheet:resolve');

/** The field's `upload`, when it has one (attachment fields). */
export function uploadOf(field: EuiSheetField): UploadField['upload'] {
  const upload = (field as UploadField).upload;
  return typeof upload === 'function' ? upload : undefined;
}

export const EMPTY_CHANGE_SET: ChangeSet = {
  source: 'undo',
  patches: [],
  inserts: [],
  rejected: [],
  newOptions: []
};

export function sameRange(a: Range, b: Range): boolean {
  return (
    a.top === b.top &&
    a.left === b.left &&
    a.bottom === b.bottom &&
    a.right === b.right
  );
}

export function samePos(a: Pos | null, b: Pos | null): boolean {
  return !!a && !!b && a.row === b.row && a.col === b.col;
}

export function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value));
}

/** "Stop": the event is the sheet's. */
export function stop(event: Event): void {
  event.preventDefault();
  event.stopPropagation();
}

export function isPromise<V>(value: unknown): value is Promise<V> {
  return !!value && typeof (value as { then?: unknown }).then === 'function';
}

/** Runs `fn` after the current render (modifiers run inside it: no tracked writes there). */
export function afterRender(owner: object, fn: () => void): void {
  schedule('afterRender', () => {
    if (isDestroying(owner) || isDestroyed(owner)) return;
    fn();
  });
}

export function sameIds(a: readonly string[], b: readonly string[]): boolean {
  if (a.length !== b.length) return false;
  for (let i = 0; i < a.length; i++) if (a[i] !== b[i]) return false;
  return true;
}

/** Whether two renders' rows are laid out the same: the same groups, at the same header and add rows. */
export function sameLayout(
  a: RowModel,
  aGroups: readonly SheetGroup[],
  b: RowModel,
  bGroups: readonly SheetGroup[]
): boolean {
  if (a.length !== b.length || aGroups.length !== bGroups.length) return false;
  for (let i = 0; i < aGroups.length; i++) {
    if (
      aGroups[i]!.key !== bGroups[i]!.key ||
      a.headerRowOf(i) !== b.headerRowOf(i) ||
      a.addRowOf(i) !== b.addRowOf(i)
    ) {
      return false;
    }
  }
  return true;
}
