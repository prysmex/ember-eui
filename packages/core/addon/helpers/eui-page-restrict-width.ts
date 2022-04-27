import { helper } from '@ember/component/helper';
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

export function restrictWidth(
  restrictWidth: _EuiPageRestrictWidth['restrictWidth'],
  style?: Record<string, unknown>
) {
  let widthClassName;
  let newStyle = {};

  if (restrictWidth === true) {
    widthClassName = 'restrictWidth-default';
  } else if (restrictWidth !== false) {
    widthClassName = 'restrictWidth-custom';
    newStyle = { ...style, maxWidth: restrictWidth };
  }

  return { widthClassName, newStyle };
}

export default helper(function ([restrict, style]: [
  _EuiPageRestrictWidth['restrictWidth'],
  Record<string, unknown> | undefined
]) {
  return restrictWidth(restrict, style);
});
