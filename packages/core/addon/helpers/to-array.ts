//@ts-nocheck
import { helper } from '@ember/component/helper';
import { isArray } from '@ember/array';
import { maybeUnwrapProxy } from '../utils/maybe-unwrap-proxy';

export function toArray<T>([maybeArray]: [T[] | T]): T[] {
  let val = maybeUnwrapProxy(maybeArray) as T | T[];
  if (val !== null && val !== undefined) {
    return isArray(val) ? val : [val];
  }

  return [];
}

export default helper(toArray);
