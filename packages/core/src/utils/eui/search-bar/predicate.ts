/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License
 * 2.0 and the Server Side Public License, v 1; you may not use this file except
 * in compliance with, at your election, the Elastic License 2.0 or the Server
 * Side Public License, v 1.
 */

// Port of upstream EUI 123.1.0 `services/predicate` (with the moment
// predicates the shared Ember copy leaves out), `services/objects#get` and
// `components/common#keysOf`, as used by the search query engine, the
// basic table and the in-memory table.

import _get from 'lodash-es/get';
import moment from 'moment';

export {
  isArray,
  isBoolean,
  isFunction,
  isNaN,
  isNil,
  isNumber,
  isObject,
  isString
} from '../../predicate/index.ts';

export const isMoment = (value: any): value is moment.Moment => {
  return moment.isMoment(value);
};

export const isDate = (value: any): value is Date => {
  return moment.isDate(value);
};

export const isDateLike = (value: any): value is moment.Moment | Date => {
  return isMoment(value) || isDate(value);
};

export const get = (object: {}, path: string[] | string, defaultValue?: any) =>
  _get(object, path, defaultValue);

export const keysOf = <T extends {}, K extends keyof T>(obj: T): K[] =>
  Object.keys(obj) as K[];

