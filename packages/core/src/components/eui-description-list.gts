import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import EuiDescriptionListDescription from './eui-description-list-description.gts';
import EuiDescriptionListTitle from './eui-description-list-title.gts';

import type {
  alignMapping,
  textStyleMapping,
  typeMapping} from '../utils/css-mappings/eui-description-list.ts';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiDescriptionListSignature {
  Element: HTMLElement;
  Args: {
    /** Smaller text. */
    compressed?: boolean;
    /**
     * `'row'` stacks each title above its description, `'column'` puts them
     * side by side, `'responsiveColumn'` is a column that stacks on small
     * screens, `'inline'` flows them as compact inline text.
     * Defaults to `'row'`.
     */
    type?: keyof typeof typeMapping;
    /**
     * `'reverse'` styles the descriptions as the prominent text and the
     * titles as the smaller labels. Defaults to `'normal'`.
     */
    textStyle?: keyof typeof textStyleMapping;
    /** `'left'` or `'center'`. Defaults to `'left'`. */
    align?: keyof typeof alignMapping;
    /**
     * The terms: `[{ title: 'Name', description: 'Jane' }]`. Without it,
     * pass `EuiDescriptionListTitle` / `EuiDescriptionListDescription` in the
     * block.
     */
    listItems?: {
      title: string;
      description: string;
    }[];
    /** Props for each title from `@listItems`: `{ className }`. */
    titleProps?: {
      className?: string;
    };
    /** Props for each description from `@listItems`: `{ className }`. */
    descriptionProps?: {
      className?: string;
    };
  };
  Blocks: {
    /**
     * Pairs of `EuiDescriptionListTitle` and `EuiDescriptionListDescription`
     * (ignored when `@listItems` is set).
     */
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
