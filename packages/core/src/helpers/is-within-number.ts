import { helper } from '@ember/component/helper';

import { isWithinRange as isWithin } from '../utils/number/index.ts';

type Comparator = {
  min: number | string;
  max: number | string;
  value: number | string;
};

export function isWithinRange(
  _: unknown[],
  { min, max, value }: Comparator
): boolean {
  return isWithin(min, max, value);
}

export default helper(isWithinRange);
