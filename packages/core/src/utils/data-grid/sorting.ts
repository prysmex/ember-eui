/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License
 * 2.0 and the Server Side Public License, v 1; you may not use this file except
 * in compliance with, at your election, the Elastic License 2.0 or the Server
 * Side Public License, v 1.
 */

/** Port of EUI 123.1.0 `components/datagrid/utils/sorting.ts` (pure part). */
import { defaultComparator } from './schema.ts';

import type {
  EuiDataGridInMemory,
  EuiDataGridInMemoryValues,
  EuiDataGridSchema,
  EuiDataGridSchemaDetector,
  EuiDataGridSorting
} from './types.ts';

/**
 * Row order produced by in-memory sorting: `map[sortedPosition] = dataRowIndex`.
 * Empty unless `inMemory.level === 'sorting'` and columns are sorted.
 */
export function computeSortedRowMap({
  sorting,
  inMemory,
  inMemoryValues,
  schema,
  schemaDetectors
}: {
  sorting?: EuiDataGridSorting;
  inMemory?: EuiDataGridInMemory;
  inMemoryValues: EuiDataGridInMemoryValues;
  schema: EuiDataGridSchema;
  schemaDetectors: EuiDataGridSchemaDetector[];
}): number[] {
  const sortingColumns = sorting?.columns;
  if (
    inMemory?.level !== 'sorting' ||
    sortingColumns == null ||
    sortingColumns.length === 0
  ) {
    return [];
  }
  const wrapped = Object.keys(inMemoryValues).map((row, index) => ({
    index,
    values: inMemoryValues[row]!
  }));
  wrapped.sort((a, b) => {
    for (const column of sortingColumns) {
      const aValue = a.values[column.id]!;
      const bValue = b.values[column.id]!;

      // get the comparator, based on schema
      let comparator: NonNullable<EuiDataGridSchemaDetector['comparator']> =
        defaultComparator;
      if (Object.prototype.hasOwnProperty.call(schema, column.id)) {
        const columnType = schema[column.id]!.columnType;
        for (const detector of schemaDetectors) {
          if (detector.type === columnType && detector.comparator) {
            comparator = detector.comparator;
          }
        }
      }

      const result = comparator(aValue, bValue, column.direction, {
        aIndex: a.index,
        bIndex: b.index
      });
      // only return if the columns are unequal, otherwise allow the next sort-by column to run
      if (result !== 0) return result;
    }
    return 0;
  });
  return wrapped.map((row) => row.index);
}
