// Shared helpers of the accessibility checks: the sheet's docs pages, a
// Playwright page on the production build, axe-core injected from the
// site's node_modules, and the violations sorted by where they are.
//   PORT (default 4211): the `vite preview` port of `site/dist`.
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const ROOT = path.resolve(__dirname, '../../../..');
const DOCS = path.join(ROOT, 'packages/sheet/docs/sheet');
const PORT = process.env.PORT || '4211';
const BASE = `http://127.0.0.1:${PORT}`;
const PREFIX = '/docs/sheet/docs/sheet';
const AXE = require.resolve('axe-core/axe.min.js', {
  paths: [path.join(ROOT, 'site')]
});

/** The 52 pages of the nav (the old URLs' pages of links, `nav: false`, left out). */
function sheetPages() {
  const pages = [];
  const walk = (dir) => {
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      const full = path.join(dir, entry.name);
      if (entry.isDirectory()) walk(full);
      else if (entry.name === 'index.md') {
        const text = fs.readFileSync(full, 'utf8');
        const front = text.match(/^---\n([\s\S]*?)\n---/)?.[1] ?? '';
        if (/^nav:\s*false\s*$/m.test(front)) continue;
        const rel = path.relative(DOCS, dir).split(path.sep).join('/');
        pages.push(rel ? `${PREFIX}/${rel}` : `${PREFIX}/`);
      }
    }
  };
  walk(DOCS);
  return pages.sort();
}

/** Light, dark and the high-contrast variants (the site's `?theme` and `?highContrast`). */
const MODES = {
  light: 'theme=light',
  dark: 'theme=dark',
  'light-hc': 'theme=light&highContrast=true',
  'dark-hc': 'theme=dark&highContrast=true'
};

async function launch({ width = 1400, height = 900 } = {}) {
  const browser = await chromium.launch();
  const context = await browser.newContext({ viewport: { width, height } });
  return { browser, context };
}

/** Opens a page in a mode and waits for every demo's sheet. */
async function openPage(context, url, mode = 'light') {
  const page = await context.newPage();
  const errors = [];
  page.on('pageerror', (e) => errors.push('pageerror: ' + e.message));
  page.on('console', (m) => {
    if (m.type() === 'error') errors.push('console: ' + m.text());
  });
  const sep = url.includes('?') ? '&' : '?';
  await page.goto(`${BASE}${url}${sep}${MODES[mode]}`, { timeout: 120000 });
  await page.waitForFunction(
    () => {
      const demos = [...document.querySelectorAll('.docfy-demo__example')];
      // the page body is rendered, and every demo's sheet (the API
      // reference has no demo)
      return (
        !!document.querySelector('.docfy-demo, .pageBody h1, .pageBody h2') &&
        demos.every((d) =>
          d.querySelector('.euiSheet [role=grid], .euiSheetImport')
        )
      );
    },
    null,
    { timeout: 120000 }
  );
  await page.waitForTimeout(1200);
  return { page, errors };
}

/**
 * Runs axe on the document; each violation's nodes sorted into
 * `sheet` (inside a sheet, its import screen or a part it portals: layers,
 * the expanded record, the shortcut list), `demo` (inside a demo's example
 * but not a sheet: the example's own buttons and text) and `chrome` (the
 * site: header, nav, prose, code snippets). `portalIsSheet`: in a state
 * run, an EUI portal (a date picker's popover, say) belongs to the sheet.
 */
async function runAxe(page, { portalIsSheet = false } = {}) {
  if (!(await page.evaluate(() => !!window.axe))) {
    await page.addScriptTag({ path: AXE });
  }
  return page.evaluate(async (portalIsSheet) => {
    const result = await window.axe.run(document, {
      resultTypes: ['violations', 'incomplete']
    });
    const SHEET =
      '.euiSheet, .euiSheetImport, [data-eui-sheet-layer], .euiSheetRecord, .euiSheetShortcuts';
    const scopeOf = (target) => {
      let el = null;
      try {
        el = document.querySelector(target[target.length - 1]);
      } catch {
        // a selector axe built that the DOM no longer has
      }
      if (!el) return 'unknown';
      if (el.closest(SHEET)) return 'sheet';
      if (portalIsSheet && el.closest('[data-euiportal]')) return 'sheet';
      if (el.closest('.docfy-demo__example')) return 'demo';
      return 'chrome';
    };
    // axe's "cannot tell" contrast results (a cell's pseudo-elements), by scope
    const incomplete = {};
    for (const v of result.incomplete.filter((r) => r.id === 'color-contrast')) {
      for (const n of v.nodes) {
        const scope = scopeOf(n.target);
        incomplete[scope] = (incomplete[scope] ?? 0) + 1;
      }
    }
    window.__axeIncompleteContrast = incomplete;
    return result.violations.map((v) => ({
      id: v.id,
      impact: v.impact,
      tags: v.tags.filter((t) => /^(wcag|best-practice)/.test(t)),
      help: v.help,
      nodes: v.nodes.map((n) => ({
        scope: scopeOf(n.target),
        target: n.target,
        html: n.html.slice(0, 300),
        summary: n.failureSummary?.slice(0, 400)
      }))
    }));
  }, portalIsSheet);
}

/**
 * axe cannot rate most of a sheet's text: the grid's cells have
 * pseudo-elements (rings and borders), so axe reports their contrast as
 * "incomplete". This rates every visible text of the sheets (and their
 * portaled parts) itself: the text colour, with the opacity of the
 * element and its ancestors, against the ancestors' background colours
 * composited up to the first opaque one (pseudo-elements and background
 * images are ignored; disabled controls are exempt, as in WCAG 1.4.3).
 * Returns the failures, one per distinct (class, colours, ratio).
 */
