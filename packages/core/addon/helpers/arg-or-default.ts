import { helper } from '@ember/component/helper';
import { assert } from '@ember/debug';
//@ts-ignore
import config from 'ember-get-config';

/**
 * Helper that returns a default value if the passed argument is undefined
 *
 * @param {array} param
 * @property {unknown} 0 - value to be returned if it's defined
 * @property {unknown} 1 - default value to be returned if value is undefined
 */
export function argOrDefault(
  [value, defaultValue]: [unknown, unknown],
  { configKey }: { configKey?: string }
): unknown {
  assert('`defaultValue` must be provided', defaultValue !== undefined);
  let configValue;
  if (configKey) {
    configValue = config['@ember-eui/core']?.[configKey];
  }
  return value !== undefined ? value : configValue || defaultValue;
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
