// Compares two shots.js directories: chips.json exactly, and each PNG pixel
// by pixel (decoded in Chromium).
//   node compare.js <dir-a> <dir-b> [--common]
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const [a, b] = process.argv.slice(2);

(async () => {
  const ja = JSON.parse(fs.readFileSync(path.join(a, 'chips.json'), 'utf8'));
  const jb = JSON.parse(fs.readFileSync(path.join(b, 'chips.json'), 'utf8'));
  // `--common`: the cells (shots-d08.js) matched by row and column, only
  // those in both (a build that renders fewer columns has fewer)
  const common = process.argv.includes('--common');
  const keyOf = (line) =>
    (line.match(/data-gridcell-visible-row-index=\S*/)?.[0] ?? '') +
    ' ' +
    (line.match(/data-gridcell-column-index=\S*/)?.[0] ?? '');
  for (const k of Object.keys(ja)) {
    if (common) {
      const ma = new Map(ja[k].map((line) => [keyOf(line), line]));
      const mb = new Map(jb[k].map((line) => [keyOf(line), line]));
      const both = [...ma.keys()].filter((key) => mb.has(key));
      const differ = both.filter((key) => ma.get(key) !== mb.get(key));
      console.log(
        `cells ${k}: ${ma.size} vs ${mb.size}, ${both.length} in both, ${differ.length} of them differ`
      );
      for (const key of differ.slice(0, 3)) {
        console.log('  a', ma.get(key));
        console.log('  b', mb.get(key));
      }
      continue;
    }
    const same = JSON.stringify(ja[k]) === JSON.stringify(jb[k]);
    console.log(
      `chips ${k}: ${ja[k].length} vs ${jb[k]?.length}, ${same ? 'identical' : 'DIFFERENT'}`
    );
    if (!same) {
      for (let i = 0; i < Math.max(ja[k].length, jb[k]?.length ?? 0); i++) {
        if (JSON.stringify(ja[k][i]) !== JSON.stringify(jb[k]?.[i])) {
          console.log('  a', JSON.stringify(ja[k][i]));
          console.log('  b', JSON.stringify(jb[k]?.[i]));
          break;
        }
      }
    }
  }
  const browser = await chromium.launch();
  const page = await browser.newPage();
  for (const f of fs.readdirSync(a).filter((f) => f.endsWith('.png'))) {
    if (!fs.existsSync(path.join(b, f))) {
      console.log(`${f}: missing in ${b}`);
      continue;
    }
    const da =
      'data:image/png;base64,' +
      fs.readFileSync(path.join(a, f)).toString('base64');
    const db =
      'data:image/png;base64,' +
      fs.readFileSync(path.join(b, f)).toString('base64');
    const r = await page.evaluate(
      async ([da, db]) => {
        const load = (src) =>
          new Promise((ok) => {
            const i = new Image();
            i.onload = () => ok(i);
            i.src = src;
          });
        const [ia, ib] = await Promise.all([load(da), load(db)]);
        if (ia.width !== ib.width || ia.height !== ib.height)
          return {
            size: `${ia.width}x${ia.height} vs ${ib.width}x${ib.height}`
          };
        const px = (img) => {
          const c = document.createElement('canvas');
          c.width = img.width;
          c.height = img.height;
          const x = c.getContext('2d');
          x.drawImage(img, 0, 0);
          return x.getImageData(0, 0, img.width, img.height).data;
        };
        const pa = px(ia),
          pb = px(ib);
        let diff = 0;
        for (let i = 0; i < pa.length; i += 4)
          if (
            pa[i] !== pb[i] ||
            pa[i + 1] !== pb[i + 1] ||
            pa[i + 2] !== pb[i + 2] ||
            pa[i + 3] !== pb[i + 3]
          )
            diff++;
        return { size: `${ia.width}x${ia.height}`, diff };
      },
      [da, db]
    );
    console.log(
      `${f}: ${r.size}, ${r.diff === undefined ? 'SIZE DIFFERS' : r.diff === 0 ? 'pixel-identical' : r.diff + ' pixels differ'}`
    );
  }
  await browser.close();
})();
