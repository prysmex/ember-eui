'use strict';

// Leak mode (opt-in): `EUI_LEAKS=1 testem --file testem.cjs ci`.
// Adds `?leaks` to the test page (tests/leak-detector.ts), exposes gc() and
// precise heap numbers to the page, and writes the report the page POSTs to
// $EUI_LEAKS_OUT (default: leak-report.json). EUI_LEAKS_FILTER narrows the run.
const leaks = Boolean(process.env.EUI_LEAKS);

function leakReportMiddleware(app) {
  const fs = require('node:fs');
  const path = require('node:path');
  app.post('/__leak-report', (req, res) => {
    let body = '';
    req.setEncoding('utf8');
    req.on('data', (chunk) => (body += chunk));
    req.on('end', () => {
      const out = path.resolve(
        __dirname,
        process.env.EUI_LEAKS_OUT || 'leak-report.json'
      );
      fs.writeFileSync(out, body);
      console.log(`[leaks] report written to ${out}`);
      res.status(204).end();
    });
  });
}

function testPage() {
  let page = 'tests/index.html?hidepassed';
  if (leaks) {
    page += '&leaks';
    if (process.env.EUI_LEAKS_FILTER) {
      page += `&filter=${encodeURIComponent(process.env.EUI_LEAKS_FILTER)}`;
    }
  }
  return page;
}

if (typeof module !== 'undefined') {
  module.exports = {
    test_page: testPage(),
    cwd: 'dist-tests',
    disable_watching: true,
    launch_in_ci: ['Chrome'],
    launch_in_dev: ['Chrome'],
    browser_start_timeout: 120,
    // the icon catalog test renders every icon at once; under load it can
    // block the browser longer than testem's 10s default and abort the run
    browser_disconnect_timeout: 120,
    middleware: leaks ? [leakReportMiddleware] : [],
    browser_args: {
      Chrome: {
        ci: [
          // --no-sandbox is needed when running Chrome inside a container
          process.env.CI ? '--no-sandbox' : null,
          // leak mode: forced gc() in --headless=new crashes the renderer in
          // this sandbox (PartitionAlloc FATAL, errno 12) once the page holds
          // a few thousand DOM nodes; the old headless mode does not
          leaks ? '--headless=old' : '--headless=new',
          '--disable-dev-shm-usage',
          '--disable-software-rasterizer',
          '--mute-audio',
          '--remote-debugging-port=0',
          '--window-size=1440,900',
          leaks ? '--js-flags=--expose-gc' : null,
          leaks ? '--enable-precise-memory-info' : null,
          // old headless throttles rAF/timers once a test opens another window
          leaks ? '--disable-background-timer-throttling' : null,
          leaks ? '--disable-renderer-backgrounding' : null,
          leaks ? '--disable-backgrounding-occluded-windows' : null,
          // old headless lets tests open windows (links with target=_blank);
          // through testem they load the test page again and run a 2nd suite
          leaks ? '--block-new-web-contents' : null,
        ].filter(Boolean),
      },
    },
  };
}
