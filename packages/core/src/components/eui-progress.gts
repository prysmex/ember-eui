import { and,eq, or } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';

import type {
  colorToClassMap,
  positionsToClassMap,
  sizeToClassMapping} from '../utils/css-mappings/eui-progress.ts';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiProgressSignature {
  Element: HTMLDivElement | HTMLProgressElement;
  Args: {
    max?: number;
    value?: number;
    size?: keyof typeof sizeToClassMapping;
    position?: keyof typeof positionsToClassMap;
    color?: keyof typeof colorToClassMap;
    labelClasses?: string;
    valueText?: string | boolean;
    label?: string;
  };
  Blocks: {
    label?: [];
    valueText?: [];
  };
}

const EuiProgress: TemplateOnlyComponent<EuiProgressSignature> = <template>
  {{#if @max}}
    {{#if (or (has-block "label") (has-block "valueText") @valueText)}}
      <div
        class={{classNames
          (if (eq @size "l") "euiProgress__data--l")
          componentName="EuiProgressData"
          color=(argOrDefault @color "success")
        }}
      >
        {{#if (has-block "label")}}
          <span class="euiProgress__label">
            {{yield to="label"}}
          </span>
        {{/if}}
        {{#if (or (has-block "valueText") @valueText)}}
          <span class="euiProgress__valueText {{@labelClasses}}">
            {{#if (eq @valueText true)}}
              {{@value}}
            {{else}}
              {{yield to="valueText"}}
            {{/if}}
          </span>
        {{/if}}
      </div>
    {{/if}}
    <progress
      class={{classNames
        "euiProgress--native"
        componentName="EuiProgress"
        size=(argOrDefault @size "m")
        position=(argOrDefault @position "static")
        color=(argOrDefault @color "success")
      }}
      max={{@max}}
      value={{@value}}
      aria-hidden={{and
        (has-block "label")
        (or @valueText (has-block "valueText"))
      }}
      ...attributes
    ></progress>
  {{else}}
    <div
      class={{classNames
        "euiProgress--indeterminate"
        componentName="EuiProgress"
        size=(argOrDefault @size "m")
        position=(argOrDefault @position "static")
        color=(argOrDefault @color "success")
      }}
      ...attributes
    ></div>
  {{/if}}
</template>;

export default EuiProgress;
