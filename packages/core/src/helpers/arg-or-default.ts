import { helper } from '@ember/component/helper';
import { assert } from '@ember/debug';
import { get } from '@ember/object';

let config = {};

/**
 * Helper that returns a default value if the passed argument is undefined
 *
 * @param {array} param
 * @property {V} 0 - value to be returned if it's defined
 * @property {DV} 1 - default value to be returned if value is undefined
 */
export function argOrDefault<V, DV>(
  [value, defaultValue]: [V | undefined, DV],
  { configKey }: { configKey?: string }
): V | DV {
  assert('`defaultValue` must be provided', defaultValue !== undefined);

  let configValue: DV | undefined;

  if (configKey) {
    configValue = get(config, configKey) as unknown as DV;
  }

  if (value !== undefined) {
    return value;
  }

  if (configValue !== undefined) {
    return configValue;
  }

  return defaultValue!;
}

//eslint-disable-next-line
export function argOrDefaultDecorator<T>(
  defaultValue: T,
  configKey?: string
): any {
  return function (_target: any, key: string) {
    return {
      get(this: { args: Record<string, T> }): T {
        return argOrDefault([this.args[key], defaultValue], {
          configKey: configKey
        }) as T;
      }
    };
  };
}

export default helper(argOrDefault);
