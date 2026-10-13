import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import {
  atMedia,
  columnQuery,
  descriptionListContext,
  rowQuery
} from '../-private/eui-list-context.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiDescriptionListTitleStyles } from '../utils/eui/styles.generated.ts';


import type { CSSInterpolation } from '@emotion/css/create-instance';

/**
 * A term (`<dt>`) in an EuiDescriptionList. Its styles follow the nearest
 * list's `@type`, `@textStyle`, `@compressed`, `@align` and `@rowGutterSize`.
 */
export interface EuiDescriptionListTitleSignature {
  Element: HTMLElement;
  Blocks: {
    /** The text. */
    default: [];
  };
}

/** Scoped stand-in for React's global reset. */
const RESET = { boxSizing: 'border-box' as const, margin: 0, padding: 0 };

/** Native Ember description list title using the upstream EUI 123 / Borealis factory. */
export default class EuiDescriptionListTitle extends Component<EuiDescriptionListTitleSignature> {
  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiDescriptionListTitleStyles);
    const { type, textStyle, compressed, align, rowGutterSize } =
      descriptionListContext(this);
    const fontStyles = compressed
      ? textStyle !== 'reverse'
        ? styles.fontStyles.compressed
        : styles.fontStyles.compressedReverse
      : styles.fontStyles[textStyle];
    const rowStyles = [styles.row, fontStyles, styles[rowGutterSize]];
    const columnStyles = [
      styles.column,
      fontStyles,
      align === 'center' && styles.right
    ];
    let typeStyles: CSSInterpolation[];
    switch (type) {
      case 'inline':
        typeStyles = [
          styles.inline,
          compressed
            ? styles.inlineStyles.compressed
            : styles.inlineStyles.normal
        ];
        break;
      case 'row':
        typeStyles = rowStyles;
        break;
      case 'column':
        typeStyles = columnStyles;
        break;
      default:
        // `responsiveColumn`: upstream renders row below `m`, column above.
        typeStyles = [
          fontStyles,
          atMedia(rowQuery(context), ...rowStyles),
          atMedia(columnQuery(context), ...columnStyles)
        ];
    }
    return `euiDescriptionList__title ${euiClass(
      context,
      RESET,
      styles.euiDescriptionList__title,
      ...typeStyles
    )}`;
  }

  <template>
    <dt class={{this.classes}} ...attributes>
      {{yield}}
    </dt>
  </template>
}
