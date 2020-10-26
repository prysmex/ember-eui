import { helper } from '@ember/component/helper';
import { action, defineProperty } from '@ember/object';
import { tracked } from '@glimmer/tracking';
import { assert } from '@ember/debug';

interface StatefulProperty {
  get: () => unknown;
  set: (value: unknown) => void;
}

function setterFn (context: MultipleUseState, prop: string): (value: unknown) => void {
  return function (value) {
    context[`${prop}Value`] = value;
  }
}

/**
 * @param value - initial value to use, undefined if not provided.
 *
 * @returns - Object with `get` and `set` methods to retrieve and set the
 *            `value` respectively.
 */
class SingleUseState {
  @tracked
  value: unknown;

  constructor (value: unknown) {
    this.value = value;

    defineProperty(this, 'get', {
      get (this: SingleUseState) {
        return this.value;
      }
    });
  }

  @action
  set (value: unknown) {
    this.value = value;
  }
}

/**
 * @param {Object} values - initial values to use, if a value is not provided
 *            undefined is used.
 *            The keys are the properties we want to be stateful.
 *
 * @returns - Object with each passed key in which each property has a `get`
 *            and `set` methods to retrieve and set the `value` respectively.
 */
class MultipleUseState {
  [property: string]: StatefulProperty | unknown;

  constructor (values: Record<string, unknown>) {
    Object.keys(values).forEach(prop => {
      this.addProperty(prop, values[prop]);
    });
  }

  hasProperty (prop: string): boolean {
    return this.hasOwnProperty(prop);
  }

  addProperty (prop: string, initialValue?: unknown): void {
    // Define the internal property for tracking
    let baseDescriptor = {
      writable: true,
      enumerable: true,
      configurable: true,
      initializer: function () {
        return initialValue;
      }
    };

    let trackedDescriptor = tracked.call(null, this, `${prop}Value`, baseDescriptor) as unknown as PropertyDescriptor;
    defineProperty(this, `${prop}Value`, trackedDescriptor);

    // Create the object with `get` and `set` methods
    const setFn = setterFn(this, prop);
    let statefulProp = {
      set: (value: unknown) => {
        return setFn(value);
      }
    };

    defineProperty(statefulProp, 'get', {
      enumerable: true,
      get: () => {
        return this[`${prop}Value`];
      }
    });

    this[prop] = statefulProp;
  }
}

export function useState(
  [...initialValues]: [unknown],
  params: Record<string, unknown>
  ): SingleUseState | MultipleUseState
{
  const { ...rest } = params;

  const hasParams = Object.keys(rest).length > 0;
  const hasMultipleValues = initialValues.length > 1;

  // Must use the `MultipleUseState` class if there's more than 1 value
  if (hasMultipleValues) {
    assert(`Incorrect use of 'use-state'.\n
    Must be used with either an array of properties or hashed properties with
    their initial values.\n
    {{use-state var1 var2 ... varN}} or {{use-state var1=val1 var2=val2 ... varN=valN}}\n
    When multiple strings are passed they are the names of the properties to set on the state;
    these properties get initialized to 'undefined'.
    `, hasMultipleValues && !hasParams);

    // We got an array, transpose it to an object
    const values = initialValues.reduce<Record<string, unknown>>((acc, prop: string) => {
      acc[prop] = undefined;
      return acc;
    }, {});
    return new MultipleUseState(values);
  } else if (hasParams) {
    assert(`Incorrect use of 'use-state'.\n
    Must be used with either an array of properties or hashed properties with
    their initial values.\n
    {{use-state var1 var2 ... varN}} or {{use-state var1=val1 var2=val2 ... varN=valN}}
    `, !hasMultipleValues && hasParams);
    return new MultipleUseState(params);
  }

  return new SingleUseState(initialValues[0]);
}

export default helper(useState);
