import { helper } from '@ember/component/helper';
import { assert } from '@ember/debug';

// Mappings registry
import attrMappings from '../utils/attribute-mappings';

interface Options {
  componentName: string;
}

/**
 * Returns a value based on the mapped attribute
 *
 * @param attrName - Attribute to get the map for
 * @param attrValue - Value to look for in the attribute's map
 * @param componentName - Component to look the attribute in
 *
 * @returns unknown - Can return any value according to the map, even null or undefined
 */
export function attrMap(
  [attrName, attrValue]: [string, string],
  {
    componentName
  }: Options
): unknown {
  assert(
    `The component '${componentName}' doesn't have mappings defined`,
    attrMappings[componentName] !== undefined
  );

  assert(`'attrName' must be provided`, attrName !== undefined);
  assert(`'attrValue' must be provided`, attrValue !== undefined);

  assert(`'${attrValue}' is not defined in '${attrName}'`, attrMappings[componentName][attrName].hasOwnProperty(attrValue));

  return attrMappings[componentName][attrName][attrValue];
}

export default helper(attrMap);
