import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiStatStyles } from '../utils/eui/styles.generated.ts';
import EuiStatDescription from './eui-stat/description.gts';
import EuiStatTitle from './eui-stat/title.gts';

import type { EuiStatDescriptionSignature } from './eui-stat/description';
import type { EuiStatTitleColor, EuiStatTitleSignature } from './eui-stat/title';

const BOX_SIZING = { boxSizing: 'border-box' } as const;

export type EuiStatTextAlign = 'left' | 'center' | 'right';

/** A key number with a description, e.g. on a dashboard. */
export interface EuiStatSignature {
  Element: HTMLDivElement;
  Args: {
    /**
     * `'left'`, `'center'` or `'right'` (logical, so left/right flip in RTL).
     * Defaults to `'left'`.
     */
    textAlign?: EuiStatTextAlign;
    /** The number or value, e.g. `1234` or "1,234". Use the `<:title>` block for markup. */
    title?: string | number;
    /** What it measures, e.g. "Total users". Use the `<:description>` block for markup. */
    description?: string;
    /**
     * Color of the title: `'default'`, `'subdued'`, `'primary'`,
     * `'success'`, `'warning'`, `'danger'`, `'accent'`, or any CSS color.
     * Defaults to `'default'`.
     */
    titleColor?: EuiStatTitleColor | string;
    /** Size of the title, any `EuiTitle` size. Defaults to `'l'`. */
    titleSize?: EuiStatTitleSignature['Args']['titleSize'];
    /**
     * Shows "--" instead of the title, pulses it (unless reduced motion is
     * requested) and labels it "Statistic is loading" (i18n token
     * `euiStat.loadingText`).
     */
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

/** Native Ember stat on the upstream EUI 123 / Borealis factories. */
export default class EuiStat extends Component<EuiStatSignature> {
  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiStatStyles);
    return euiClass(
      context,
      BOX_SIZING,
      styles.euiStat,
      styles[this.args.textAlign ?? 'left']
    );
  }

  <template>
    <div class="euiStat {{this.classes}}" ...attributes>
      {{#unless @reverse}}
        <EuiStatDescription @descriptionElement={{@descriptionElement}}>
          {{#if (has-block "description")}}
            {{yield to="description"}}
          {{else}}
            {{@description}}
          {{/if}}
        </EuiStatDescription>
      {{/unless}}
      <EuiStatTitle
        @titleElement={{@titleElement}}
        @titleSize={{@titleSize}}
        @titleColor={{@titleColor}}
        @isLoading={{@isLoading}}
      >
        {{#if @isLoading}}
          --
        {{else if (has-block "title")}}
          {{yield to="title"}}
        {{else}}
          {{@title}}
        {{/if}}
      </EuiStatTitle>
      {{#if @reverse}}
        <EuiStatDescription @descriptionElement={{@descriptionElement}}>
          {{#if (has-block "description")}}
            {{yield to="description"}}
          {{else}}
            {{@description}}
          {{/if}}
        </EuiStatDescription>
      {{/if}}
      {{yield}}
    </div>
  </template>
}
