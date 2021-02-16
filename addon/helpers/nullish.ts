import { helper } from '@ember/component/helper';

export function nullish<A = unknown, B = unknown>([that, fallback]: [A, B]): A | B {
  return that !== null && that !== undefined ? that : fallback;
}

export default helper(nullish);
