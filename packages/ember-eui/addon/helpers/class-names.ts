import { helper } from '@ember/component/helper';
import { assert } from '@ember/debug';

// Mappings registry
import cssMappings from '../utils/css-mappings';

interface IObjectKeys {
  [key: string]: string | number;
}
interface Options extends IObjectKeys {
  size: string;
  paddingSize: string;
  textAlign: string;
  color: string;
  verticalPosition: string;
  horizontalPosition: string;
  componentName: string;
  textTransform: string;
  display: string;
  type: string;
  gutterSize: string;
  alignItems: string;
  direction: string;
  justifyContent: string;
  columns: number;
  grow: number | string;
  iconSide: string;
  flush: string;
  borderSide: string;
  position: string;
  theme: string;
  margin: string;
  borderRadius: string;
  backgroundColor: string;
  resize: string;
}

/**
 * Joins a list of classes
 *
 * @param classes - List of classes that will be joined
 */
export function classNames(classNames: string[] = [], options: Options): string {
  let { componentName, ...rest } = options;
  let str = `${classNames.join(' ')}`;
  if (options.componentName) {
    assert(
      `The component '${options.componentName}' doesn't have mappings defined`,
      cssMappings[options.componentName] !== undefined
    );
    const component = cssMappings[options.componentName];
    str = `${str} ${component.base}`;

    for (let key in rest) {
      if (component.properties[key] && component.properties[key][rest[key]]) {
        str = `${str} ${component.properties[key][rest[key]]}`;
      }
    }
  }
  return str;
}

export default helper(classNames);
