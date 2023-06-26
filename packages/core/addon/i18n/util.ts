/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License
 * 2.0 and the Server Side Public License, v 1; you may not use this file except
 * in compliance with, at your election, the Elastic License 2.0 or the Server
 * Side Public License, v 1.
 */

import { isBoolean, isString, isNumber, isUndefined } from '../utils/predicate';
import { get } from '@ember/object';
import { assert } from '@ember/debug';

function isPrimitive(value: any) {
  return (
    isBoolean(value) || isString(value) || isNumber(value) || isUndefined(value)
  );
}

type Child = string | { propName: string };

function hasPropName(child: Child): child is { propName: string } {
  return child
    ? typeof child === 'object' && child.hasOwnProperty('propName')
    : false;
}

function isElement(value: any) {
  return value.hasOwnProperty('propName') && !isPrimitive(value);
}

/**
 * Replaces placeholder values in `input` with their matching value in `values`
 * e.g. input:'Hello, {name}' will replace `{name}` with `values[name]`
 * @param {string} input
 * @param {RenderableValues} values
 * @param {Function} i18nMappingFunc
 * @returns {string}
 */
export function processStringToChildren(
  input: string,
  values: { [key: string]: any },
  i18nMappingFunc?: (token: string) => string
): any[] | string {
  const children: any[] = [];

  let child: Child | undefined = { propName: '' };

  function appendCharToChild(char: string) {
    if (child === undefined) {
      // starting a new string literal
      child = char;
    } else if (typeof child === 'string') {
      // existing string literal
      child = child + char;
    } else if (hasPropName(child)) {
      // adding to the propName of a values lookup
      child.propName = child.propName + char;
    }
  }

  function appendValueToChildren(value?: Child) {
    if (value === undefined) {
      return;
    } else if (hasPropName(value)) {
      // an array with any ReactElements will be kept as an array
      // so they need to be assigned a key
      // children.push(cloneElement(value, { key: children.length }));
      children.push(value.propName);
    } else if (isElement(value)) {
      // this won't be called, propName children are converted to a ReactChild before calling this
    } else {
      // everything else can go straight in
      if (i18nMappingFunc !== undefined && typeof value === 'string') {
        value = i18nMappingFunc(value);
      }
      children.push(value);
    }
  }

  // if we don't encounter a non-primitive
  // then `children` can be concatenated together at the end
  let encounteredNonPrimitive = false;
  for (let i = 0; i < input.length; i++) {
    const char = input[i];

    if (char === '\\') {
      // peek at the next character to know if this is an escape
      const nextChar = input[i + 1];
      let charToAdd = char; // if this isn't an escape sequence then we will add the backslash

      if (nextChar === '{' || nextChar === '}') {
        // escaping a brace
        i += 1; // advance passed the brace
        charToAdd = input[i];
      }
      appendCharToChild(charToAdd);
    } else if (char === '{') {
      appendValueToChildren(child);
      child = { propName: '' };
    } else if (char === '}') {
      const propName = (child as { propName: string }).propName as string;
      if (get(values, propName) === undefined) {
        assert(
          `Key "${propName}" not found in ${JSON.stringify(values, null, 2)}`,
          true
        );
      }
      const propValue = values[propName];
      encounteredNonPrimitive =
        encounteredNonPrimitive || !isPrimitive(propValue);
      appendValueToChildren(propValue);
      child = undefined;
    } else {
      appendCharToChild(char);
    }
  }

  // include any remaining child value
  appendValueToChildren(child);

  return encounteredNonPrimitive ? children : children.join('');
}
