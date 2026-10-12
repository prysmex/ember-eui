import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { on } from '@ember/modifier';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import {
  buttonReset,
  euiFormControlLayoutCustomIconStyles as styles
} from '../utils/eui/form-controls.ts';
import { euiClass } from '../utils/eui/styles.ts';
import EuiIcon from './eui-icon.gts';

import type { CommonArgs } from './common.ts';
import type { EuiIconSignature } from './eui-icon.gts';

export type EuiFormControlLayoutCustomIconArgs = CommonArgs & {
  /** Makes the icon a button calling this function. */
  onClick?: (event: MouseEvent) => void;
  /** The icon; anything `EuiIcon`'s `@type` accepts. */
  type: EuiIconSignature['Args']['type'];
  /** Size of the icon. */
  size?: EuiIconSignature['Args']['size'];
  /** Color of the icon, anything `EuiIcon`'s `@color` accepts. */
  color?: EuiIconSignature['Args']['color'];
  /** Disables the `@onClick` button. */
  disabled?: boolean;
  /** @deprecated Has no effect. */
  iconRef?: string | ((el: HTMLButtonElement | HTMLSpanElement | null) => void);
};

/** @private An icon inside EuiFormControlLayout. */
export interface EuiFormControlLayoutCustomIconSignature {
  Element: HTMLButtonElement | HTMLSpanElement;
  Args: EuiFormControlLayoutCustomIconArgs;
}

export default class EuiFormControlLayoutCustomIcon extends Component<EuiFormControlLayoutCustomIconSignature> {
  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    const clickable = Boolean(this.args.onClick);
    return euiClass(
      context,
      clickable && buttonReset,
      styles.euiFormControlLayoutCustomIcon,
      clickable ? styles.clickable : styles.unclickable
    );
  }

  <template>
    {{#if @onClick}}
      <button
        type="button"
        class="euiFormControlLayoutCustomIcon {{this.classes}}"
        disabled={{@disabled}}
        ...attributes
        {{on "click" @onClick}}
      >
        <EuiIcon
          @iconClasses="euiFormControlLayoutCustomIcon__icon"
          @type={{@type}}
          @size={{@size}}
          @color={{@color}}
          aria-hidden="true"
        />
      </button>
    {{else}}
      <span
        class="euiFormControlLayoutCustomIcon {{this.classes}}"
        ...attributes
      >
        <EuiIcon
          @iconClasses="euiFormControlLayoutCustomIcon__icon"
          @type={{@type}}
          @size={{@size}}
          @color={{@color}}
          aria-hidden="true"
        />
      </span>
    {{/if}}
  </template>
}
