import { on } from '@ember/modifier';

import EuiIcon from './eui-icon.gts';

import type { CommonArgs, ExclusiveUnion } from './common';
import type { EuiIconArgs, IconType } from './eui-icon.gts';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export type EuiFormControlLayoutCustomIconArgs = CommonArgs &
  ExclusiveUnion<Omit<HTMLButtonElement, 'type'>, HTMLSpanElement> & {
    onClick?: (event: MouseEvent) => void;
    type: IconType;
    size?: EuiIconArgs['size'];
    iconRef?:
      | string
      | ((el: HTMLButtonElement | HTMLSpanElement | null) => void);
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
