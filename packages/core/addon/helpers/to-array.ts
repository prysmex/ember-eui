import { helper } from '@ember/component/helper';
import { isArray } from '@ember/array';

export function toArray<T>([maybeArray]: [T[] | T]): T[] {
  return isArray(maybeArray) ? maybeArray : [maybeArray];
}

export default helper(toArray);
