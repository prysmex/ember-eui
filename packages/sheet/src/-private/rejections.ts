/**
 * The sheet's rejected texts (PACKAGE-DESIGN.md 6, 7.5) and what undo and
 * redo do with them (V02-RESULTS.md, batch 2, "Undo/redo and rejected
 * paste cells"). Plain TypeScript.
 */
import { cellKey } from '../core/index.ts';

import type { RecordId } from '../core/index.ts';

/** A text a type could not read, shown in its cell until the cell is written. */
export interface Rejection {
  /** recordId or tempId, as a string. */
  id: string;
  fieldId: string;
  text: string;
  message: string;
  /** The record's value when the rejection was stored; another value means the owner changed it. */
  seenValue: unknown;
}

export type RejectionMap = ReadonlyMap<string, Rejection>;

/**
 * The same rejection as far as the user can tell: same cell, text and
 * message. Not identity: `remapIds` and redo re-create the objects.
 */
export function sameRejection(a: Rejection, b: Rejection): boolean {
  return (
    a.id === b.id &&
    a.fieldId === b.fieldId &&
    a.text === b.text &&
    a.message === b.message
  );
}

/**
 * Undo of an entry: drops each of its rejections that is still shown,
 * so the cell shows its value again. A rejection the cell got later (other
 * text or message) is kept. `null` when nothing was dropped.
 */
export function clearRejections(
  current: RejectionMap,
  entry: readonly Rejection[]
): Map<string, Rejection> | null {
  let next: Map<string, Rejection> | null = null;
  for (const rejection of entry) {
    const key = cellKey(rejection.id, rejection.fieldId);
    const shown = (next ?? current).get(key);
    if (!shown || !sameRejection(shown, rejection)) continue;
    next ??= new Map(current);
    next.delete(key);
  }
  return next;
}

/**
 * Redo of an entry: puts back each of its rejections whose record exists
 * and still holds the value it had when the text was rejected. `value`
 * says whether the record exists (`found`) and its value. `null` when
 * nothing was put back.
 */
export function restoreRejections(
  current: RejectionMap,
  entry: readonly Rejection[],
  value: (id: string, fieldId: string) => { found: boolean; value: unknown }
): Map<string, Rejection> | null {
  let next: Map<string, Rejection> | null = null;
  for (const rejection of entry) {
    const cell = value(rejection.id, rejection.fieldId);
    if (!cell.found || !Object.is(cell.value, rejection.seenValue)) continue;
    next ??= new Map(current);
    next.set(cellKey(rejection.id, rejection.fieldId), { ...rejection });
  }
  return next;
}

/** The rejections with their record ids remapped (`SheetApi.remapIds`). */
export function remapRejections(
  rejections: readonly Rejection[],
  remap: (id: RecordId) => RecordId
): Rejection[] {
  return rejections.map((rejection) => {
    const id = String(remap(rejection.id));
    return id === rejection.id ? rejection : { ...rejection, id };
  });
}
