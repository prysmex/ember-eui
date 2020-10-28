import { helper } from '@ember/component/helper';
import { assert } from '@ember/debug';
import cssMappings from '../utils/css-mappings';

interface InlineStylesParams {
  componentName?: string;
  [property: string]: unknown;
}

export function inlineStyles(_:unknown, params: InlineStylesParams) {

  let styles: string[] = [];
  const { componentName, ...properties } = params

  if (componentName) {
    assert(`Could not find component ${componentName} in cssMappings.`, cssMappings[componentName]);
    assert(`Could not find inlineStyles in ${componentName}'s cssMapping.`, cssMappings[componentName].inlineStyles);
    styles.push(...cssMappings[componentName].inlineStyles!?.(properties));
  }

  for(let property in properties) {
    let style;
    if (property === 'background-image' && properties[property] !== 'none') {
      style = `${property}` + `: url(${properties[property]})`;
    } else {
      style = `${property}` + `: ${properties[property]}`;
    }

    styles.push(style);
  }

  return styles.join('; ');
}

export default helper(inlineStyles);
