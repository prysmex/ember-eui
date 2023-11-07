import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';
import EuiDescriptionListTitle from './eui-description-list-title.gts';
import EuiDescriptionListDescription from './eui-description-list-description.gts';
import {
  typeMapping,
  alignMapping,
  textStyleMapping
} from '../utils/css-mappings/eui-description-list';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiDescriptionListSignature {
  Element: HTMLElement;
  Args: {
    compressed?: boolean;
    type?: keyof typeof typeMapping;
    textStyle?: keyof typeof textStyleMapping;
    align?: keyof typeof alignMapping;
    listItems?: {
      title: string;
      description: string;
    }[];
    titleProps?: {
      className?: string;
    };
    descriptionProps?: {
      className?: string;
    };
  };
  Blocks: {
    default: [];
  };
}

const EuiDescriptionList: TemplateOnlyComponent<EuiDescriptionListSignature> =
  <template>
    <dl
      class={{classNames
        (if (argOrDefault @compressed false) "euiDescriptionList--compressed")
        type=(argOrDefault @type "row")
        textStyle=(argOrDefault @textStyle "normal")
        align=(argOrDefault @align "left")
        componentName="EuiDescriptionList"
      }}
      ...attributes
    >
      {{#if @listItems}}
        {{#each @listItems as |item|}}
          <EuiDescriptionListTitle class={{@titleProps.className}}>
            {{item.title}}
          </EuiDescriptionListTitle>
          <EuiDescriptionListDescription class={{@descriptionProps.className}}>
            {{item.description}}
          </EuiDescriptionListDescription>
        {{/each}}
      {{else}}
        {{yield}}
      {{/if}}
    </dl>
  </template>;

export default EuiDescriptionList;
