import Component from '@glimmer/component';
import { inject as service } from '@ember/service';

import type EuiI18n from '../services/eui-i18n';

/**
 * Formats a number for the reader, e.g. `1234567` as "1,234,567", with
 * the `euiI18n` service's `formatNumber` (English by default; set it to
 * use your app's locale).
 */
export interface EuiI18nNumberSignature {
  Args: {
    /** The number to format. */
    value?: number;
    /** Several numbers to format; yielded as an array. */
    values?: number[];
  };
  Blocks: {
    /** Renders the formatted text yourself: yields it (or an array for `@values`). */
    default: [string | string[]];
  };
}

export default class EuiI18nNumber extends Component<EuiI18nNumberSignature> {
  @service declare euiI18n: EuiI18n;

  get formatted(): string | string[] {
    const format = (value: number) => this.euiI18n.formatNumber(value);

    return this.args.values ? this.args.values.map(format) : format(this.args.value ?? 0);
  }

  get text(): string {
    const formatted = this.formatted;

    return Array.isArray(formatted) ? formatted.join(', ') : formatted;
  }

  <template>
    {{~#if (has-block)~}}
      {{yield this.formatted}}
    {{~else~}}
      {{this.text}}
    {{~/if~}}
  </template>
}
