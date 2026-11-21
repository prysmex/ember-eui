// Checks a sheet's grid semantics in the DOM, beyond axe: the grid's
// counts, every rendered row's and cell's role and indices, and that a
// column's cells share its header's `aria-colindex` (with virtualization
// and with the frozen grid's column window), before and after scrolling.
//   node aria-grid.js <page path> <grid aria-label> [scrollLeft px] [scrollTop px]
//   FREEZE=1: click the page's first switch labelled "Freeze..." first.
// Prints the problems found and a `RESULT {...}` line.
const lib = require('./lib.js');

async function main() {
  const [url, label, left = '0', top = '0'] = process.argv.slice(2);
  const { browser, context } = await lib.launch();
  const { page } = await lib.openPage(context, url, 'light');
  if (process.env.FREEZE) {
    await page.getByRole('switch', { name: /^Freeze/ }).first().click();
    await page.waitForTimeout(800);
  }
  const check = () =>
    page.evaluate((label) => {
      const grid = document.querySelector(`[role=grid][aria-label="${label}"]`);
      const problems = [];
      const headerIndex = new Map();
      for (const header of grid.querySelectorAll('[role=columnheader]')) {
        const id = header.getAttribute('data-gridcell-column-id');
        const index = header.getAttribute('aria-colindex');
        if (headerIndex.has(id) && headerIndex.get(id) !== index)
          problems.push(`header ${id}: two colindex`);
        headerIndex.set(id, index);
        if (!header.textContent.trim() && !header.getAttribute('aria-label'))
          problems.push(`header ${id} (${index}): no text`);
      }
      const indices = [...headerIndex.values()].map(Number);
      if (new Set(indices).size !== indices.length)
        problems.push(`headers share an aria-colindex: ${indices}`);
      const colcount = Number(grid.getAttribute('aria-colcount'));
      const rowcount = Number(grid.getAttribute('aria-rowcount'));
      if (Math.max(...indices) > colcount)
        problems.push(`header colindex ${Math.max(...indices)} > colcount ${colcount}`);
      const rows = [...grid.querySelectorAll('[role=row]')];
      const rowIndices = [];
      let cells = 0;
      for (const row of rows) {
        const rowCells = [...row.querySelectorAll('[role=gridcell]')];
        if (!rowCells.length) continue;
        const rowIndex = new Set(rowCells.map((c) => c.getAttribute('aria-rowindex')));
        if (rowIndex.size !== 1) problems.push(`a row's cells have rowindex ${[...rowIndex]}`);
        rowIndices.push(Number([...rowIndex][0]));
        const seen = new Set();
        for (const c of rowCells) {
          cells++;
          const id = c.getAttribute('data-gridcell-column-id');
          const index = c.getAttribute('aria-colindex');
          if (seen.has(index)) problems.push(`row ${[...rowIndex][0]}: colindex ${index} twice`);
          seen.add(index);
          if (headerIndex.has(id) && headerIndex.get(id) !== index)
            problems.push(
              `row ${[...rowIndex][0]} ${id}: colindex ${index}, its header ${headerIndex.get(id)}`
            );
        }
      }
      if (Math.max(...rowIndices) > rowcount)
        problems.push(`rowindex ${Math.max(...rowIndices)} > rowcount ${rowcount}`);
      // the rows' cells that are not inside a role=row
      const loose = [...grid.querySelectorAll('[role=gridcell]')].filter(
        (c) => !c.closest('[role=row]')
      ).length;
      if (loose) problems.push(`${loose} gridcells outside a row`);
      return {
        rowcount,
        colcount,
        headers: Object.fromEntries(headerIndex),
        renderedRows: rowIndices.length,
        firstRows: rowIndices.slice(0, 5),
        cells,
        problems: problems.slice(0, 30),
        problemCount: problems.length
      };
    }, label);
  console.log('RESULT top', JSON.stringify(await check()));
  if (Number(left) || Number(top)) {
    await page.evaluate(
      ({ label, left, top }) => {
        const grid = document.querySelector(`[role=grid][aria-label="${label}"]`);
        const scroller = grid.querySelector('.euiDataGrid__virtualized');
        scroller.scrollLeft = left;
        scroller.scrollTop = top;
      },
      { label, left: Number(left), top: Number(top) }
    );
    await page.waitForTimeout(800);
    console.log('RESULT scrolled', JSON.stringify(await check()));
  }
  await browser.close();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
