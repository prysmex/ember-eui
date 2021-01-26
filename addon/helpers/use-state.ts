import { helper } from '@ember/component/helper';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';

/**
 * @param value - initial value to use, undefined if not provided.
 *
 * @returns - Object with `get` and `set` methods to retrieve and set the
 *            `value` respectively.
 */
class SingleUseState {
  @tracked value: unknown;

  constructor(value: unknown) {
    this.value = value;
  }

  @action
  setState(value: unknown) {
    this.value = value;
  }
}

export function useState([initialValue]: [unknown]): SingleUseState {
  return new SingleUseState(initialValue);
}

export default helper(useState);
