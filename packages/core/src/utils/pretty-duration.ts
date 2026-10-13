/**
 * Upstream's `usePrettyDuration` and `showPrettyDuration` as plain functions,
 * the same ones EuiSuperDatePicker uses:
 *
 * ```js
 * import { prettyDuration } from '@ember-eui/core/utils/pretty-duration';
 * prettyDuration(this.euiI18n, { timeFrom: 'now-15m', timeTo: 'now', dateFormat: 'MMM D, YYYY' });
 * // 'Last 15 minutes'
 * ```
 */
export {
  prettyDuration,
  showPrettyDuration
} from '../components/eui-super-date-picker/utils/pretty-duration.ts';
