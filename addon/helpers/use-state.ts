import { helper } from '@ember/component/helper';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';

/**
 * @param value - initial value to use, undefined if not provided.
 *
 * @returns - Object with a `value` property and `setState` method to set the
 *            `value`
 */
class SingleUseState<T> {
  @tracked value: T;

  constructor(value: T) {
    this.value = value;
  }

  @action
  setState(value: T): T {
    this.value = value;
    return value;
  }
}

export function useState<T>([initialValue]: [T]): SingleUseState<T> {
  return new SingleUseState(initialValue);
}

export default helper(useState);
