/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License
 * 2.0 and the Server Side Public License, v 1; you may not use this file except
 * in compliance with, at your election, the Elastic License 2.0 or the Server
 * Side Public License, v 1.
 */

/**
 * Port of EUI 123.1.0 `components/datagrid/utils/row_heights.ts`
 * (`RowHeightUtils`). The react-window specific subclass becomes an
 * `onChange` callback the grid body uses to recompute row offsets.
 */
import type {
  EuiDataGridColumn,
  EuiDataGridRowHeightOption,
  EuiDataGridRowHeightsOptions
} from './types.ts';

export const AUTO_HEIGHT = 'auto';
export const DEFAULT_ROW_HEIGHT = 34;

export type RowHeightType =
  | 'default'
  | 'auto'
  | 'lineCount'
  | 'numerical'
  | 'autoBelowLineCount';

const isObject = (value: unknown): value is Record<string, unknown> =>
  typeof value === 'object' && value !== null;
const isNumber = (value: unknown): value is number =>
  typeof value === 'number' && !isNaN(value);

export class RowHeightUtils {
  heightsCache = new Map<number, Map<string, number>>();

  constructor(private onChange?: (rowIndex: number) => void) {}

  getRowHeightOption(
    rowIndex: number,
    rowHeightsOptions?: EuiDataGridRowHeightsOptions
  ): EuiDataGridRowHeightOption | undefined {
    return (
      rowHeightsOptions?.rowHeights?.[rowIndex] ??
      rowHeightsOptions?.defaultHeight
    );
  }

  isRowHeightOverride(
    rowIndex: number,
    rowHeightsOptions?: EuiDataGridRowHeightsOptions
  ): boolean {
    return rowHeightsOptions?.rowHeights?.[rowIndex] != null;
  }

  getCalculatedHeight(
    heightOption: EuiDataGridRowHeightOption,
    defaultHeight: number,
    rowIndex?: number,
    rowHeightsOptions?: EuiDataGridRowHeightsOptions
  ): number {
    if (isObject(heightOption) && heightOption.height) {
      return Math.max(heightOption.height as number, defaultHeight);
    }
    if (heightOption && isNumber(heightOption)) {
      return Math.max(heightOption, defaultHeight);
    }
    if (isObject(heightOption) && heightOption.lineCount) {
      const autoBelowLineCount = rowHeightsOptions?.autoBelowLineCount;
      const isRowHeightOverride =
        rowIndex != null && this.isRowHeightOverride(rowIndex, rowHeightsOptions);
      if (autoBelowLineCount || isRowHeightOverride) {
        return this.getRowHeight(rowIndex!) || defaultHeight;
      }
      return defaultHeight;
    }
    if (heightOption === AUTO_HEIGHT && rowIndex != null) {
      return this.getRowHeight(rowIndex);
    }
    return defaultHeight;
  }

  getHeightType(option?: EuiDataGridRowHeightOption): RowHeightType {
    if (option == null) return 'default';
    if (option === AUTO_HEIGHT) return 'auto';
    const lineCount = this.getLineCount(option);
    if (lineCount != null) return lineCount > 1 ? 'lineCount' : 'default';
    return 'numerical';
  }

  getLineCount(option?: EuiDataGridRowHeightOption): number | undefined {
    return isObject(option) ? (option.lineCount as number | undefined) : undefined;
  }

  calculateHeightForLineCount(cellRef: HTMLElement, lineCount: number): number {
    const computedStyles = window.getComputedStyle(cellRef, null);
    const lineHeight = parseInt(computedStyles.lineHeight, 10);
    const contentHeight = Math.ceil(lineCount * lineHeight);
    const padding = parseInt(computedStyles.paddingTop, 10);
    // Assumes both padding-top and bottom are the same
    return contentHeight + padding * 2;
  }

  isAutoBelowLineCount(
    options?: EuiDataGridRowHeightsOptions,
    option?: EuiDataGridRowHeightOption
  ): boolean {
    if (!options?.autoBelowLineCount) return false;
    return (this.getLineCount(option) ?? 0) > 1;
  }

  isAutoHeight(
    rowIndex: number,
    rowHeightsOptions?: EuiDataGridRowHeightsOptions
  ): boolean {
    const height = this.getRowHeightOption(rowIndex, rowHeightsOptions);
    if (height === AUTO_HEIGHT) return true;
    return this.isAutoBelowLineCount(rowHeightsOptions, height);
  }

  getRowHeight(rowIndex: number): number {
    const rowHeights = this.heightsCache.get(rowIndex);
    if (rowHeights == null) return 0;
    const values = Array.from(rowHeights.values());
    if (!values.length) return 0;
    return Math.max(...values);
  }

  setRowHeight(
    rowIndex: number,
    colId: string,
    height: number = DEFAULT_ROW_HEIGHT,
    visibleRowIndex: number = rowIndex
  ): boolean {
    const rowHeights = this.heightsCache.get(rowIndex) || new Map();
    const adaptedHeight = Math.ceil(height);
    if (rowHeights.get(colId) === adaptedHeight) return false;
    rowHeights.set(colId, adaptedHeight);
    this.heightsCache.set(rowIndex, rowHeights);
    this.onChange?.(visibleRowIndex);
    return true;
  }

  pruneHiddenColumnHeights(visibleColumns: EuiDataGridColumn[]): boolean {
    const visibleColumnIds = new Set(visibleColumns.map(({ id }) => id));
    let didModify = false;
    this.heightsCache.forEach((rowHeights) => {
      Array.from(rowHeights.keys()).forEach((existingColumnId) => {
        if (!visibleColumnIds.has(existingColumnId)) {
          didModify = true;
          rowHeights.delete(existingColumnId);
        }
      });
    });
    if (didModify) this.onChange?.(0);
    return didModify;
  }
}
