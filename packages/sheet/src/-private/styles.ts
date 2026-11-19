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
.euiSheet__checkbox--mixed { background: var(--euiSheet-primary, #0B64DD); border-color: var(--euiSheet-primary, #0B64DD); }
.euiSheet__checkbox--mixed::after { content: ''; position: absolute; left: 2px; top: 5px; width: 8px; height: 2px; background: var(--euiSheet-textInverse, #FFF); }
.euiSheet .euiSheet__rowCell { background-color: var(--euiSheet-subdued, #F7F8FC); color: var(--euiSheet-textSubdued, #69707D); cursor: default; }
.euiSheet .euiSheet__rowCell [data-datagrid-cellcontent] { display: flex; align-items: center; justify-content: space-between; gap: 4px; width: 100%; }
.euiSheet .euiDataGridRowCell.euiSheet__rowCell--selected { background-color: var(--euiSheet-selected, rgba(0, 119, 204, 0.12)); }
.euiSheet__rowStart { display: inline-flex; align-items: center; min-width: 0; overflow: hidden; }
.euiSheet__rowLabel { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; font-variant-numeric: tabular-nums; }
.euiSheet__rowCheck { display: none; }
.euiSheet .euiDataGridRow:hover .euiSheet__rowCheck, .euiSheet__rowCell--checked .euiSheet__rowCheck, .euiSheet__rowCell:focus .euiSheet__rowCheck { display: inline-block; }
.euiSheet .euiDataGridRow:hover .euiSheet__rowLabel, .euiSheet__rowCell--checked .euiSheet__rowLabel, .euiSheet__rowCell:focus .euiSheet__rowLabel { display: none; }
.euiSheet__rowExpand { display: inline-flex; padding: 2px; border-radius: 3px; cursor: pointer; visibility: hidden; }
.euiSheet__rowExpand:hover { background: var(--euiSheet-hover, rgba(105, 112, 125, 0.16)); color: var(--euiSheet-text, #343741); }
.euiSheet .euiDataGridRow:hover .euiSheet__rowExpand, .euiSheet__rowCell:focus .euiSheet__rowExpand { visibility: visible; }
.euiSheet__rowCheckAll { margin-left: 2px; }
.euiSheet .euiSheet__addRow .euiDataGridRowCell { cursor: pointer; color: var(--euiSheet-textSubdued, #69707D); }
.euiSheet .euiSheet__addRow:hover .euiDataGridRowCell { background-color: var(--euiSheet-hover, rgba(105, 112, 125, 0.06)); }
.euiSheet__addRecord, .euiSheet__rowAdd { display: inline-flex; align-items: center; gap: 4px; white-space: nowrap; }
.euiSheet__menu { position: absolute; z-index: 5; min-width: 200px; }
.euiSheet__editor--inline { position: relative; margin-top: 4px; }
.euiSheet__editor--inline .euiSheet__input { height: 32px; border-radius: 4px; }
.euiSheetRecord__header { display: flex; align-items: center; gap: 4px; padding-right: 32px; }
.euiSheetRecord__title { flex: 1; min-width: 0; margin: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; font-size: 20px; line-height: 28px; font-weight: 600; color: var(--euiSheet-text, #343741); }
.euiSheetRecord__field { margin-bottom: 16px; }
.euiSheetRecord__label { margin-bottom: 4px; font-size: 12px; line-height: 16px; font-weight: 600; color: var(--euiSheet-text, #343741); }
.euiSheetRecord__box { position: relative; box-sizing: border-box; min-height: 32px; padding: 6px 8px; border: 1px solid var(--euiSheet-border, #D3DAE6); border-radius: 4px; background: var(--euiSheet-plain, #FFF); color: var(--euiSheet-text, #343741); line-height: 18px; overflow-wrap: anywhere; }
.euiSheetRecord__box[role=button] { cursor: pointer; }
.euiSheetRecord__box[role=button]:hover { background-color: var(--euiSheet-hover, rgba(105, 112, 125, 0.06)); }
.euiSheetRecord__box:focus { outline: 2px solid var(--euiSheet-primary, #0B64DD); outline-offset: -1px; }
.euiSheetRecord__box--readOnly { background: var(--euiSheet-subdued, #F7F8FC); color: var(--euiSheet-textSubdued, #69707D); }
.euiSheetRecord__box--invalid { border-color: var(--euiSheet-danger, #BD271E); color: var(--euiSheet-textDanger, #BD271E); }
.euiSheetRecord__errors { margin-top: 4px; font-size: 12px; line-height: 16px; color: var(--euiSheet-textDanger, #BD271E); }
.euiSheet__checkbox--checked::after { content: ''; position: absolute; left: 4px; top: 1px; width: 4px; height: 8px; border: solid var(--euiSheet-textInverse, #FFF); border-width: 0 2px 2px 0; transform: rotate(45deg); }
.euiSheet__toolbar { margin-bottom: 8px; }
.euiSheet__footer { margin-top: 8px; }
.euiSheetSearch > .euiSheet__toolbar:not(:has(> *)), .euiSheetSearch > .euiSheet__footer:not(:has(> *)) { display: none; }
.euiSheetSearch__bar { display: flex; flex-wrap: wrap; align-items: center; gap: 8px; }
.euiSheetSearch__footer { display: flex; flex-direction: column; gap: 8px; }
.euiSheet__grid { position: relative; }
.euiSheet__loading { z-index: 4; }
.euiSheet__headerTip { display: inline-flex; margin-left: 4px; vertical-align: middle; }
.euiSheetRecord__description { margin: -2px 0 4px; font-size: 12px; line-height: 16px; color: var(--euiSheet-textSubdued, #69707D); }
.euiSheet .euiDataGridRowCell.euiSheet__cell--frozen { --euiSheetFrozenBase: var(--euiSheet-plain, #FFF); background-color: var(--euiSheetFrozenBase); background-image: none; }
.euiSheet .euiDataGridRowCell.euiSheet__rowCell.euiSheet__cell--frozen { --euiSheetFrozenBase: var(--euiSheet-subdued, #F7F8FC); }
.euiSheet .euiDataGridRow:hover .euiDataGridRowCell.euiSheet__cell--frozen { background-color: var(--euiSheetFrozenBase); background-image: linear-gradient(var(--euiSheet-hover, rgba(105, 112, 125, 0.06)), var(--euiSheet-hover, rgba(105, 112, 125, 0.06))); }
.euiSheet .euiDataGridRowCell.euiSheet__cell--frozen.euiSheet__cell--selected, .euiSheet .euiDataGridRowCell.euiSheet__cell--frozen.euiSheet__rowCell--selected { background-color: var(--euiSheetFrozenBase); background-image: linear-gradient(var(--euiSheet-selected, rgba(0, 119, 204, 0.12)), var(--euiSheet-selected, rgba(0, 119, 204, 0.12))); }
.euiSheet .euiDataGridFooterCell.euiSheet__cell--frozen { background-color: inherit; background-image: none; }
.euiSheet .euiDataGridHeaderCell.euiSheet__frozenHeader { position: sticky; z-index: 3; background-color: inherit; }
.euiSheet--scrolledX .euiSheet__frozenEdge { box-shadow: 4px 0 4px -2px var(--euiSheet-shadow, rgba(0, 0, 0, 0.2)); }
.euiSheet--scrolledX .euiSheet__frozenEdge.euiSheet__cell--invalid { box-shadow: inset 0 0 0 1px var(--euiSheet-danger, #BD271E), 4px 0 4px -2px var(--euiSheet-shadow, rgba(0, 0, 0, 0.2)); }
${frozenHeaderLefts()}
`;

/**
 * `left` of each frozen header cell, from a custom property the sheet sets
 * per grid column index (the header cell's own style is the grid's).
 * Index 0 is the row-number column; up to FROZEN_MAX_COLUMNS fields.
 */
function frozenHeaderLefts(): string {
  const rules: string[] = [];
  for (let i = 0; i <= 51; i++) {
    rules.push(
      `.euiSheet .euiSheet__frozenHeader--${i} { left: var(--euiSheetFrozenLeft-${i}, 0px); }`
    );
  }
  return rules.join('\n');
}

export function ensureStyles(): void {
  if (typeof document === 'undefined') return;
  if (document.head.querySelector('style[data-eui-sheet]')) return;
  const style = document.createElement('style');
  style.setAttribute('data-eui-sheet', '');
  style.textContent = CSS;
  document.head.appendChild(style);
}
