import { helper } from '@ember/component/helper';
import { assert } from '@ember/debug';
import cssMappings from '../utils/css-mappings';

interface InlineStylesParams {
  componentName?: string;
  componentArgs?: Record<string, unknown>;
  [property: string]: unknown;
}

export function inlineStyles(_: unknown, params: InlineStylesParams) {
  const { componentName, componentArgs = {}, ...properties } = params;
  let componentStyles = {};

  if (componentName) {
    assert(
      `Could not find component ${componentName} in cssMappings.`,
      cssMappings[componentName]
    );
    assert(
      `Could not find inlineStyles in ${componentName}'s cssMapping.`,
      cssMappings[componentName]?.inlineStyles
    );
    componentStyles =
      cssMappings[componentName]?.inlineStyles?.(componentArgs) || {};
  }

  let finalProperties: {
    [name: string]: string | undefined;
  } = {
    ...properties,
    ...componentStyles
  };

  for (let property in finalProperties) {
    if (
      property === 'background-image' &&
      finalProperties[property] !== 'none'
    ) {
      finalProperties[property] = `url(${finalProperties[property]})`;
    } else {
      finalProperties[property] = `${finalProperties[property]}`;
    }
  }

  return finalProperties;
}

export default helper(inlineStyles);
