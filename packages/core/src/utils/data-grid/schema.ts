/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License
 * 2.0 and the Server Side Public License, v 1; you may not use this file except
 * in compliance with, at your election, the Elastic License 2.0 or the Server
 * Side Public License, v 1.
 */

/**
 * Port of EUI 123.1.0 `components/datagrid/utils/data_grid_schema.tsx`:
 * default schema detectors/comparators and in-memory schema detection.
 * Sort labels are i18n `{ token, default }` pairs instead of `<EuiI18n>`.
 */
import type {
  EuiDataGridColumn,
  EuiDataGridInMemory,
  EuiDataGridInMemoryValues,
  EuiDataGridSchema,
  EuiDataGridSchemaDetector
} from './types.ts';

const numericChars = new Set([
  '0',
  '1',
  '2',
  '3',
  '4',
  '5',
  '6',
  '7',
  '8',
  '9',
  '.',
  '-'
]);

export const schemaDetectors: EuiDataGridSchemaDetector[] = [
  {
    type: 'boolean',
    detector(value) {
      return value.toLowerCase() === 'true' || value.toLowerCase() === 'false'
        ? 1
        : 0;
    },
    comparator(a, b, direction) {
      const aValue = a.toLowerCase() === 'true';
      const bValue = b.toLowerCase() === 'true';
      if (aValue < bValue) return direction === 'asc' ? -1 : 1;
      if (aValue > bValue) return direction === 'asc' ? 1 : -1;
      return 0;
    },
    icon: 'tokenBoolean',
    sortTextAsc: {
      token: 'euiDataGridSchema.booleanSortTextAsc',
      default: 'False-True'
    },
    sortTextDesc: {
      token: 'euiDataGridSchema.booleanSortTextDesc',
      default: 'True-False'
    }
  },
  {
    type: 'currency',
    detector(value) {
      const matchLength = (value.match(
        // currency prefers starting with 1-3 characters for the currency symbol
        // then it matches against numerical data + $
        /(^[^-(.]{1,3})?[$-(]*[\d,]+(\.\d*)?[$)]*/
      ) || [''])[0].length;

      // if there is no currency symbol then reduce the score
      const hasCurrency = value.indexOf('$') !== -1;
      const confidenceAdjustment = hasCurrency ? 1 : 0.95;

      return (matchLength / value.length) * confidenceAdjustment || 0;
    },
    comparator(a, b, direction) {
      const aValue = parseFloat(
        a
          .split('')
          .filter((char) => numericChars.has(char))
          .join('')
      );
      const bValue = parseFloat(
        b
          .split('')
          .filter((char) => numericChars.has(char))
          .join('')
      );
      if (aValue < bValue) return direction === 'asc' ? -1 : 1;
      if (aValue > bValue) return direction === 'asc' ? 1 : -1;
      return 0;
    },
    icon: 'money',
    color: 'euiColorVis0',
    sortTextAsc: {
      token: 'euiDataGridSchema.currencySortTextAsc',
      default: 'Low-High'
    },
    sortTextDesc: {
      token: 'euiDataGridSchema.currencySortTextDesc',
      default: 'High-Low'
    }
  },
  {
    type: 'datetime',
    detector(value) {
      // matches the most common forms of ISO-8601
      const isoTimestampMatch = value.match(
        // 2019 - 09    - 17     T 12     : 18    : 32      .853     Z or -0600
        /^\d{2,4}-\d{1,2}-\d{1,2}(T?\d{1,2}:\d{1,2}:\d{1,2}(\.\d{3})?(Z|[+-]\d{4})?)?/
      );

      // matches 9 digits (seconds) or 13 digits (milliseconds) since unix epoch
      const unixTimestampMatch = value.match(/^(\d{9}|\d{13})$/);

      const isoMatchLength = isoTimestampMatch
        ? isoTimestampMatch[0].length
        : 0;

      // reduce the confidence of a unix timestamp match to 75%
      // (a column of all unix timestamps should be numeric instead)
      const unixMatchLength = unixTimestampMatch
        ? unixTimestampMatch[0].length * 0.75
        : 0;

      return Math.max(isoMatchLength, unixMatchLength) / value.length || 0;
    },
    icon: 'tokenDate',
    sortTextAsc: {
      token: 'euiDataGridSchema.dateSortTextAsc',
      default: 'Old-New'
    },
    sortTextDesc: {
      token: 'euiDataGridSchema.dateSortTextDesc',
      default: 'New-Old'
    }
  },
  {
    type: 'numeric',
    detector(value) {
      const matchLength = (value.match(/[%-(]*[\d,]+(\.\d*)?[%)]*/) || [''])[0]
        .length;
      return matchLength / value.length || 0;
    },
    comparator(a, b, direction) {
      // sort on all digits groups
      const aGroups = a.split(/\D+/);
      const bGroups = b.split(/\D+/);

      const maxGroups = Math.max(aGroups.length, bGroups.length);
      for (let i = 0; i < maxGroups; i++) {
        // if A and B's group counts differ and they match until that difference, prefer whichever is shorter
        if (i >= aGroups.length) return direction === 'asc' ? -1 : 1;
        if (i >= bGroups.length) return direction === 'asc' ? 1 : -1;

        const aValue = parseInt(aGroups[i]!, 10);
        const bValue = parseInt(bGroups[i]!, 10);

        if (aValue < bValue) return direction === 'asc' ? -1 : 1;
        if (aValue > bValue) return direction === 'asc' ? 1 : -1;
      }

      return 0;
    },
    icon: 'tokenNumber',
    sortTextAsc: {
      token: 'euiDataGridSchema.numberSortTextAsc',
      default: 'Low-High'
    },
    sortTextDesc: {
      token: 'euiDataGridSchema.numberSortTextDesc',
      default: 'High-Low'
    }
  },
  {
    type: 'json',
    detector(value) {
      // does this look like it might be a JSON object?
      const maybeArray = value[0] === '[' && value[value.length - 1] === ']';
      const maybeObject = value[0] === '{' && value[value.length - 1] === '}';
      if (!maybeArray && !maybeObject) return 0;

      try {
        JSON.parse(value);
        return 1;
      } catch {
        return 0;
      }
    },
    comparator(a, b, direction) {
      if (a.length > b.length) return direction === 'asc' ? 1 : -1;
      if (a.length < b.length) return direction === 'asc' ? 1 : -1;
      return 0;
    },
    icon: 'tokenObject',
    sortTextAsc: {
      token: 'euiDataGridSchema.jsonSortTextAsc',
      default: 'Small-Large'
    },
    sortTextDesc: {
      token: 'euiDataGridSchema.jsonSortTextDesc',
      default: 'Large-Small'
    }
  }
];

export function defaultComparator<T>(
  a: T,
  b: T,
  direction: 'asc' | 'desc'
): number {
  if (a < b) return direction === 'asc' ? -1 : 1;
  if (a > b) return direction === 'asc' ? 1 : -1;
  return 0;
}

// completely arbitrary minimum match upstream came up with
// represents lowest score a type detector can have to be considered valid
const MINIMUM_SCORE_MATCH = 0.5;

/** Port of `useDetectSchema` (pure): detect column types from in-memory values. */
export function detectSchema({
  columns,
  inMemory,
  inMemoryValues,
  schemaDetectors: detectors,
  autoDetectSchema
}: {
  columns: EuiDataGridColumn[];
  inMemory?: EuiDataGridInMemory;
  inMemoryValues: EuiDataGridInMemoryValues;
  schemaDetectors: EuiDataGridSchemaDetector[];
  autoDetectSchema: boolean;
}): EuiDataGridSchema {
  const schema: EuiDataGridSchema = {};
  if (autoDetectSchema === false) return schema;

  const definedColumnSchemas = new Set<string>();
  for (const { id, schema: columnSchema } of columns)
    if (columnSchema != null) definedColumnSchemas.add(id);

  const columnSchemas: Record<string, Record<string, number[]>> = {};
  const columnIdsWithDefinedSchemas = new Set([
    ...(inMemory?.skipColumns ?? []),
    ...definedColumnSchemas
  ]);

  // for each row, score each value by each detector and put the results on `columnSchemas`
  for (const rowIndex of Object.keys(inMemoryValues)) {
    const rowData = inMemoryValues[rowIndex]!;
    for (const columnId of Object.keys(rowData)) {
      if (columnIdsWithDefinedSchemas.has(columnId)) continue;
      const schemaColumn = (columnSchemas[columnId] =
        columnSchemas[columnId] || {});
      const columnValue = rowData[columnId]!.trim();
      for (const { type, detector } of detectors) {
        const score = detector(columnValue);
        (schemaColumn[type] = schemaColumn[type] || []).push(score);
      }
    }
  }

  // for each column, reduce each detector type's score to a single value and find the best fit
  for (const columnId of Object.keys(columnSchemas)) {
    const columnScores = columnSchemas[columnId]!;
    let bestType: string | null = null;
    let bestScore = 0;
    for (const typeId of Object.keys(columnScores)) {
      const typeScores = columnScores[typeId]!;
      const mean =
        typeScores.reduce((total, score) => total + score, 0) /
        typeScores.length;
      const sd = Math.sqrt(
        typeScores.reduce(
          (sum, score) => sum + (score - mean) * (score - mean),
          0
        ) / typeScores.length
      );
      // the mean-standard_deviation calculation is fairly arbitrary but fits the patterns
      const score = mean - sd;
      if (score > MINIMUM_SCORE_MATCH && (bestType == null || score > bestScore)) {
        bestType = typeId;
        bestScore = score;
      }
    }
    schema[columnId] = { columnType: bestType };
  }
  return schema;
}

/** Port of `useMergedSchema`: explicit column schemas win over detection. */
export function mergeSchema(
  detected: EuiDataGridSchema,
  columns: EuiDataGridColumn[]
): EuiDataGridSchema {
  const merged: EuiDataGridSchema = { ...detected };
  for (const { id, schema } of columns) {
    if (schema != null) merged[id] = { ...detected[id], columnType: schema };
  }
  return merged;
}

/** Given a provided schema, return the details for the schema. */
export function getDetailsForSchema(
  detectors: EuiDataGridSchemaDetector[],
  providedSchema: string | null | undefined
): EuiDataGridSchemaDetector | undefined {
  return detectors.find((detector) => detector.type === providedSchema);
}
