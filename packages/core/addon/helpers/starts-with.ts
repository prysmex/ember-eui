import { helper } from '@ember/component/helper';

export function startsWith(
  [needle, word]: [string, string] /*, hash*/
): boolean {
  return word?.startsWith(needle) || false;
}

export default helper(startsWith);
