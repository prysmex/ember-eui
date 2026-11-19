/**
 * The sheet's few styles, added once to `document.head` (one
 * `<style data-eui-sheet>` per page, not one per sheet). Every colour is a
 * `--euiSheet-*` custom property, defined from the EUI theme by the
 * wrapper's class (`theme.ts`), with today's light colour as the fallback.
 */
const CSS = `
.euiSheet { position: relative; }
.euiSheet--dragging, .euiSheet--dragging * { user-select: none; -webkit-user-select: none; }
.euiSheet .euiDataGridRow:hover .euiDataGridRowCell { background-color: var(--euiSheet-hover, rgba(105, 112, 125, 0.06)); }
.euiSheet .euiDataGridRowCell.euiSheet__cell--selected { background-color: var(--euiSheet-selected, rgba(0, 119, 204, 0.12)); }
.euiSheet .euiDataGridRowCell:focus { outline: 2px solid var(--euiSheet-primary, #0B64DD); outline-offset: -2px; }
.euiSheet__opener { position: absolute; top: 50%; right: 6px; transform: translateY(-50%); display: inline-flex; padding: 2px; border-radius: 3px; color: var(--euiSheet-textSubdued, #69707D); cursor: pointer; visibility: hidden; }
.euiSheet__opener:hover { background: var(--euiSheet-hover, rgba(105, 112, 125, 0.16)); color: var(--euiSheet-text, #343741); }
.euiSheet .euiDataGridRowCell:hover .euiSheet__opener,
.euiSheet .euiDataGridRowCell:focus .euiSheet__opener,
.euiSheet .euiSheet__cell--selected .euiSheet__opener { visibility: visible; }
.euiSheet__cell--invalid { color: var(--euiSheet-textDanger, #BD271E); box-shadow: inset 0 0 0 1px var(--euiSheet-danger, #BD271E); }
.euiSheet__cellError { position: absolute; z-index: 4; box-sizing: border-box; padding: 4px 8px; border-radius: 4px; background: var(--euiSheet-dangerFilled, #BD271E); color: var(--euiSheet-textInverse, #FFF); font-size: 12px; line-height: 16px; pointer-events: none; box-shadow: 0 2px 6px var(--euiSheet-shadow, rgba(0, 0, 0, 0.2)); }
.euiSheet__editor { position: absolute; box-sizing: border-box; }
.euiSheet__editor--cell { z-index: 2; }
.euiSheet__editor--panel { z-index: 3; }
.euiSheet__input { display: block; box-sizing: border-box; width: 100%; height: 100%; margin: 0; padding: 0 6px; border: 2px solid var(--euiSheet-primary, #0B64DD); background: var(--euiSheet-plain, #FFF); color: var(--euiSheet-text, #343741); font: inherit; }
.euiSheet__checkbox { display: inline-block; box-sizing: border-box; width: 14px; height: 14px; vertical-align: middle; border: 1px solid var(--euiSheet-textSubdued, #69707D); border-radius: 3px; background: var(--euiSheet-plain, #FFF); position: relative; cursor: pointer; }
.euiSheet__checkbox--checked { background: var(--euiSheet-primary, #0B64DD); border-color: var(--euiSheet-primary, #0B64DD); }
.euiSheet__checkbox--checked::after { content: ''; position: absolute; left: 4px; top: 1px; width: 4px; height: 8px; border: solid var(--euiSheet-textInverse, #FFF); border-width: 0 2px 2px 0; transform: rotate(45deg); }
`;

export function ensureStyles(): void {
  if (typeof document === 'undefined') return;
  if (document.head.querySelector('style[data-eui-sheet]')) return;
  const style = document.createElement('style');
  style.setAttribute('data-eui-sheet', '');
  style.textContent = CSS;
  document.head.appendChild(style);
}
