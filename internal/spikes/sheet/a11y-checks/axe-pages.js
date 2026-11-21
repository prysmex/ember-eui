// axe-core over every sheet docs page, in each mode.
//   node axe-pages.js [outDir] [modes]   modes: comma list of light,dark,light-hc,dark-hc
//   PAGES: a comma list of page paths to limit the run (e.g. /docs/sheet/docs/sheet/rows)
// Writes `<outDir>/pages-<mode>.json` (every violation node, by page) and
// prints the counts by scope, rule and impact.
const fs = require('fs');
const path = require('path');
const lib = require('./lib.js');

async function main() {
  const outDir = path.resolve(process.argv[2] || 'a11y-out');
  const modes = (process.argv[3] || 'light,dark').split(',');
  const pages = process.env.PAGES
    ? process.env.PAGES.split(',')
    : lib.sheetPages();
  fs.mkdirSync(outDir, { recursive: true });
  const { browser, context } = await lib.launch();
  for (const mode of modes) {
    const perPage = {};
    const total = {};
    for (const url of pages) {
      const { page, errors } = await lib.openPage(context, url, mode);
      const violations = await lib.runAxe(page);
      const contrast = await lib.runContrast(page);
      contrast.axeIncomplete = await page.evaluate(() => window.__axeIncompleteContrast);
      const counts = lib.tally(violations);
      perPage[url] = { counts, violations, contrast, errors };
      lib.addTally(total, counts);
      for (const [scope, n] of Object.entries(contrast.axeIncomplete ?? {})) {
        total.axeIncompleteContrast ??= {};
        total.axeIncompleteContrast[scope] = (total.axeIncompleteContrast[scope] ?? 0) + n;
      }
      for (const f of contrast.failures) {
        total.contrast ??= {};
        total.contrast[`${f.tag}.${f.cls} ${f.fg} on ${f.bg} ${f.ratio}`] =
          (total.contrast[`${f.tag}.${f.cls} ${f.fg} on ${f.bg} ${f.ratio}`] ?? 0) + f.count;
      }
      const sheet = Object.values(counts.sheet ?? {}).reduce((a, b) => a + b, 0);
      const demo = Object.values(counts.demo ?? {}).reduce((a, b) => a + b, 0);
      const chrome = Object.values(counts.chrome ?? {}).reduce((a, b) => a + b, 0);
      console.log(
        `${mode} ${url}: sheet ${sheet}, demo ${demo}, chrome ${chrome}; contrast ${contrast.failures.length} of ${contrast.rated}${errors.length ? `, ${errors.length} errors` : ''}`
      );
      await page.close();
    }
    fs.writeFileSync(
      path.join(outDir, `pages-${mode}.json`),
      JSON.stringify({ total, perPage }, null, 1)
    );
    console.log(`TOTAL ${mode}`, JSON.stringify(total, null, 1));
  }
  await browser.close();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
