import Component from '@glimmer/component';
import { service } from '@ember/service';

import { prettyDuration } from '../components/eui-super-date-picker/utils/pretty-duration.ts';

import type EuiI18n from '../services/eui-i18n';
import type { DurationRange, ShortDate } from './eui-super-date-picker/types/global';

/**
 * Renders a start and end date as a human friendly text (upstream's
 * `PrettyDuration`): a matching quick range's label ("Today"), a relative
 * duration ("Last 15 minutes", "Next 2 days rounded to the day"), otherwise
 * "{start} to {end}". Renders text only, no element.
 */
export interface EuiPrettyDurationSignature {
  Args: {
    /** The start: a timestamp (`2018-01-17T18:57:57.149Z`) or a relative time (`now-15m`). */
    timeFrom: ShortDate;
    /** The end, in the same formats as `@timeFrom`. */
    timeTo: ShortDate;
    /**
     * Quick ranges whose label is used when they match the start and end.
     * Defaults to the commonly used ranges of EuiSuperDatePicker.
     */
    quickRanges?: DurationRange[];
    /** moment format of absolute dates. Defaults to `'MMM D, YYYY @ HH:mm:ss.SSS'`. */
    dateFormat?: string;
  };
}

export default class EuiPrettyDuration extends Component<EuiPrettyDurationSignature> {
  @service declare euiI18n: EuiI18n;

  get text() {
    const { timeFrom, timeTo, quickRanges, dateFormat } = this.args;

    return prettyDuration(this.euiI18n, {
      timeFrom,
      timeTo,
      quickRanges,
      dateFormat: dateFormat ?? 'MMM D, YYYY @ HH:mm:ss.SSS'
    });
  }

  <template>{{this.text}}</template>
}
