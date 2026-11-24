/**
 * Display text and locale (DESIGN 5.3, 5.4). Locale results that depend on
 * the engine's CLDR data are asserted against `Intl` itself; only `en-US`
 * and `en-GB` use literals.
 */
import { module, test } from 'qunit';

import {
  dateOrderOf,
  datePlaceholder,
  firstDayFromLocale,
  firstDayOfWeekOf,
  formatDate,
  formatDateTime,
  formatTime,
  fullDateLabel,
  hour12Of,
  localeDefaults,
  monthNames,
  monthYearLabel,
  resolveLocale,
  weekdayNames
} from '#src/utils/date/format.ts';
import {
  instantString,
  parseDateText,
  parseDateTimeText,
  parseTimeText
} from '#src/utils/date/parse.ts';

import type { DateOrder } from '#src/utils/date/parse.ts';

const ORDERS: DateOrder[] = ['dmy', 'mdy', 'ymd'];

module('Unit | utils | date | format', function () {
  test('dates as shown, in each order', function (assert) {
    assert.strictEqual(formatDate('2026-11-24', 'dmy'), '24/11/2026');
    assert.strictEqual(formatDate('2026-11-24', 'mdy'), '11/24/2026');
    assert.strictEqual(formatDate('2026-11-24', 'ymd'), '2026-11-24');
    assert.strictEqual(formatDate('0001-01-05', 'dmy'), '05/01/0001');
  });

  test('times as shown: 24-hour, 12-hour, seconds', function (assert) {
    const t = (hour: number, minute: number, second = 0) => ({
      hour,
      minute,
      second
    });
    assert.strictEqual(formatTime(t(9, 5)), '09:05');
    assert.strictEqual(
      formatTime(t(15, 30, 45), { seconds: true }),
      '15:30:45'
    );
    assert.strictEqual(formatTime(t(15, 30), { hour12: true }), '3:30 pm');
    assert.strictEqual(formatTime(t(0, 15), { hour12: true }), '12:15 am');
    assert.strictEqual(formatTime(t(12, 0), { hour12: true }), '12:00 pm');
    assert.strictEqual(
      formatTime(t(11, 59, 59), { hour12: true, seconds: true }),
      '11:59:59 am'
    );
  });

  test('instants as shown in a zone', function (assert) {
    const at = Date.UTC(2026, 10, 24, 21, 30);
    assert.strictEqual(
      formatDateTime(at, { order: 'dmy', zone: 'America/Monterrey' }),
      '24/11/2026 15:30',
      'DESIGN 4.4'
    );
    assert.strictEqual(
      formatDateTime(at, { order: 'mdy', zone: 'utc', hour12: true }),
      '11/24/2026 9:30 pm'
    );
    assert.strictEqual(
      formatDateTime(Date.UTC(2026, 10, 1, 6, 30), {
        order: 'ymd',
        zone: 'America/New_York'
      }),
      '2026-11-01 01:30',
      'the second 01:30 shows as 01:30'
    );
    assert.strictEqual(
      formatDateTime(at, { order: 'dmy', zone: 'Mars/Olympus' }),
      '24/11/2026 21:30',
      'unknown zone: UTC, no throw'
    );
  });

  test('display text parses back to the same value', function (assert) {
    const days = [
      '2026-11-24',
      '2028-02-29',
      '0001-01-01',
      '9999-12-31',
      '2026-01-05'
    ];
    for (const order of ORDERS) {
      for (const day of days) {
        assert.strictEqual(
          parseDateText(formatDate(day, order), { order, year: 2026 }),
          day,
          `${order} ${day}`
        );
      }
    }
    for (let minutes = 0; minutes < 24 * 60; minutes += 17) {
      const time = {
        hour: Math.floor(minutes / 60),
        minute: minutes % 60,
        second: 0
      };
      for (const hour12 of [false, true]) {
        assert.deepEqual(
          parseTimeText(formatTime(time, { hour12 })),
          time,
          `${minutes} ${hour12}`
        );
      }
    }
    const zones = [
      'utc',
      'America/New_York',
      'Asia/Kolkata',
      'Australia/Lord_Howe'
    ];
    for (const zone of zones) {
      for (const order of ORDERS) {
        for (const text of [
          '2026-11-24T15:30:00.000Z',
          '2026-03-08T07:30:00.000Z',
          '2026-07-01T00:00:00.000Z'
        ]) {
          const at = Date.parse(text);
          for (const hour12 of [false, true]) {
            const shown = formatDateTime(at, {
              order,
              zone,
              hour12,
              seconds: true
            });
            const back = parseDateTimeText(shown, {
              order,
              year: 2026,
              zone,
              seconds: true
            });
            assert.strictEqual(
              instantString(back!),
              text,
              `${zone} ${order} ${hour12}: "${shown}"`
            );
          }
        }
      }
    }
  });

  test('the placeholder spells the display format', function (assert) {
    assert.strictEqual(datePlaceholder('dmy'), 'DD/MM/YYYY');
    assert.strictEqual(datePlaceholder('mdy'), 'MM/DD/YYYY');
    assert.strictEqual(datePlaceholder('ymd'), 'YYYY-MM-DD');
    assert.strictEqual(
      datePlaceholder('dmy', { day: 'J', month: 'M', year: 'A' }),
      'JJ/MM/AAAA',
      'letters from i18n tokens'
    );
  });

  test('locale defaults: en-US and en-GB (9 #32)', function (assert) {
    assert.deepEqual(localeDefaults('en-US'), {
      locale: 'en-US',
      dateOrder: 'mdy',
      hour12: true,
      firstDayOfWeek: localeHasWeekInfo() ? 0 : 1
    });
    assert.strictEqual(dateOrderOf('en-GB'), 'dmy');
    assert.false(hour12Of('en-GB'));
    assert.strictEqual(dateOrderOf('ja-JP'), 'ymd');
    assert.strictEqual(dateOrderOf('de-DE'), 'dmy');
  });

  test('locale defaults follow Intl for a list of locales (9 #33)', function (assert) {
    for (const locale of [
      'es-MX',
      'es-ES',
      'fr-FR',
      'de-DE',
      'pt-BR',
      'ar-EG',
      'he-IL',
      'zh-CN',
      'ko-KR',
      'hu-HU',
      'en-CA',
      'fa-IR'
    ]) {
      const parts = new Intl.DateTimeFormat(locale, {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        timeZone: 'UTC'
      })
        .formatToParts(Date.UTC(2026, 10, 24))
        .map((part) => part.type)
        .filter((type) => type === 'year' || type === 'month' || type === 'day')
        .join(',');
      const order = dateOrderOf(locale);
      const expected = parts.startsWith('year')
        ? 'ymd'
        : parts.indexOf('month') < parts.indexOf('day')
          ? 'mdy'
          : 'dmy';
      assert.strictEqual(order, expected, `${locale} order (${parts})`);

      const cycle = new Intl.DateTimeFormat(locale, {
        hour: 'numeric'
      }).resolvedOptions().hourCycle;
      assert.strictEqual(
        hour12Of(locale),
        cycle === 'h11' || cycle === 'h12',
        `${locale} ${cycle}`
      );

      const first = firstDayOfWeekOf(locale);
      const info = weekInfoOf(locale);
      assert.strictEqual(
        first,
        info === undefined ? 1 : info % 7,
        `${locale} first day ${info}`
      );
    }
  });

  test('the first day of the week without getWeekInfo is Monday (9 #34)', function (assert) {
    assert.strictEqual(firstDayFromLocale({}), 1, 'neither accessor');
    assert.strictEqual(
      firstDayFromLocale({ getWeekInfo: () => ({ firstDay: 7 }) }),
      0,
      'Sunday'
    );
    assert.strictEqual(
      firstDayFromLocale({ getWeekInfo: () => ({ firstDay: 6 }) }),
      6,
      'Saturday'
    );
    assert.strictEqual(
      firstDayFromLocale({ weekInfo: { firstDay: 1 } }),
      1,
      'the older accessor'
    );
    assert.strictEqual(firstDayFromLocale({ weekInfo: { firstDay: 7 } }), 0);
    assert.strictEqual(
      firstDayFromLocale({
        getWeekInfo: () => {
          throw new Error('no');
        }
      }),
      1,
      'a throwing engine'
    );
    assert.strictEqual(
      firstDayFromLocale({ getWeekInfo: () => ({}) }),
      1,
      'no firstDay'
    );
    assert.strictEqual(
      firstDayFromLocale({ weekInfo: { firstDay: 9 } }),
      1,
      'out of range'
    );
  });

  test('the locale: argument, then the document, then the browser', function (assert) {
    const html = document.documentElement;
    const lang = html.getAttribute('lang');
    try {
      html.setAttribute('lang', 'es-MX');
      assert.strictEqual(resolveLocale('fr-FR'), 'fr-FR', 'the argument');
      assert.strictEqual(resolveLocale(undefined), 'es-MX', 'the document');
      assert.strictEqual(
        resolveLocale('not a tag!'),
        'es-MX',
        'a bad tag is skipped'
      );
      assert.strictEqual(resolveLocale('EN-us'), 'en-US', 'canonical');
      html.removeAttribute('lang');
      assert.strictEqual(
        resolveLocale(null),
        Intl.getCanonicalLocales(navigator.language)[0],
        'the browser'
      );
    } finally {
      if (lang === null) html.removeAttribute('lang');
      else html.setAttribute('lang', lang);
    }
  });

  test('names come from Intl, in UTC on UTC dates', function (assert) {
    const months = monthNames('en-US');
    assert.strictEqual(months.length, 12);
    assert.strictEqual(months[0], 'January');
    assert.strictEqual(months[10], 'November');
    assert.strictEqual(monthNames('en-US', 'short')[1], 'Feb');
    assert.deepEqual(weekdayNames('en-US', 'short'), [
      'Sun',
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat'
    ]);
    assert.deepEqual(weekdayNames('en-US', 'short', 1), [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun'
    ]);
    assert.strictEqual(weekdayNames('en-US', 'long', 6)[0], 'Saturday');
    assert.strictEqual(
      fullDateLabel('2026-11-24', 'en-US'),
      'Tuesday, November 24, 2026'
    );
    assert.true(
      fullDateLabel('2026-11-24', 'en-GB').includes('24 November 2026'),
      'en-GB, day first'
    );
    assert.strictEqual(
      fullDateLabel('2026-01-01', 'en-US'),
      'Thursday, January 1, 2026',
      'not 31 December in a zone west of UTC'
    );
    assert.strictEqual(monthYearLabel(2026, 11, 'en-US'), 'November 2026');
    assert.strictEqual(
      monthNames('es-MX')[10],
      new Intl.DateTimeFormat('es-MX', {
        month: 'long',
        timeZone: 'UTC'
      }).format(Date.UTC(2026, 10, 15))
    );
  });
});

function weekInfoOf(locale: string): number | undefined {
  const loc = new Intl.Locale(locale) as Intl.Locale & {
    getWeekInfo?: () => { firstDay: number };
    weekInfo?: { firstDay: number };
  };
  return typeof loc.getWeekInfo === 'function'
    ? loc.getWeekInfo().firstDay
    : loc.weekInfo?.firstDay;
}

function localeHasWeekInfo(): boolean {
  return weekInfoOf('en-US') !== undefined;
}
