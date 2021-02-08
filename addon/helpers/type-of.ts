import { helper } from '@ember/component/helper';
import { typeOf } from '@ember/utils';

export function startsWith([subject, kind]: [string, string] /*, hash*/): boolean {
  return typeOf(subject) === kind;
}

export default helper(startsWith);
