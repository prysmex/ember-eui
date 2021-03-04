import { helper } from '@ember/component/helper';
import { typeOf as EmberTypeOf } from '@ember/utils';

export function typeOf([subject]: [unknown], { useNative = false }): string {
  return useNative ? typeof subject : EmberTypeOf(subject);
}

export default helper(typeOf);
