import classNames from '../helpers/class-names';
import argOrDefault from '../helpers/arg-or-default';
import { textAlignMapping, colorMapping } from '../utils/css-mappings/eui-stat';
import EuiStatTitle from './eui-stat/title.gts';
import type { EuiStatTitleSignature } from './eui-stat/title.gts';
import EuiStatDescription from './eui-stat/description.gts';
import type { EuiStatDescriptionSignature } from './eui-stat/description.gts';
import { helper } from '@ember/component/helper';
import type { TemplateOnlyComponent } from '@ember/component/template-only';
import screenReaderOnly from '../modifiers/screen-reader-only';

export interface EuiStatSignature {
  Element: HTMLDivElement;
  Args: {
    textAlign?: keyof typeof textAlignMapping;
    title: string;
    description: string;
    titleColor?: keyof typeof colorMapping;
    titleSize: EuiStatTitleSignature['Args']['titleSize'];
    isLoading: boolean;
    reverse: boolean;
    screenReader: boolean;
    titleElement: string;
    descriptionElement?: EuiStatDescriptionSignature['Args']['descriptionElement'];
  };
  Blocks: {
    title: [];
    description: [];
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
