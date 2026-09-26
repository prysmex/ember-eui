import { helper } from '@ember/component/helper';

import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import screenReaderOnly from '../modifiers/screen-reader-only.ts';
import { colorMapping } from '../utils/css-mappings/eui-stat.ts';
import EuiStatDescription from './eui-stat/description.gts';
import EuiStatTitle from './eui-stat/title.gts';

import type {textAlignMapping } from '../utils/css-mappings/eui-stat.ts';
import type { EuiStatDescriptionSignature } from './eui-stat/description';
import type { EuiStatTitleSignature } from './eui-stat/title';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** A key number with a description, e.g. on a dashboard. */
export interface EuiStatSignature {
  Element: HTMLDivElement;
  Args: {
    /** `'left'`, `'center'` or `'right'`. Defaults to `'left'`. */
    textAlign?: keyof typeof textAlignMapping;
    /** The number or value, e.g. "1,234". Use the `<:title>` block for markup. */
    title?: string;
    /** What it measures, e.g. "Total users". Use the `<:description>` block for markup. */
    description?: string;
    /**
     * Color of the title: `'default'`, `'subdued'`, `'primary'`,
     * `'success'`, `'danger'`, `'accent'`, or any CSS color.
     * Defaults to `'default'`.
     */
    titleColor?: keyof typeof colorMapping;
    /** Size of the title, any `EuiTitle` size. Defaults to `'l'`. */
    titleSize?: EuiStatTitleSignature['Args']['titleSize'];
    /** Shows "--" instead of the title, e.g. while it loads. */
    isLoading?: boolean;
    /** Puts the title above the description. Defaults to `false`. */
    reverse?: boolean;
    /** @deprecated Has no effect. */
    screenReader?: boolean;
    /** Tag of the title. Defaults to `'p'`. */
    titleElement?: string;
    /** Tag of the description. Defaults to `'p'`. */
    descriptionElement?: EuiStatDescriptionSignature['Args']['descriptionElement'];
  };
  Blocks: {
    /** The title, instead of `@title`. */
    title: [];
    /** The description, instead of `@description`. */
    description: [];
    /** Extra content after the stat, e.g. a trend. */
    default: [];
  };
}

const isColorClass = helper(([input]: [string | undefined]) => {
  if (!input) return false;

  return colorMapping.hasOwnProperty(input);
});

const useScreenReader = helper(
  ([title, description]: [string | undefined, string | undefined]) => {
    return typeof title === 'string' && typeof description === 'string';
  }
);

const EuiStat: TemplateOnlyComponent<EuiStatSignature> = <template>
  {{#let
    (classNames
      textAlign=(argOrDefault @textAlign "left") componentName="EuiStat"
    )
    (classNames
      "euiStat__title"
      (if @isLoading "euiStat__title-isLoading")
      color=(argOrDefault @titleColor "default")
      addBase=false
      componentName="EuiStat"
    )
    (argOrDefault @reverse false)
    (argOrDefault @titleSize "l")
    as |classes titleClasses reverse titleSize|
  }}
    <div class={{classes}} ...attributes>
      {{#if reverse}}
        <EuiStatTitle
          class={{titleClasses}}
          @titleElement={{@titleElement}}
          @titleSize={{titleSize}}
          @isColorClass={{isColorClass @titleColor}}
        >
          {{#if @isLoading}}
            --
          {{else}}
            {{#if (has-block "title")}}
              {{yield to="title"}}
            {{else}}
              {{@title}}
            {{/if}}
          {{/if}}
        </EuiStatTitle>
        <EuiStatDescription @descriptionElement={{@descriptionElement}}>
          {{#if (has-block "description")}}
            {{yield to="description"}}
          {{else}}
            {{@description}}
          {{/if}}
        </EuiStatDescription>
      {{else}}
        <EuiStatDescription @descriptionElement={{@descriptionElement}}>
          {{#if (has-block "description")}}
            {{yield to="description"}}
          {{else}}
            {{@description}}
          {{/if}}
        </EuiStatDescription>
        <EuiStatTitle
          class={{titleClasses}}
          @titleElement={{@titleElement}}
          @titleSize={{titleSize}}
          @isColorClass={{isColorClass @titleColor}}
        >
          {{#if @isLoading}}
            --
          {{else}}
            {{#if (has-block "title")}}
              {{yield to="title"}}
            {{else}}
              {{@title}}
            {{/if}}
          {{/if}}
        </EuiStatTitle>
      {{/if}}
      {{#if (useScreenReader @title @description)}}
        <p {{screenReaderOnly}}>
          {{#if reverse}}
            {{@title}}
            {{@description}}
          {{else}}
            {{@description}}
            {{@title}}
          {{/if}}
        </p>
      {{/if}}
      {{yield}}
    </div>
  {{/let}}
</template>;

export default EuiStat;