async function runContrast(page) {
  return page.evaluate(() => {
    const ROOTS =
      '.euiSheet, .euiSheetImport, [data-eui-sheet-layer], .euiSheetRecord, .euiSheetShortcuts';
    const parse = (c) => {
      const m = c.match(/rgba?\(([^)]+)\)/);
      if (!m) return [0, 0, 0, 0];
      const p = m[1].split(/[ ,/]+/).filter(Boolean).map(Number);
      return [p[0], p[1], p[2], p.length > 3 ? p[3] : 1];
    };
    const over = (top, bottom) => {
      const a = top[3] + bottom[3] * (1 - top[3]);
      if (!a) return [0, 0, 0, 0];
      return [0, 1, 2]
        .map((i) => (top[i] * top[3] + bottom[i] * bottom[3] * (1 - top[3])) / a)
        .concat(a);
    };
    const lum = ([r, g, b]) => {
      const f = (v) => {
        v /= 255;
        return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
      };
      return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b);
    };
    const background = (el) => {
      const layers = [];
      for (let e = el; e; e = e.parentElement) {
        const bg = parse(getComputedStyle(e).backgroundColor);
        if (bg[3] > 0) layers.push(bg);
        if (bg[3] >= 1) break;
      }
      let color = [255, 255, 255, 1];
      for (let i = layers.length - 1; i >= 0; i--) color = over(layers[i], color);
      return color;
    };
    const opacity = (el) => {
      let o = 1;
      for (let e = el; e; e = e.parentElement) o *= Number(getComputedStyle(e).opacity);
      return o;
    };
    const seen = new Map();
    const elements = new Set();
    for (const root of document.querySelectorAll(ROOTS)) {
      const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);
      for (let n = walker.nextNode(); n; n = walker.nextNode()) {
        // the grid's copy markers are hidden text, not shown
        const text = n.textContent.replace(/[✄\u{10617}\u{10602}]/gu, '').trim();
        if (text && n.parentElement) elements.add(n.parentElement);
      }
    }
    let rated = 0;
    for (const el of elements) {
      const style = getComputedStyle(el);
      const rect = el.getBoundingClientRect();
      if (rect.width <= 1 || rect.height <= 1) continue;
      if (style.visibility !== 'visible' || style.display === 'none') continue;
      if (style.clip && style.clip !== 'auto') continue;
      if (style.clipPath && style.clipPath !== 'none' && style.clipPath.includes('inset(50%')) continue;
      if (el.closest('[disabled], [aria-disabled="true"], .euiDataGridRowCell__expandFlex [hidden]')) continue;
      const alpha = opacity(el);
      if (alpha < 0.1) continue;
      const bg = background(el);
      const fgRaw = parse(style.color);
      const fg = over([fgRaw[0], fgRaw[1], fgRaw[2], fgRaw[3] * alpha], bg);
      const l1 = lum(fg);
      const l2 = lum(bg);
      const ratio = (Math.max(l1, l2) + 0.05) / (Math.min(l1, l2) + 0.05);
      const size = parseFloat(style.fontSize);
      const bold = Number(style.fontWeight) >= 700;
      const large = size >= 24 || (bold && size >= 18.66);
      // a glyph that is a graphic (a rating's stars, a check): 3:1 (WCAG 1.4.11)
      const graphic = /^[\u2605\u2606\u2713\u2714\u2022]+$/u.test(el.textContent.trim());
      const needed = large || graphic ? 3 : 4.5;
      rated++;
      if (ratio + 0.005 >= needed) continue;
      const cls = (typeof el.className === 'string' ? el.className : '')
        .split(/\s+/)
        .filter((c) => c && !c.startsWith('eui-spike-'))
        .slice(0, 3)
        .join('.');
      const hex = (c) => '#' + c.slice(0, 3).map((v) => Math.round(v).toString(16).padStart(2, '0')).join('');
      const key = `${el.tagName.toLowerCase()}.${cls} ${hex(fg)} on ${hex(bg)} ${ratio.toFixed(2)}`;
      const entry = seen.get(key) ?? {
        key,
        tag: el.tagName.toLowerCase(),
        cls,
        fg: hex(fg),
        bg: hex(bg),
        ratio: Number(ratio.toFixed(2)),
        needed,
        text: el.textContent.trim().slice(0, 40),
        count: 0
      };
      entry.count++;
      seen.set(key, entry);
    }
    return { rated, failures: [...seen.values()] };
  });
}

/** `{ scope: { 'rule (impact)': nodeCount } }` */
function tally(violations) {
  const out = {};
  for (const v of violations) {
    for (const n of v.nodes) {
      const key = `${v.id} (${v.impact})`;
      out[n.scope] ??= {};
      out[n.scope][key] = (out[n.scope][key] ?? 0) + 1;
    }
  }
  return out;
}

function addTally(total, part) {
  for (const [scope, rules] of Object.entries(part)) {
    total[scope] ??= {};
    for (const [rule, n] of Object.entries(rules)) {
      total[scope][rule] = (total[scope][rule] ?? 0) + n;
    }
  }
  return total;
}

module.exports = {
  BASE,
  MODES,
  sheetPages,
  launch,
  openPage,
  runAxe,
  runContrast,
  tally,
  addTally
};
