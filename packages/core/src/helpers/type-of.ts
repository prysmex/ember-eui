import { helper } from '@ember/component/helper';
import { typeOf as emberTypeOf } from '@ember/utils';

export function typeOf<T>([subject]: [T]) {
  return emberTypeOf<T>(subject);
}

export default helper(typeOf);
