/**
 * `url`'s host rule (READINESS.md item 5, UH1-UH3): the host as written
 * must be `localhost`, a bracketed IPv6 address, a dotted quad, or a name
 * whose last label has a letter. The URL parser alone reads `19/11/2026`
 * and `12` as IPv4 hosts (0.0.0.19, 0.0.0.12). UH4: the import guess
 * relies on the type's rule alone (its own host check is gone).
 */
import { module, test } from 'qunit';

import {
  builtInFieldTypes,
  defaultMessages,
  guessColumn,
  urlFieldType
} from '#src/core/index.ts';

import type { LinkField } from '#src/core/index.ts';

const url: LinkField = { id: 'u', type: 'url' };
const view = { record: undefined, messages: defaultMessages };
const valid = (text: string) =>
  urlFieldType.validate!(text, url, view).length === 0;

module('Unit | url host', function () {
  test('UH1 a date, a number and a dotted number are not URLs', function (assert) {
    for (const text of [
      '19/11/2026',
      '12',
      '0',
      '1.5',
      '1.2.3',
      '0x7f.1',
      '256.1.1.1',
      'https://12',
      'https://19/11/2026',
      'Calle 5',
      'word'
    ]) {
      assert.false(valid(text), `${text}: not a URL`);
      assert.deepEqual(
        urlFieldType.validate!(text, url, view),
        [defaultMessages.notAUrl(text)],
        `${text}: the message`
      );
      assert.strictEqual(urlFieldType.link!(text, url), undefined, 'no link');
    }
  });

  test('UH2 names, addresses, ports, users and paths', function (assert) {
    for (const text of [
      'example.com',
      'example.com/a?b=1',
      'https://x.org',
      'http://www.acme.mx/precios#2026',
      'https://example.com:8080/x',
      'https://ana@example.com/',
      'https://acme.mx./',
      'ñandú.mx',
      'https://ñandú.mx',
      'sub-domain.example.co.uk',
      'https://192.168.0.1/admin',
      '10.0.0.1',
      'http://localhost:4200/docs',
      'https://localhost',
      'http://[::1]:8080/',
      'https://xn--and-6ma2c.mx'
    ]) {
      assert.true(valid(text), `${text}: a URL`);
    }
    assert.strictEqual(
      urlFieldType.link!('10.0.0.1', url),
      'https://10.0.0.1',
      'a dotted quad links'
    );
  });

  test('UH3 a label with a space or an empty label is not a host', function (assert) {
    for (const text of ['https://a..com', 'https://.com', 'https://-a.com']) {
      assert.false(valid(text), `${text}: not a URL`);
    }
    assert.false(valid('ftp://example.com'), 'not a web scheme');
    assert.false(valid('javascript:alert(1)'), 'not a web scheme');
  });

  test('UH4 the import guess: dates and numbers are not URLs, sites are', function (assert) {
    const ctx = { types: builtInFieldTypes, messages: defaultMessages };
    const typesOf = (texts: string[], candidates: string[]) =>
      guessColumn(ctx, texts, candidates).map((guess) => guess.type);
    assert.deepEqual(
      typesOf(['19/11/2026', '20/11/2026'], ['url', 'text']),
      ['text'],
      'dates'
    );
    assert.deepEqual(typesOf(['12', '30', '7'], ['url', 'text']), ['text']);
    assert.deepEqual(typesOf(['1.5', '2.25'], ['url', 'text']), ['text']);
    assert.deepEqual(
      typesOf(
        ['acme.mx', 'https://x.com/a', 'ñandú.mx/precios'],
        ['url', 'text']
      ),
      ['url', 'text']
    );
    assert.deepEqual(
      typesOf(['192.168.0.1', '10.0.0.7'], ['url', 'text']),
      ['url', 'text'],
      'dotted quads are addresses'
    );
  });
});
