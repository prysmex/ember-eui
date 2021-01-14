import { helper } from '@ember/component/helper';
import { assert } from '@ember/debug';
import cssMappings from '../utils/css-mappings';

interface InlineStylesParams {
  componentName?: string;
  componentArgs?: Record<string, unknown>;
  [property: string]: unknown;
}
interface FinalProperties {
  [name: string]: unknown
}

export function inlineStyles(_: unknown, params: InlineStylesParams) {
  let styles: string[] = [];
  const { componentName, componentArgs = {}, ...properties } = params;
  let componentStyles = {};

  if (componentName) {
    assert(`Could not find component ${componentName} in cssMappings.`, cssMappings[componentName]);
    assert(
      `Could not find inlineStyles in ${componentName}'s cssMapping.`,
      cssMappings[componentName].inlineStyles
    );
    componentStyles = cssMappings[componentName].inlineStyles?.(componentArgs) || {};
  }

  let finalProperties: FinalProperties = {
    ...properties,
    ...componentStyles,
  };

  for (let property in finalProperties) {
    let style;
    if (property === 'background-image' && finalProperties[property] !== 'none') {
      style = `${property}` + `: url(${finalProperties[property]})`;
    } else {
      style = `${property}` + `: ${finalProperties[property]}`;
    }

    styles.push(style);
  }

  return styles.join('; ');
}

export default helper(inlineStyles);
