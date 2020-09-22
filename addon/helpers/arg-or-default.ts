import { helper } from '@ember/component/helper';
import { assert } from '@ember/debug';

/**
 * Helper that returns a default value if the passed argument is undefined
 *
 * @param {array} param
 * @property {unknown} 0 - value to be returned if it's defined
 * @property {unknown} 1 - default value to be returned if value is undefined
 */
export function argOrDefault([value, defaultValue]: [unknown, unknown]): unknown {
  assert('`defaultValue` must be provided', defaultValue !== undefined);
  return value !== undefined ? value : defaultValue;
}

export default helper(argOrDefault);
