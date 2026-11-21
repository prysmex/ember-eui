import { module, test } from 'qunit';
import { currentURL, visit } from '@ember/test-helpers';

import { setupApplicationTest } from 'site/tests/helpers';

import type DocfyService from '@docfy/ember/services/docfy';

const SHEET = '/docs/sheet/docs/sheet/';

type Heading = { id: string; headings?: Heading[] };

const demoHeadings = (headings: Heading[]): Heading[] =>
  headings.flatMap((heading) => [
    ...(heading.id.startsWith('docfy-demo-') ? [heading] : []),
    ...demoHeadings(heading.headings ?? []),
  ]);

module('Acceptance | sheet docs', function (hooks) {
  setupApplicationTest(hooks);

  test('every sheet page renders each of its demos with its sheet', async function (assert) {
    const docfy = this.owner.lookup('service:docfy') as DocfyService;
    const pages = docfy.flat.filter((page) => page.url.startsWith(SHEET));

    assert.timeout(300_000);
    assert.ok(pages.length > 40, `the sheet has its pages (${pages.length})`);

    for (const page of pages) {
      // each demo has a heading (under "Examples", or where the page puts it)
      const demos = demoHeadings(page.headings);

      await visit(page.url);

      assert.strictEqual(currentURL(), page.url, `${page.url} renders`);
      const rendered = [
        ...document.querySelectorAll('.docfy-demo .docfy-demo__example'),
      ];

      assert.strictEqual(
        rendered.length,
        demos.length,
        `${page.url}: its ${demos.length} demos`,
      );
      rendered.forEach((example, index) => {
        assert.ok(
          example.querySelector('.euiSheet [role="grid"], .euiSheetImport'),
          `${page.url}: demo ${index + 1} shows its sheet`,
        );
      });
      assert.notOk(
        document.querySelector('.pageBody')?.textContent?.includes('[[demo'),
        `${page.url}: no demo marker as text`,
      );
    }
  });
});
