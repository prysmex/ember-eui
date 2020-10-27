import { helper } from '@ember/component/helper';
import cssMappings from '../utils/css-mappings';

export function inlineStyles(_:unknown, params:Record<string, unknown>) {

  let styles: string[] = [];
  const { componentName, ...properties } = params

  if (componentName) {
    styles.push(...cssMappings[componentName as string].inlineStyles(properties))
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
