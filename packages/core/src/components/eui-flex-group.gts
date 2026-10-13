import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
import { euiFlexGroupStyles } from '../utils/eui/styles.generated.ts';
import { euiFlexRootReset } from './eui-flex-item.gts';

/** Upstream gutter sizes: `xs`=size.xs, `s`=size.s, `m`=size.base, `l`=size.l, `xl`=size.xxl. */
export type EuiFlexGroupGutterSize = 'none' | 'xs' | 's' | 'm' | 'l' | 'xl';
export type EuiFlexGroupAlignItems =
  | 'stretch'
  | 'flexStart'
  | 'flexEnd'
  | 'center'
  | 'baseline';
export type EuiFlexGroupJustifyContent =
  | 'flexStart'
  | 'flexEnd'
  | 'center'
  | 'spaceBetween'
  | 'spaceAround'
  | 'spaceEvenly';
export type EuiFlexGroupDirection =
  | 'row'
  | 'rowReverse'
  | 'column'
  | 'columnReverse';

export interface EuiFlexGroupSignature {
  Element: HTMLElement;
  Args: {
    /**
     * Space between items (CSS `gap`): `'none'`, `'xs'` (4px), `'s'` (8px),
     * `'m'` (16px), `'l'` (24px) or `'xl'` (40px). Defaults to `'m'`.
     */
    gutterSize?: EuiFlexGroupGutterSize;
    /**
     * Cross axis alignment (`align-items`): `'stretch'`, `'flexStart'`,
     * `'flexEnd'`, `'center'` or `'baseline'`. Defaults to `'stretch'`.
     */
    alignItems?: EuiFlexGroupAlignItems;
    /**
     * Main axis distribution (`justify-content`): `'flexStart'`,
     * `'flexEnd'`, `'center'`, `'spaceBetween'`, `'spaceAround'` or
     * `'spaceEvenly'`. Defaults to `'flexStart'`.
     */
    justifyContent?: EuiFlexGroupJustifyContent;
    /**
     * `'row'`, `'rowReverse'`, `'column'` or `'columnReverse'`.
     * Defaults to `'row'`.
     */
    direction?: EuiFlexGroupDirection;
    /** Lets items wrap onto several lines. Defaults to `false`. */
    wrap?: boolean;
    /**
     * Below the theme's `m` breakpoint (767px in Borealis), wraps the group
     * and makes every direct `EuiFlexItem` full width. Set `false` for rows
     * that must stay on one line (e.g. icon + text). Column directions are
     * never affected. Defaults to `true`.
     */
    responsive?: boolean;
    /**
     * Any tag name, e.g. `'span'` (inside text), `'section'` or `'ul'`
     * (upstream's `component`). Defaults to `'div'`.
     */
    tagName?: string;
    /**
     * Extra styles composed last into this component's class (like upstream's
     * `css` prop). Prefer this to an extra class when styling it from a parent.
     */
    css?: EuiCss;
  };
  Blocks: {
    /** The `EuiFlexItem`s. */
    default: [];
  };
}

export default class EuiFlexGroup extends Component<EuiFlexGroupSignature> {
  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiFlexGroupStyles);
    const direction = this.args.direction ?? 'row';
    // Same order as upstream's `cssStyles`.
    return euiClass(
      context,
      euiFlexRootReset(this.args.tagName),
      styles.euiFlexGroup,
      this.args.responsive !== false && !direction.includes('column')
        ? styles.responsive
        : undefined,
      this.args.wrap ? styles.wrap : undefined,
      styles.gutterSizes[this.args.gutterSize ?? 'm'],
      styles.justifyContent[this.args.justifyContent ?? 'flexStart'],
      styles.alignItems[this.args.alignItems ?? 'stretch'],
      styles.direction[direction],
      this.args.css
    );
  }

  <template>
    {{#let (element (if @tagName @tagName "div")) as |Tag|}}
      {{! @glint-expect-error the tag is not known }}
      <Tag class="euiFlexGroup {{this.classes}}" ...attributes>
        {{yield}}
      </Tag>
    {{/let}}
  </template>
}
