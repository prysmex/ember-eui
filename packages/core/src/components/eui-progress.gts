import { and,eq, or } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';

import type {
  colorToClassMap,
  positionsToClassMap,
  sizeToClassMapping} from '../utils/css-mappings/eui-progress.ts';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** A progress bar: a value out of `@max`, or an indeterminate loading bar. */
export interface EuiProgressSignature {
  Element: HTMLDivElement | HTMLProgressElement;
  Args: {
    /**
     * Maximum value. With it the bar shows `@value`; without it the bar is
     * an indeterminate loading animation.
     */
    max?: number;
    /** Current value, from 0 to `@max`. */
    value?: number;
    /** Thickness: `'xs'`, `'s'`, `'m'` or `'l'`. Defaults to `'m'`. */
    size?: keyof typeof sizeToClassMapping;
    /**
     * `'static'` renders in place; `'fixed'` / `'absolute'` pin it to the
     * top of the window / its positioned parent. Defaults to `'static'`.
     */
    position?: keyof typeof positionsToClassMap;
    /**
     * `'primary'`, `'success'`, `'warning'`, `'danger'`, `'subdued'`,
     * `'accent'` or `'vis0'`–`'vis9'`. Defaults to `'success'`.
     */
    color?: keyof typeof colorToClassMap;
    /** Classes for the value text. */
    labelClasses?: string;
    /**
     * `true` shows `@value` above the bar; for other text use the
     * `<:valueText>` block.
     */
    valueText?: string | boolean;
    /** @deprecated Has no effect, use the `<:label>` block. */
    label?: string;
  };
  Blocks: {
    /** Label above the bar (with `@max`). */
    label?: [];
    /** Value text above the bar, e.g. "70%" (with `@max`). */
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
      aria-hidden={{if
        (and (has-block "label") (or @valueText (has-block "valueText")))
        "true"
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
