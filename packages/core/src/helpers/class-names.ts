import { helper } from '@ember/component/helper';

import { deprecateUnusedAfterBorealis } from '../-private/unused-after-borealis.ts';

interface Options {
  [key: string]: unknown;
  /**
   * @deprecated Ignored since the Borealis migration: the legacy Amsterdam
   * class mappings it looked up were removed. Removed in 16.0.0.
   */
  componentName?: string;
  /** @deprecated Only applied with `componentName`; ignored. */
  addBase?: boolean;
}

/**
 * Joins a list of classes, dropping `undefined` entries and extra whitespace.
 *
 * @param classes - List of classes that will be joined
 */
export function classNames(
  classNames: (string | undefined)[] = [],
  options: Options = {}
): string {
  deprecateUnusedAfterBorealis(
    'class-names-component-name',
    `The \`componentName\` option of \`class-names\` (\`${options.componentName}\`) is ignored: the legacy Amsterdam css-mappings it looked up were removed. Style components through their arguments or \`@css\` instead.`,
    options.componentName === undefined
  );

  return classNames.join(' ').replace(/\s+/g, ' ').trim();
}

export default helper<(string | undefined)[], Options, string>(classNames);
