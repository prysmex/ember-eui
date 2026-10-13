/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License
 * 2.0 and the Server Side Public License, v 1; you may not use this file except
 * in compliance with, at your election, the Elastic License 2.0 or the Server
 * Side Public License, v 1.
 */

// The EuiSearchBar query engine: a port of upstream EUI 123.1.0
// `components/search_bar/query` (pure TypeScript, no framework code).

export { Query } from './query.ts';
export { AST, Operator, Match } from './ast.ts';
export { defaultSyntax } from './default-syntax.ts';
export { executeAst } from './execute-ast.ts';
export { dateValue, isDateValue } from './date-value.ts';
export { dateFormat } from './date-format.ts';

export type {
  _AST,
  Clause,
  FieldClause,
  GroupClause,
  IsClause,
  OperatorType,
  TermClause,
  Value
} from './ast.ts';
export type { ParseOptions, Syntax } from './default-syntax.ts';
export type { DateValue } from './date-value.ts';
