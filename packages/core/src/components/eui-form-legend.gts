import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiFormLegendStyles } from '../utils/eui/styles.generated.ts';
import screenReaderOnly from '../modifiers/screen-reader-only.ts';
import { euiFormLabelReset } from './eui-form-label.gts';

import type { CSSObject } from '@emotion/css/create-instance';

/**
 * Upstream `euiScreenReaderOnly` mixin, for the hidden legend's text.
 * EuiScreenReaderOnly is not migrated, so the class the `screenReaderOnly`
 * modifier adds has no styles without the legacy stylesheet. Remove this
 * local stand-in when it migrates.
 */
const screenReaderOnlyCss: CSSObject = {
  '& > .euiScreenReaderOnly': {
    position: 'absolute',
    insetBlockStart: 'auto',
    insetInlineStart: '-10000px',
    inlineSize: '1px',
    blockSize: '1px',
    clip: 'rect(0 0 0 0)',
    clipPath: 'inset(50%)',
    overflow: 'hidden',
    margin: '-1px'
  }
};

/** The legend of an EuiFormFieldset. */
export interface EuiFormLegendSignature {
  Element: HTMLLegendElement;
  Args: {
    /** `'hidden'` keeps it for screen readers only. Defaults to `'visible'`. */
    display?: 'hidden' | 'visible';
    /** Smaller space under the legend, for compressed forms. */
    compressed?: boolean;
  };
  Blocks: {
    /** The legend text. */
    default: [];
  };
}

export default class EuiFormLegend extends Component<EuiFormLegendSignature> {
  get isHidden() {
    return this.args.display === 'hidden';
  }

  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiFormLegendStyles);
    // Same order as upstream's `cssStyles`.
    return euiClass(
      context,
      euiFormLabelReset(context.upstream),
      styles.euiFormLegend,
      this.isHidden
        ? undefined
        : this.args.compressed
          ? styles.compressed
          : styles.uncompressed,
      this.isHidden ? screenReaderOnlyCss : undefined
    );
  }

  <template>
    <legend
      class="euiFormLegend
        {{if this.isHidden 'euiFormLegend-isHidden'}}
        {{this.classes}}"
      ...attributes
    >
      {{#if this.isHidden}}
        <span {{screenReaderOnly}}>
          {{yield}}
        </span>
      {{else}}
        {{yield}}
      {{/if}}
    </legend>
  </template>
}
