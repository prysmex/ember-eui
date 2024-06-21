import { helper } from '@ember/component/helper';
import { assert } from '@ember/debug';

// Mappings registry
import cssMappings from '../utils/css-mappings/index.ts';

interface Options {
  [key: string]: unknown;
  size?: string | number | boolean | {};
  side?: string;
  paddingSize?: string;
  textAlign?: string;
  textStyle?: string;
  color?: string;
  verticalPosition?: string;
  horizontalPosition?: string;
  componentName?: keyof typeof cssMappings;
  textTransform?: string;
  display?: string;
  type?: string;
  gutterSize?: string;
  alignItems?: string;
  direction?: string;
  justifyContent?: string;
  columns?: number;
  grow?: number | string | boolean;
  iconSide?: string;
  flush?: string | boolean;
  borderSide?: string;
  position?: string;
  theme?: string;
  margin?: string;
  borderRadius?: string;
  backgroundColor?: string;
  resize?: string;
  addBase?: boolean;
}

/**
 * Joins a list of classes
 *
 * @param classes - List of classes that will be joined
 */
export function classNames(
  classNames: (string | undefined)[] = [],
  options: Options
): string {
  let { componentName, ...rest } = options;
  let includeBase = options.addBase !== false;
  let str = `${classNames.join(' ')}`;

  if (options.componentName) {
    assert(
      `The component '${options.componentName}' doesn't have mappings defined`,
      cssMappings[options.componentName] !== undefined
    );

    const component = cssMappings[options.componentName]!;

    if (includeBase) {
      str = `${str} ${component.base}`;
    }

    for (let key in rest) {
      //@ts-expect-error
      if (component.properties[key] && component.properties[key]?.[rest[key]]) {
        //@ts-expect-error
        str = `${str} ${component.properties[key]?.[rest[key]]}`;
      }
    }
  }

  return str;
}

export default helper<(string | undefined)[], Options, string>(classNames);
