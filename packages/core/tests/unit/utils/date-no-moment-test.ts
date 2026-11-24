/**
 * `EuiDatePicker` must not pull in moment (DESIGN 4.6, 8.5): neither
 * `utils/date/*` nor the picker's modules import it, directly or through
 * `@elastic/datemath`. Modelled on the sheet's `core-boundary-test.ts`: the
 * sources are read as text, so this fails in the test run.
 */
import { module, test } from 'qunit';

const dateUtils = import.meta.glob('../../../src/utils/date/**/*.ts', {
  query: '?raw',
  import: 'default',
  eager: true
}) as Record<string, string>;

// the picker and its private parts, as they are added (batches 2 to 6)
const picker = import.meta.glob(
  [
    '../../../src/components/eui-date-picker*.{ts,gts}',
    '../../../src/components/eui-date-picker/**/*.{ts,gts}',
    '../../../src/-private/native-date-input.ts',
    '../../../src/-private/eui-date-picker-range-context.ts'
  ],
  { query: '?raw', import: 'default', eager: true }
) as Record<string, string>;

const FORBIDDEN =
  /(?:from\s*|import\s*\(\s*|require\s*\(\s*|import\s+)['"](?:moment(?:-timezone)?|@elastic\/datemath)(?:\/[^'"]*)?['"]/;

module('Unit | utils | date | boundary', function () {
  test('utils/date/* does not import moment', function (assert) {
    const files = Object.keys(dateUtils);
    assert.true(files.length >= 6, `${files.length} utils/date files read`);
    for (const [file, source] of Object.entries(dateUtils)) {
      assert.false(FORBIDDEN.test(source), file);
    }
  });

  test('the picker modules do not import moment', function (assert) {
    const files = Object.keys(picker);
    assert.true(
      files.some((file) => file.endsWith('/eui-date-picker-range.gts')),
      `${files.length} picker files read, the range among them`
    );
    for (const [file, source] of Object.entries(picker)) {
      assert.false(FORBIDDEN.test(source), file);
    }
  });

  test('the pattern catches every import form', function (assert) {
    for (const line of [
      "import moment from 'moment';",
      'import moment from "moment";',
      "import { Moment } from 'moment';",
      "import type { Moment } from 'moment';",
      "import 'moment';",
      "import tz from 'moment-timezone';",
      "import 'moment/locale/es';",
      "import dateMath from '@elastic/datemath';",
      "const m = await import('moment');",
      "const m = require('moment');",
      "export { default } from 'moment';"
    ]) {
      assert.true(FORBIDDEN.test(line), line);
    }
    for (const line of [
      "import { pad } from './calendar-date.ts';",
      '// moment is not used here',
      "import momentary from 'momentary';"
    ]) {
      assert.false(FORBIDDEN.test(line), line);
    }
  });
});
