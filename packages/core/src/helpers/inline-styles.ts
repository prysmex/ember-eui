import { helper } from '@ember/component/helper';

import { deprecateUnusedAfterBorealis } from '../-private/unused-after-borealis.ts';

interface InlineStylesParams {
  /**
   * @deprecated Ignored since the Borealis migration: the legacy Amsterdam
   * css-mappings it looked up were removed. Removed in 16.0.0.
   */
  componentName?: string;
  /** @deprecated Only used with `componentName`; ignored. */
  componentArgs?: Record<string, unknown>;
  [property: string]: unknown;
}

export function inlineStyles(_: unknown, params: InlineStylesParams) {
  const {
    componentName,
    componentArgs: _componentArgs,
    ...properties
  } = params;

  deprecateUnusedAfterBorealis(
    'inline-styles-component-name',
    `The \`componentName\` option of \`inline-styles\` (\`${componentName}\`) is ignored: the legacy Amsterdam css-mappings it looked up were removed.`,
    componentName === undefined
  );

  const finalProperties: {
    [name: string]: string | undefined;
  } = {
    ...(properties as Record<string, string | undefined>)
  };

  for (const property in finalProperties) {
    if (
      property === 'background-image' &&
      finalProperties[property] !== 'none'
    ) {
      finalProperties[property] = `url('${finalProperties[property]}')`;
    } else {
      finalProperties[property] = `${finalProperties[property]}`;
    }
  }

  return finalProperties;
}

export default helper(inlineStyles);
