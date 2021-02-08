import { helper } from '@ember/component/helper';

export function isCurriedComponent([obj]: [{}] /*, hash*/): boolean {
  return obj?.constructor?.name === 'CurriedComponentDefinition';
}

export default helper(isCurriedComponent);
