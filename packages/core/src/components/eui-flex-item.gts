import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { eq } from 'ember-truth-helpers';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass } from '../utils/eui/styles.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
import { euiFlexItemStyles } from '../utils/eui/styles.generated.ts';

import type { CSSObject } from '@emotion/css/create-instance';

/** Tags whose browser margins/padding/markers React EUI's global reset removes. */
const SPACED_TAGS = new Set(['ul', 'ol', 'dl', 'p', 'figure', 'blockquote']);

/**
 * @private The part of React EUI's global reset that flex roots rely on:
 * border-box sizing, and no browser spacing when rendered as a list,
 * paragraph or figure (Ember has no global reset).
 */
export function euiFlexRootReset(tagName: string | undefined): CSSObject {
  return SPACED_TAGS.has(tagName ?? 'div')
    ? { boxSizing: 'border-box', margin: 0, padding: 0, listStyle: 'none' }
    : { boxSizing: 'border-box' };
}

/** Grow values upstream accepts. Anything else falls back to `true`. */
const VALID_GROW_VALUES = [
  true,
  false,
  0,
  1,
  2,
  3,
  4,
  5,
  6,
  7,
  8,
  9,
  10
] as const;

export type EuiFlexItemGrow = (typeof VALID_GROW_VALUES)[number];

export interface EuiFlexItemSignature {
  Element: Element;
  Args: {
    /**
     * How the item grows: `true` (default) takes an equal share of the
     * space, `false` (or `0`) only takes its content's width, `1`–`10` take
     * that many shares.
     */
    grow?: EuiFlexItemGrow;
    /** Tag of the item. Defaults to `'div'`. */
    tagName?: string;
    /**
     * Extra styles composed last into this component's class (like upstream's
     * `css` prop). Prefer this to an extra class when styling it from a parent.
     */
    css?: EuiCss;
  };
  Blocks: {
    /** The content. */
    default: [];
  };
}

export default class EuiFlexItem extends Component<EuiFlexItemSignature> {
  get tagName() {
    return this.args.tagName ?? 'div';
  }

  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    const styles = euiFlexItemStyles;
    const raw = this.args.grow;
    // Same normalization as upstream: unknown values behave like `true`.
    const grow =
      raw === undefined ||
      raw === null ||
      !(VALID_GROW_VALUES as readonly unknown[]).includes(raw)
        ? true
        : raw;
    return euiClass(
      context,
      euiFlexRootReset(this.tagName),
      styles.euiFlexItem,
      grow ? styles.grow : styles.growZero,
      grow
        ? styles.growSizes[
            (typeof grow === 'number'
              ? String(grow)
              : '1') as keyof typeof styles.growSizes
          ]
        : undefined,
      this.args.css
    );
  }

  <template>
    {{#if (eq this.tagName "div")}}
      <div class="euiFlexItem {{this.classes}}" ...attributes>
        {{yield}}
      </div>
    {{else if (eq this.tagName "span")}}
      <span class="euiFlexItem {{this.classes}}" ...attributes>
        {{yield}}
      </span>
    {{else}}
      {{#let (element this.tagName) as |TagElement|}}
        <TagElement class="euiFlexItem {{this.classes}}" ...attributes>
          {{yield}}
        </TagElement>
      {{/let}}
    {{/if}}
  </template>
}
