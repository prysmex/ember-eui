import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import style from 'ember-style-modifier/modifiers/style';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
import { euiBeaconStyles } from '../utils/eui/styles.generated.ts';

import type { SerializedStyles } from '@emotion/serialize';

export const BEACON_COLORS = [
  'subdued',
  'primary',
  'success',
  'accent',
  'danger',
  'warning'
] as const;

export type EuiBeaconColor = (typeof BEACON_COLORS)[number];

/**
 * A pulsing dot that draws attention to something new, e.g. next to a
 * feature a tour points at.
 */
export interface EuiBeaconSignature {
  Element: HTMLDivElement;
  Args: {
    /** Diameter of the center dot in px. Defaults to `12`. */
    size?: number;
    /**
     * `'subdued'`, `'primary'`, `'success'`, `'accent'`, `'danger'` or
     * `'warning'`. Defaults to `'success'`.
     */
    color?: EuiBeaconColor;
    /**
     * Extra styles composed last into this component's class (like upstream's
     * `css` prop). Prefer this to an extra class when styling it from a parent.
     */
    css?: EuiCss;
  };
}

/** Native Ember beacon using the upstream EUI 123 / Borealis styles. */
export default class EuiBeacon extends Component<EuiBeaconSignature> {
  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(
      context,
      euiBeaconStyles as (
        ...args: Parameters<typeof euiBeaconStyles>
      ) => Record<string, SerializedStyles>
    );
    const color = this.args.color;
    return `euiBeacon ${euiClass(
      context,
      styles['euiBeacon'],
      styles[
        color && (BEACON_COLORS as readonly string[]).includes(color)
          ? color
          : 'success'
      ],
      this.args.css
    )}`;
  }

  /**
   * Upstream sets the size inline, so each size doesn't add a class that
   * stays in the style cache for good.
   */
  get inlineStyle(): Record<string, string> {
    const size = `${this.args.size ?? 12}px`;
    return { blockSize: size, inlineSize: size };
  }

  <template>
    <div class={{this.classes}} ...attributes {{style this.inlineStyle}}></div>
  </template>
}
