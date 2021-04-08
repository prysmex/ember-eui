import { helper } from '@ember/component/helper';
import { isArray } from '@ember/array';

export function toArray<T>([maybeArray]: [T[] | T]): T[] {
  if (maybeArray !== null && maybeArray !== undefined) {
    return isArray(maybeArray) ? maybeArray : [maybeArray];
  }

  return [];
}

export default helper(toArray);
