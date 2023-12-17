import { on } from '@ember/modifier';

import EuiIcon from './eui-icon.gts';

import type { CommonArgs } from './common';
import type { EuiIconSignature } from './eui-icon';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export type EuiFormControlLayoutCustomIconArgs = CommonArgs & {
  onClick?: (event: MouseEvent) => void;
  type: EuiIconSignature['Args']['type'];
  size?: EuiIconSignature['Args']['size'];
  iconRef?: string | ((el: HTMLButtonElement | HTMLSpanElement | null) => void);
};

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
