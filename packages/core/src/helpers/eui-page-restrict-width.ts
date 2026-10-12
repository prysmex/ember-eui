import { helper } from '@ember/component/helper';

import { deprecateUnusedAfterBorealis } from '../-private/unused-after-borealis.ts';

export type _EuiPageRestrictWidth = {
  /**
   * Sets the max-width of the page,
   * set to `true` to use the default size of `1000px (1200 for Amsterdam)`,
   * set to `false` to not restrict the width,
   * set to a number for a custom width in px,
   * set to a string for a custom width in custom measurement.
   */
  restrictWidth?: boolean | number | string;
};

/**
 * @deprecated Unused since the Borealis migration: page components set an
 * inline `max-width` themselves. Removed in 16.0.0.
 */
export function restrictWidth(
  restrictWidth: _EuiPageRestrictWidth['restrictWidth'],
  style?: Record<string, unknown>
) {
  deprecateUnusedAfterBorealis(
    'eui-page-restrict-width',
    'The `eui-page-restrict-width` helper (`restrictWidth`) is deprecated; its `restrictWidth-*` classes have no styles. Pass `@restrictWidth` to the page components instead.'
  );

  let widthClassName;
  let newStyle = {
    ...(style || {})
  };

  if (restrictWidth === true) {
    widthClassName = 'restrictWidth-default';
  } else if (restrictWidth !== false) {
    widthClassName = 'restrictWidth-custom';
    newStyle = {
      ...newStyle,
      maxWidth:
        typeof restrictWidth === 'number' ? `${restrictWidth}px` : restrictWidth
    };
  }

  return { widthClassName, newStyle };
}

export default helper(function ([restrict, style]: [
  _EuiPageRestrictWidth['restrictWidth'],
  Record<string, unknown> | undefined
]) {
  return restrictWidth(restrict, style);
});
