import Component from '@glimmer/component';

import style from 'ember-style-modifier/modifiers/style';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import {
  composedOver,
  euiPageBoxSizing,
  euiPagePadding,
  euiPageRestrictWidthStyle,
  isRestricted
} from '../utils/eui/page-layout.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiPageBodyStyles } from '../utils/eui/styles.generated.ts';
import EuiPanel from './eui-panel.gts';

import type { EuiPanelSignature } from './eui-panel';

/** The main column of an EuiPage: header, content and so on. */
export interface EuiPageBodySignature {
  Element: EuiPanelSignature['Element'];
  Args: {
    /**
     * Max width of the body, centered: `true` for EUI's default (1200px),
     * a number in px, or any CSS width. Defaults to `false` (no limit).
     */
    restrictWidth?: boolean | number | string;
    /** Tag of the body (without `@panelled`). Defaults to `'div'`. */
    tagName?: string;
    /** Border radius of the panel: `'none'` or `'m'`. Defaults to `'none'`. */
    borderRadius?: EuiPanelSignature['Args']['borderRadius'];
    /**
     * Padding: `'none'`, `'s'`, `'m'` or `'l'`. Defaults to `'none'`, as
     * upstream, also when `@panelled` (formerly `'l'` when panelled).
     */
    paddingSize?: EuiPanelSignature['Args']['paddingSize'];
    /** Renders the body as an `EuiPanel` (plain background, border). */
    panelled?: boolean;
    /** Panel background (with `@panelled`), any `EuiPanel` color. */
    color?: EuiPanelSignature['Args']['color'];
    /** Panel border (with `@panelled`). Defaults to EuiPanel's (`true`). */
    hasBorder?: boolean;
    /** Panel shadow (with `@panelled`). Defaults to EuiPanel's (`false`). */
    hasShadow?: boolean;
    /** Inline styles, merged with the max width. */
    style?: Record<string, string>;
  };
  Blocks: {
    /** Usually an `EuiPageHeader` and `EuiPageContent`. */
    default: [];
  };
}

/** Upstream `EuiPageBody` (`euiPageBodyStyles`) on the Borealis theme. */
export default class EuiPageBody extends Component<EuiPageBodySignature> {
  get tagName() {
    return this.args.tagName ?? 'div';
  }

  get paddingSize(): NonNullable<EuiPanelSignature['Args']['paddingSize']> {
    return this.args.paddingSize ?? 'none';
  }

  get bodyStyles() {
    const styles = euiPageBodyStyles();
    return [
      styles.euiPageBody,
      isRestricted(this.args.restrictWidth) && styles.restrictWidth
    ];
  }

  get classes() {
    const context = getEuiThemeContext(this);
    useEuiBorealisStyles(context, euiPageBodyStyles);
    return euiClass(
      context,
      euiPageBoxSizing,
      ...this.bodyStyles,
      euiPagePadding(context.upstream, this.paddingSize)
    );
  }

  /** Upstream passes the body styles as the panel's `css`, after its own. */
  get panelClasses() {
    return euiClass(getEuiThemeContext(this), composedOver(...this.bodyStyles));
  }

  get inlineStyle() {
    return euiPageRestrictWidthStyle(this.args.restrictWidth, this.args.style);
  }

  <template>
    {{#if @panelled}}
      <EuiPanel
        class="euiPageBody {{this.panelClasses}}"
        @paddingSize={{this.paddingSize}}
        @borderRadius={{if @borderRadius @borderRadius "none"}}
        @color={{@color}}
        @hasBorder={{@hasBorder}}
        @hasShadow={{@hasShadow}}
        {{style this.inlineStyle}}
        ...attributes
      >
        {{yield}}
      </EuiPanel>
    {{else}}
      {{#let (element this.tagName) as |Tag|}}
        <Tag
          class="euiPageBody {{this.classes}}"
          {{style this.inlineStyle}}
          {{!@glint-expect-error}}
          ...attributes
        >
          {{yield}}
        </Tag>
      {{/let}}
    {{/if}}
  </template>
}
