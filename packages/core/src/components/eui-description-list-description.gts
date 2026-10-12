import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import {
  atMedia,
  columnQuery,
  descriptionListContext
} from '../-private/eui-list-context.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiDescriptionListDescriptionStyles } from '../utils/eui/styles.generated.ts';


import type { CSSInterpolation } from '@emotion/css/create-instance';

/**
 * The description (`<dd>`) of the term before it, in an EuiDescriptionList.
 * Its styles follow the nearest list's `@type`, `@textStyle`, `@compressed`
 * and `@align`.
 */
export interface EuiDescriptionListDescriptionSignature {
  Element: HTMLElement;
  Blocks: {
    /** The text. */
    default: [];
  };
}

/** Scoped stand-in for React's global reset. */
const RESET = { boxSizing: 'border-box' as const, margin: 0, padding: 0 };

/** Native Ember description list description using the upstream EUI 123 / Borealis factory. */
export default class EuiDescriptionListDescription extends Component<EuiDescriptionListDescriptionSignature> {
  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(
      context,
      euiDescriptionListDescriptionStyles
    );
    const { type, textStyle, compressed, align } = descriptionListContext(this);
    const fontStyles = compressed
      ? textStyle === 'reverse'
        ? styles.fontStyles.compressed
        : styles.fontStyles.compressedNormal
      : styles.fontStyles[textStyle];
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
        typeStyles = [styles.row, fontStyles];
        break;
      case 'column':
        typeStyles = [styles.column, fontStyles, align === 'center' && styles.left];
        break;
      default:
        // `responsiveColumn`: upstream renders row below `m`, column above.
        typeStyles = [
          fontStyles,
          align === 'center' && atMedia(columnQuery(context), styles.left)
        ];
    }
    return `euiDescriptionList__description ${euiClass(
      context,
      RESET,
      styles.euiDescriptionList__description,
      ...typeStyles
    )}`;
  }

  <template>
    <dd class={{this.classes}} ...attributes>
      {{yield}}
    </dd>
  </template>
}
