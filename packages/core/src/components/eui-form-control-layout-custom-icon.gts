import { on } from '@ember/modifier';

import EuiIcon from './eui-icon.gts';

import type { CommonArgs } from './common.ts';
import type { EuiIconSignature } from './eui-icon.gts';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export type EuiFormControlLayoutCustomIconArgs = CommonArgs & {
  /** Makes the icon a button calling this function. */
  onClick?: (event: MouseEvent) => void;
  /** The icon; anything `EuiIcon`'s `@type` accepts. */
  type: EuiIconSignature['Args']['type'];
  /** Size of the icon. */
  size?: EuiIconSignature['Args']['size'];
  /** @deprecated Has no effect. */
  iconRef?: string | ((el: HTMLButtonElement | HTMLSpanElement | null) => void);
};

/** @private An icon inside EuiFormControlLayout. */
export interface EuiFormControlLayoutCustomIconSignature {
  Element: HTMLButtonElement | HTMLSpanElement;
  Args: EuiFormControlLayoutCustomIconArgs;
}

const EuiFormControlLayoutCustomIcon: TemplateOnlyComponent<EuiFormControlLayoutCustomIconSignature> =
  <template>
    {{#if @onClick}}
      <button
        type="button"
        class="euiFormControlLayoutCustomIcon euiFormControlLayoutCustomIcon--clickable"
        ...attributes
        {{on "click" @onClick}}
      >
        <EuiIcon
          @iconClasses="euiFormControlLayoutCustomIcon__icon"
          @type={{@type}}
          @size={{@size}}
          aria-hidden="true"
        />
      </button>
    {{else}}
      <span class="euiFormControlLayoutCustomIcon" ...attributes>
        <EuiIcon
          @iconClasses="euiFormControlLayoutCustomIcon__icon"
          @type={{@type}}
          @size={{@size}}
          aria-hidden="true"
        />
      </span>
    {{/if}}
  </template>;

export default EuiFormControlLayoutCustomIcon;
