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
/* the selection wins over the row hover, so a range shows while it is dragged in one row */
/* checked rows (V03 batch 1): a light tint, before the selection rules so a range wins */
.euiSheet .euiDataGridRowCell.euiSheet__cell--checked { background-color: var(--euiSheet-checked, rgba(11, 100, 221, 0.06)); }
.euiSheet .euiDataGridRow:hover .euiDataGridRowCell.euiSheet__cell--checked { background-color: var(--euiSheet-checked, rgba(11, 100, 221, 0.06)); background-image: linear-gradient(var(--euiSheet-hover, rgba(105, 112, 125, 0.06)), var(--euiSheet-hover, rgba(105, 112, 125, 0.06))); }
.euiSheet .euiDataGridRowCell.euiSheet__cell--selected, .euiSheet .euiDataGridRow:hover .euiDataGridRowCell.euiSheet__cell--selected { background-color: var(--euiSheet-selected, rgba(11, 100, 221, 0.12)); background-image: none; }
/* the active cell's ring (V03 batch 1): 3 px inside the cell; over the grid's own (its :focus-visible "outline: none" and its ::after ring) */
.euiSheet .euiDataGridRowCell:focus, .euiSheet .euiDataGridRow .euiDataGridRowCell:focus { outline: 3px solid var(--euiSheet-primary, #0B64DD); outline-offset: -3px; }
.euiSheet .euiDataGridRow .euiDataGridRowCell:focus::after { border-color: transparent; }
/* no grid outline on a hovered cell (its ::after): the sheet's active ring and range outline show where you are, as in Airtable */
.euiSheet .euiDataGrid .euiDataGridRow .euiDataGridRowCell::after { content: none; }
.euiSheet__opener { position: absolute; top: 50%; right: 6px; transform: translateY(-50%); display: inline-flex; padding: 2px; border-radius: 3px; color: var(--euiSheet-textSubdued, #69707D); cursor: pointer; visibility: hidden; }
.euiSheet__opener:hover { background: var(--euiSheet-hover, rgba(105, 112, 125, 0.16)); color: var(--euiSheet-text, #343741); }
.euiSheet .euiDataGridRowCell:hover .euiSheet__opener,
.euiSheet .euiDataGridRowCell:focus .euiSheet__opener,
.euiSheet .euiSheet__cell--selected .euiSheet__opener { visibility: visible; }
.euiSheet__cell--invalid { color: var(--euiSheet-textDanger, #BD271E); box-shadow: inset 0 0 0 1px var(--euiSheet-danger, #BD271E); }
/* focused and invalid: a 2 px error band just inside the 3 px ring (V03 batch 2: 1 px did not read next to the ring) */
.euiSheet .euiDataGridRow .euiDataGridRowCell.euiSheet__cell--invalid:focus { box-shadow: inset 0 0 0 5px var(--euiSheet-danger, #BD271E); }
.euiSheet__cellError { position: absolute; z-index: 4; box-sizing: border-box; padding: 4px 8px; border-radius: 4px; background: var(--euiSheet-dangerFilled, #BD271E); color: var(--euiSheet-textInverse, #FFF); font-size: 12px; line-height: 16px; pointer-events: none; box-shadow: 0 2px 6px var(--euiSheet-shadow, rgba(0, 0, 0, 0.2)); }
/* the read-only cue (V03 batch 2): the message box, neutral, with a lock */
.euiSheet__cellError.euiSheet__cellError--notice { background: var(--euiSheet-text, #343741); color: var(--euiSheet-plain, #FFF); }
.euiSheet__cellNotice { display: inline-flex; align-items: center; gap: 4px; }
/* keyboard focus on a header (V03 batch 2): the data cells' 3 px ring, over the grid's ":focus-visible { outline: none }" and its ::after */
.euiSheet .euiDataGridHeader .euiDataGridHeaderCell:focus, .euiSheet .euiDataGridHeader .euiDataGridHeaderCell:focus-visible { outline: 3px solid var(--euiSheet-primary, #0B64DD); outline-offset: -3px; }
.euiSheet .euiDataGridHeader .euiDataGridHeaderCell:focus::after { border-color: transparent; }
.euiSheet__editor { position: absolute; box-sizing: border-box; }
.euiSheet__editor--cell { z-index: 2; }
/* the open cell editor (V03 batch 1): lifted 2 px past the cell (clamped at the body's edges by EditorFrame), a 3 px ring, the theme's elevation; the padding keeps the caret where the cell's text was */
.euiSheet__editor--cell .euiSheet__input, .euiSheet__editor--expand .euiSheet__textarea { border-width: 3px; border-radius: 2px; box-shadow: 0 4px 12px var(--euiSheet-elevation, rgba(0, 0, 0, 0.25)); }
.euiSheet__editor--cell .euiSheet__input { padding: 0 var(--euiSheetEditorPadX, 5px); }
.euiSheet__editor--expand .euiSheet__textarea { padding: var(--euiSheetEditorPadY, 4px) var(--euiSheetEditorPadX, 5px); }
.euiSheet__editor--panel { z-index: 3; }
/* the floating layers (V03 batch 2, after the real-input check): portaled to <body>, placed in the viewport by layer.gts (z-index too: above the wrapper's stacking context) */
.euiSheetLayer { color: var(--euiSheet-text, #343741); }
.euiSheetLayer .euiSheet__editor--panel, .euiSheetLayer .euiSheet__menu, .euiSheetLayer .euiSheet__fieldEditor { position: fixed; top: 0; left: 0; z-index: 2000; }
.euiSheet__input { display: block; box-sizing: border-box; width: 100%; height: 100%; margin: 0; padding: 0 6px; border: 2px solid var(--euiSheet-primary, #0B64DD); background: var(--euiSheet-plain, #FFF); color: var(--euiSheet-text, #343741); font: inherit; }
.euiSheet__checkbox { display: inline-block; box-sizing: border-box; width: 14px; height: 14px; vertical-align: middle; border: 1.5px solid var(--euiSheet-textSubdued, #69707D); border-radius: 3px; background: var(--euiSheet-plain, #FFF); position: relative; cursor: pointer; }
.euiSheet__checkbox--checked { background: var(--euiSheet-primary, #0B64DD); border-color: var(--euiSheet-primary, #0B64DD); }
.euiSheet__checkbox--mixed { background: var(--euiSheet-primary, #0B64DD); border-color: var(--euiSheet-primary, #0B64DD); }
.euiSheet__checkbox--mixed::after { content: ''; position: absolute; left: 2px; top: 5px; width: 8px; height: 2px; background: var(--euiSheet-textInverse, #FFF); }
.euiSheet .euiSheet__rowCell { background-color: var(--euiSheet-subdued, #F7F8FC); color: var(--euiSheet-textSubdued, #69707D); cursor: default; }
.euiSheet .euiSheet__rowCell [data-datagrid-cellcontent] { display: flex; align-items: center; justify-content: space-between; gap: 4px; width: 100%; }
/* row numbers (V03 batch 1): a checked row's number in the selection tint; a cell range marks its rows' numbers lightly; selected rows get the tint and a 3 px bar on the inner edge */
.euiSheet .euiDataGridRowCell.euiSheet__rowCell--checked, .euiSheet .euiDataGridRow:hover .euiDataGridRowCell.euiSheet__rowCell--checked { background-color: var(--euiSheet-selected, rgba(11, 100, 221, 0.12)); }
.euiSheet .euiDataGridRowCell.euiSheet__rowCell--marked { background-image: linear-gradient(var(--euiSheet-hover, rgba(105, 112, 125, 0.06)), var(--euiSheet-hover, rgba(105, 112, 125, 0.06))); color: var(--euiSheet-primary, #0B64DD); }
.euiSheet .euiDataGridRowCell.euiSheet__rowCell--selected, .euiSheet .euiDataGridRow:hover .euiDataGridRowCell.euiSheet__rowCell--selected { background-color: var(--euiSheet-selected, rgba(11, 100, 221, 0.12)); box-shadow: inset -3px 0 0 var(--euiSheet-primary, #0B64DD); color: var(--euiSheet-primary, #0B64DD); }
.euiSheet__rowStart { display: inline-flex; align-items: center; min-width: 0; overflow: hidden; }
.euiSheet__rowLabel { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; font-variant-numeric: tabular-nums; }
.euiSheet__rowCheck { display: none; }
.euiSheet .euiDataGridRow:hover .euiSheet__rowCheck, .euiSheet__rowCell--checked .euiSheet__rowCheck, .euiSheet__rowCell:focus .euiSheet__rowCheck { display: inline-block; }
.euiSheet .euiDataGridRow:hover .euiSheet__rowLabel, .euiSheet__rowCell--checked .euiSheet__rowLabel, .euiSheet__rowCell:focus .euiSheet__rowLabel { display: none; }
.euiSheet__rowExpand { display: inline-flex; padding: 2px; border-radius: 4px; color: var(--euiSheet-text, #343741); cursor: pointer; visibility: hidden; }
.euiSheet__rowExpand:hover { background: var(--euiSheet-hover, rgba(105, 112, 125, 0.16)); color: var(--euiSheet-primary, #0B64DD); }
.euiSheet__rowCheck:hover { border-color: var(--euiSheet-primary, #0B64DD); }
.euiSheet .euiDataGridRow:hover .euiSheet__rowExpand, .euiSheet__rowCell:focus .euiSheet__rowExpand { visibility: visible; }
.euiSheet__rowCheckAll { margin-left: 2px; }
.euiSheet__addRecord, .euiSheet__rowAdd { display: inline-flex; align-items: center; gap: 4px; white-space: nowrap; }
.euiSheet__menu { position: absolute; z-index: 5; min-width: 200px; }
/* the row menu (V03 batch 1): groups, and a shadow and a hairline that read in dark too */
.euiSheet__menu > .euiPanel { max-height: var(--euiSheetLayerMaxHeight, none); overflow-y: auto; }
.euiSheet__menu > .euiPanel { box-shadow: 0 4px 12px var(--euiSheet-elevation, rgba(0, 0, 0, 0.25)); border: 1px solid var(--euiSheet-border, #D3DAE6); }
.euiSheet__menuSeparator { height: 0; margin: 4px 0; border: 0; border-top: 1px solid var(--euiSheet-border, #D3DAE6); }
/* the copy mark (dashed, until Escape or a change) and the changed cells' fading tint */
.euiSheet__range.euiSheet__range--fill { border: 2px dashed var(--euiSheet-primary, #0B64DD); }
/* the copy mark sits just inside the range outline, so both show while the copied range is still selected */
.euiSheet__range.euiSheet__range--copied { border: 0; outline: 2px dashed var(--euiSheet-primary, #0B64DD); outline-offset: -6px; z-index: 4; }
.euiSheet__range.euiSheet__range--flash { border: 0; background-color: var(--euiSheet-selected, rgba(11, 100, 221, 0.12)); animation: euiSheetFlash 600ms ease-out forwards; }
@keyframes euiSheetFlash { from { opacity: 1; } to { opacity: 0; } }
@media (prefers-reduced-motion: reduce) { .euiSheet__range--flash { display: none; } }
/* the empty state (V03 batch 1) */
.euiSheet__empty { display: flex; flex-direction: column; align-items: center; gap: 4px; padding: 24px 16px; color: var(--euiSheet-textSubdued, #69707D); font-size: 14px; line-height: 20px; text-align: center; }
.euiSheet__editor--inline { position: relative; margin-top: 4px; }
/* the 3 px border is the editor's focus mark: no browser or EUI focus outline over it */
.euiSheet__input:focus, .euiSheet__input:focus-visible, .euiSheet__textarea:focus, .euiSheet__textarea:focus-visible { outline: none; }
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
.euiSheetShortcuts__section { width: 100%; table-layout: fixed; margin-bottom: 16px; border-collapse: collapse; }
.euiSheetShortcuts__title { padding-bottom: 4px; text-align: left; font-size: 12px; line-height: 16px; font-weight: 600; text-transform: uppercase; color: var(--euiSheet-textSubdued, #69707D); }
.euiSheetShortcuts__keys, .euiSheetShortcuts__text { padding: 4px 0; border-top: 1px solid var(--euiSheet-border, #D3DAE6); vertical-align: top; font-size: 14px; line-height: 20px; color: var(--euiSheet-text, #343741); }
.euiSheetShortcuts__keys { width: 45%; padding-right: 16px; white-space: normal; }
.euiSheetShortcuts__key { display: inline-block; min-width: 20px; margin: 0 2px; padding: 0 4px; box-sizing: border-box; border: 1px solid var(--euiSheet-border, #D3DAE6); border-radius: 3px; background: var(--euiSheet-subdued, #F7F8FC); font-family: inherit; font-size: 12px; line-height: 18px; text-align: center; }
.euiSheetShortcuts__or { margin: 0 4px; color: var(--euiSheet-textSubdued, #69707D); }
.euiSheet__toolbar { margin-bottom: 8px; }
.euiSheet__footer { margin-top: 8px; }
.euiSheetSearch > .euiSheet__toolbar:not(:has(> *)), .euiSheetSearch > .euiSheet__footer:not(:has(> *)) { display: none; }
.euiSheetSearch__bar { display: flex; flex-wrap: wrap; align-items: center; gap: 8px; }
.euiSheetSearch__footer { display: flex; flex-direction: column; gap: 8px; }
.euiSheet__grid { position: relative; }
.euiSheet__loading { z-index: 4; }
/* the loading bar (V03 batch 2): 3 px, not the grid's 2 */
.euiSheet__grid > .euiSheet__loading { height: 3px; }
.euiSheet__headerTip { display: inline-flex; margin-left: 4px; vertical-align: middle; }
/* the header menu's trigger (V03 batch 1): the text colour, a 16 px icon, a hover background; always shown on the active cell's and the selected columns' headers (headerMarkRules) and on touch screens. The grid draws the icon (ellipsis): it cannot be chosen without a core change */
.euiSheet .euiDataGridHeaderCell .euiDataGridHeaderCell__button { color: var(--euiSheet-text, #343741); border-radius: 4px; }
.euiSheet .euiDataGridHeaderCell .euiDataGridHeaderCell__button svg { width: 16px; height: 16px; }
.euiSheet .euiDataGridHeaderCell .euiDataGridHeaderCell__button:hover { background-color: var(--euiSheet-hover, rgba(105, 112, 125, 0.16)); }
@media (pointer: coarse) { .euiSheet .euiDataGridHeader .euiDataGridHeaderCell .euiDataGridHeaderCell__button { margin-inline-start: 0; transform: none; opacity: 1; } }
/* header lines (V03 5.4); the grid's truncation sets white-space with !important */
.euiSheet--headerLines2 .euiDataGridHeaderCell__content, .euiSheet--headerLines3 .euiDataGridHeaderCell__content { white-space: normal !important; overflow-wrap: anywhere; overflow: hidden; display: -webkit-box; -webkit-box-orient: vertical; -webkit-line-clamp: 2; }
.euiSheet--headerLines3 .euiDataGridHeaderCell__content { -webkit-line-clamp: 3; }
.euiSheetRecord__description { margin: -2px 0 4px; font-size: 12px; line-height: 16px; color: var(--euiSheet-textSubdued, #69707D); }
.euiSheet .euiDataGridRowCell.euiSheet__cell--frozen { --euiSheetFrozenBase: var(--euiSheet-plain, #FFF); background-color: var(--euiSheetFrozenBase); background-image: none; }
.euiSheet .euiDataGridRowCell.euiSheet__rowCell.euiSheet__cell--frozen { --euiSheetFrozenBase: var(--euiSheet-subdued, #F7F8FC); }
.euiSheet .euiDataGridRow:hover .euiDataGridRowCell.euiSheet__cell--frozen { background-color: var(--euiSheetFrozenBase); background-image: linear-gradient(var(--euiSheet-hover, rgba(105, 112, 125, 0.06)), var(--euiSheet-hover, rgba(105, 112, 125, 0.06))); }
/* frozen and checked: the tint as an image over the opaque base */
.euiSheet .euiDataGridRowCell.euiSheet__cell--frozen.euiSheet__cell--checked, .euiSheet .euiDataGridRowCell.euiSheet__cell--frozen.euiSheet__rowCell--checked { background-color: var(--euiSheetFrozenBase); background-image: linear-gradient(var(--euiSheet-checked, rgba(11, 100, 221, 0.06)), var(--euiSheet-checked, rgba(11, 100, 221, 0.06))); }
.euiSheet .euiDataGridRow:hover .euiDataGridRowCell.euiSheet__cell--frozen.euiSheet__cell--checked, .euiSheet .euiDataGridRow:hover .euiDataGridRowCell.euiSheet__cell--frozen.euiSheet__rowCell--checked { background-color: var(--euiSheetFrozenBase); background-image: linear-gradient(var(--euiSheet-hover, rgba(105, 112, 125, 0.06)), var(--euiSheet-hover, rgba(105, 112, 125, 0.06))), linear-gradient(var(--euiSheet-checked, rgba(11, 100, 221, 0.06)), var(--euiSheet-checked, rgba(11, 100, 221, 0.06))); }
.euiSheet .euiDataGridRowCell.euiSheet__cell--frozen.euiSheet__rowCell--marked { background-color: var(--euiSheetFrozenBase); background-image: linear-gradient(var(--euiSheet-hover, rgba(105, 112, 125, 0.06)), var(--euiSheet-hover, rgba(105, 112, 125, 0.06))); }
.euiSheet .euiDataGridRowCell.euiSheet__cell--frozen.euiSheet__cell--selected, .euiSheet .euiDataGridRowCell.euiSheet__cell--frozen.euiSheet__rowCell--selected, .euiSheet .euiDataGridRow:hover .euiDataGridRowCell.euiSheet__cell--frozen.euiSheet__cell--selected, .euiSheet .euiDataGridRow:hover .euiDataGridRowCell.euiSheet__cell--frozen.euiSheet__rowCell--selected { background-color: var(--euiSheetFrozenBase); background-image: linear-gradient(var(--euiSheet-selected, rgba(11, 100, 221, 0.12)), var(--euiSheet-selected, rgba(11, 100, 221, 0.12))); }
.euiSheet .euiDataGridFooterCell.euiSheet__cell--frozen { background-color: inherit; background-image: none; }
/* in a range of more than one cell the active (focused) cell keeps the plain background, as in Airtable */
.euiSheet.euiSheet--ranged .euiDataGridRow .euiDataGridRowCell.euiSheet__cell--selected:focus { background-color: var(--euiSheet-plain, #FFF); background-image: none; }
/* the add row (V03 5.2), after the frozen rules: one opaque background for every cell (frozen, row number), hover drawn over it as frozen cells do, no inner dividers (the grid frame's outer edges stay), no grid outline (its ::after: the grey hover box and a second focus ring) */
.euiSheet .euiDataGridRow.euiSheet__addRow .euiDataGridRowCell { --euiSheetFrozenBase: var(--euiSheet-plain, #FFF); background-color: var(--euiSheet-plain, #FFF); background-image: none; color: var(--euiSheet-textSubdued, #69707D); cursor: pointer; }
.euiSheet .euiDataGridRow.euiSheet__addRow .euiDataGridRowCell:not(.euiDataGridRowCell--lastColumn) { border-inline-end-color: transparent; }
.euiSheet .euiDataGridRow.euiSheet__addRow:hover .euiDataGridRowCell { background-color: var(--euiSheet-plain, #FFF); background-image: linear-gradient(var(--euiSheet-hover, rgba(105, 112, 125, 0.06)), var(--euiSheet-hover, rgba(105, 112, 125, 0.06))); }
.euiSheet .euiDataGridRow.euiSheet__addRow .euiDataGridRowCell::after { content: none; }
.euiSheet .euiDataGridRow.euiSheet__addRow .euiDataGridRowCell__content { display: flex; align-items: center; }
.euiSheet__addPinned { display: none; position: absolute; inset: 0; align-items: center; white-space: nowrap; pointer-events: none; }
.euiSheet__addPinnedPlus { display: inline-flex; flex: none; justify-content: center; width: var(--euiSheetAddPlus, 0px); }
.euiSheet__addPinnedText { margin-inline-start: 6px; }
.euiSheet__addPinned--inline { gap: 4px; padding-inline-start: 6px; }
.euiSheet__addPinned--inline .euiSheet__addPinnedPlus { width: auto; }
.euiSheet__addPinned--inline .euiSheet__addPinnedText { margin-inline-start: 0; }
.euiSheet--pinAddRow .euiDataGridRow.euiSheet__addRow > .euiDataGridRowCell:first-child { position: sticky !important; left: 0 !important; float: left; width: max-content !important; min-width: var(--euiSheetGroupMin, 0px); z-index: 2; }
.euiSheet--pinAddRow .euiDataGridRow.euiSheet__addRow > .euiDataGridRowCell:first-child .euiSheet__addPinned { display: flex; }
.euiSheet--pinAddRow .euiDataGridRow.euiSheet__addRow .euiSheet__rowAdd, .euiSheet--pinAddRow .euiDataGridRow.euiSheet__addRow .euiSheet__addRecord { visibility: hidden; }
.euiSheet .euiDataGridRow.euiSheet__addRow .euiDataGridRowCell:focus { outline: 3px solid var(--euiSheet-primary, #0B64DD); outline-offset: -3px; box-shadow: none; }
.euiSheet .euiSheet__rowCell--add [data-datagrid-cellcontent] { justify-content: center; height: 100%; }
/* field management (V03 batch 2): the "+" column's header (a hover tint, the 3 px ring under the keyboard), its inert body cells, the field editor's panel, the header menu's Delete in the danger colour after a line */
.euiSheet__srOnly { position: absolute; width: 1px; height: 1px; margin: -1px; padding: 0; overflow: hidden; clip: rect(0 0 0 0); white-space: nowrap; border: 0; }
.euiSheet .euiDataGridHeaderCell.euiSheet__addFieldHeader { cursor: pointer; padding: 0; }
.euiSheet .euiDataGridHeaderCell.euiSheet__addFieldHeader > div { width: 100%; height: 100%; }
.euiSheet__addField { display: flex; align-items: center; justify-content: center; width: 100%; height: 100%; min-height: 24px; color: var(--euiSheet-textSubdued, #69707D); }
.euiSheet .euiDataGridHeaderCell.euiSheet__addFieldHeader:hover { background-color: var(--euiSheet-checked, rgba(11, 100, 221, 0.06)); }
.euiSheet .euiDataGridHeaderCell.euiSheet__addFieldHeader:hover .euiSheet__addField, .euiSheet .euiDataGridHeaderCell.euiSheet__addFieldHeader:focus .euiSheet__addField, .euiSheet--addingField .euiSheet__addField { color: var(--euiSheet-primary, #0B64DD); }
.euiSheet .euiDataGridHeader .euiDataGridHeaderCell.euiSheet__addFieldHeader:focus, .euiSheet .euiDataGridHeader .euiDataGridHeaderCell.euiSheet__addFieldHeader:focus-visible { outline: 3px solid var(--euiSheet-primary, #0B64DD); outline-offset: -3px; }
.euiSheet .euiDataGridHeader .euiDataGridHeaderCell.euiSheet__addFieldHeader:focus::after, .euiSheet .euiDataGridHeader .euiDataGridHeaderCell.euiSheet__addFieldHeader::after { content: none; }
.euiSheet--addingField .euiDataGridHeaderCell.euiSheet__addFieldHeader { background-color: var(--euiSheet-selected, rgba(11, 100, 221, 0.12)); box-shadow: inset 0 -3px 0 var(--euiSheet-primary, #0B64DD); }
.euiSheet .euiDataGridRow .euiDataGridRowCell[data-gridcell-column-id="euiSheet-addField"] { cursor: default; }
.euiSheet__fieldEditor { position: absolute; z-index: 5; box-sizing: border-box; width: 320px; max-width: calc(100vw - 16px); }
.euiSheet__fieldEditor > div > .euiPanel { max-height: var(--euiSheetLayerMaxHeight, none); overflow-y: auto; }
.euiSheet__fieldEditor > div > .euiPanel { box-shadow: 0 4px 12px var(--euiSheet-elevation, rgba(0, 0, 0, 0.25)); border: 1px solid var(--euiSheet-border, #D3DAE6); }
.euiSheetFieldEditor__form { display: flex; flex-direction: column; gap: 8px; }
.euiSheetFieldEditor__form .euiFormRow + .euiFormRow { margin-top: 0; }
.euiSheetFieldEditor__title { margin: 0 0 4px; font-size: 14px; line-height: 20px; font-weight: 600; color: var(--euiSheet-text, #343741); }
.euiSheetFieldEditor__confirm { margin: 0; font-size: 14px; line-height: 20px; color: var(--euiSheet-text, #343741); }
.euiSheetFieldEditor__options { margin: 0; padding: 0; border: 0; min-width: 0; display: flex; flex-direction: column; gap: 6px; }
.euiSheetFieldEditor__options > .euiButtonEmpty { align-self: flex-start; }
.euiSheetFieldEditor__legend { padding: 0; margin-bottom: 4px; font-size: 12px; line-height: 16px; font-weight: 600; color: var(--euiSheet-text, #343741); }
.euiSheetFieldEditor__option { display: grid; grid-template-columns: 14px minmax(0, 1fr) 96px 24px; align-items: center; gap: 6px; }
.euiSheetFieldEditor__swatch.euiBadge { width: 14px; height: 14px; min-width: 0; padding: 0; margin: 0; border-radius: 50%; }
.euiSheetFieldEditor__optionRow { display: flex; gap: 8px; align-items: flex-end; }
.euiSheetFieldEditor__optionRow > .euiFormRow { flex: 1; margin: 0; }
.euiSheetFieldEditor__actions { display: flex; justify-content: flex-end; gap: 8px; margin-top: 4px; }
/* the header menu is portaled (no sheet theme class): EUI's own --eui-color-* variables, with neutral fallbacks; the line goes before the first field item */
li:has([data-test-subj^="euiSheetEditField-"]), li:has([data-test-subj^="euiSheetDuplicateField-"]):not(li:has([data-test-subj^="euiSheetEditField-"]) ~ li), li:has([data-test-subj^="euiSheetInsertFieldLeft-"]):not(li:has([data-test-subj^="euiSheetEditField-"]) ~ li, li:has([data-test-subj^="euiSheetDuplicateField-"]) ~ li), li:has([data-test-subj^="euiSheetInsertFieldRight-"]):not(li:has([data-test-subj^="euiSheetEditField-"]) ~ li, li:has([data-test-subj^="euiSheetDuplicateField-"]) ~ li, li:has([data-test-subj^="euiSheetInsertFieldLeft-"]) ~ li), li:has([data-test-subj^="euiSheetDeleteField-"]) { border-top: 1px solid var(--eui-color-border-base-subdued, var(--euiSheet-border, #D3DAE6)); margin-top: 4px; padding-top: 4px; }
[data-test-subj^="euiSheetDeleteField-"], [data-test-subj^="euiSheetDeleteField-"] * { color: var(--eui-color-text-danger, var(--euiSheet-textDanger, #BD271E)) !important; }
.euiSheet .euiDataGridHeaderCell.euiSheet__frozenHeader { position: sticky; z-index: 3; background-color: inherit; }
.euiSheet .euiDataGridHeader > [data-test-subj=euiDataGridHeaderDroppable],
.euiSheet .euiDataGridHeaderCellDraggable:has(.euiSheet__frozenHeader),
.euiSheet .euiDataGridHeaderCellDraggable:has(.euiSheet__frozenHeader) > .euiDraggable__item { background-color: inherit; }
.euiSheet .euiDataGridHeaderCellDraggable:has(.euiSheet__frozenHeader) { position: sticky; z-index: 3; }
.euiSheet--scrolledX .euiSheet__frozenEdge { box-shadow: 4px 0 4px -2px var(--euiSheet-shadow, rgba(0, 0, 0, 0.2)); }
.euiSheet--scrolledX .euiSheet__frozenEdge.euiSheet__cell--invalid { box-shadow: inset 0 0 0 1px var(--euiSheet-danger, #BD271E), 4px 0 4px -2px var(--euiSheet-shadow, rgba(0, 0, 0, 0.2)); }
.euiSheet__chips, .euiSheet__people, .euiSheet__files { display: inline-flex; align-items: center; gap: 4px; max-width: 100%; overflow: hidden; white-space: nowrap; vertical-align: middle; }
.euiSheet__chips .euiBadge { min-width: 0; flex-shrink: 1; margin: 0; }
.euiSheet__more { flex-shrink: 0; font-size: 12px; color: var(--euiSheet-textSubdued, #69707D); }
.euiSheet__person { display: inline-flex; align-items: center; gap: 4px; min-width: 0; }
.euiSheet__personName, .euiSheet__fileName { overflow: hidden; text-overflow: ellipsis; }
.euiSheet__thumb { flex-shrink: 0; width: 24px; height: 24px; object-fit: cover; border: 1px solid var(--euiSheet-border, #D3DAE6); border-radius: 3px; vertical-align: middle; }
.euiSheet__file { display: inline-flex; align-items: center; gap: 2px; min-width: 0; max-width: 120px; }
.euiSheet__rating { display: inline-flex; gap: 1px; line-height: 1; }
/* an empty star (V03 batch 2): the subdued text at half strength; the border colour was 1.2:1 on white */
.euiSheet__star { color: var(--euiSheet-textSubdued, #69707D); opacity: 0.45; font-size: 16px; cursor: pointer; }
.euiSheet__star.euiSheet__star--on { opacity: 1; }
.euiSheet__star--on { color: var(--euiSheet-star, #F5A700); }
.euiSheet__link { color: var(--euiSheet-link, #0B64DD); text-decoration: underline; cursor: pointer; }
.euiSheet__longText { white-space: pre-line; }
.euiSheet .euiDataGridRowCell.euiSheet__cell--pending { color: var(--euiSheet-textSubdued, #69707D); font-style: italic; }
/* files dragged over an attachment cell (V03 batch 2): the active ring's 3 px and the range tint */
.euiSheet .euiDataGridRow .euiDataGridRowCell.euiSheet__cell--dropTarget { outline: 3px solid var(--euiSheet-primary, #0B64DD); outline-offset: -3px; background-color: var(--euiSheet-selected, rgba(11, 100, 221, 0.12)); background-image: none; }
.euiSheet__editor--expand { z-index: 3; }
.euiSheet__textarea { display: block; box-sizing: border-box; width: 100%; min-height: inherit; max-height: 240px; margin: 0; padding: 6px; border: 2px solid var(--euiSheet-primary, #0B64DD); background: var(--euiSheet-plain, #FFF); color: var(--euiSheet-text, #343741); font: inherit; line-height: 1.4; resize: none; overflow-y: auto; }
.euiSheet__editor--inline .euiSheet__textarea { min-height: 88px; border-radius: 4px; }
.euiSheet__attachments { outline: none; }
.euiSheet__attachment { display: flex; align-items: center; gap: 8px; padding: 2px 0 6px; }
.euiSheet__attachmentName { flex: 1; min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; color: var(--euiSheet-link, #0B64DD); }
.euiSheet__attachmentError { margin-top: 4px; font-size: 12px; line-height: 16px; color: var(--euiSheet-textDanger, #BD271E); }
.euiSheetRecord__box--withLink { display: inline-block; width: calc(100% - 36px); vertical-align: top; }
.euiSheetRecord__openLink { margin-left: 4px; vertical-align: top; }
.euiSheet { touch-action: manipulation; }
/* the fill handle (V03 batch 1): a 10 px square in a 2 px ring, 14 px drawn, centred on the range's corner (FILL_HANDLE_SIZE); a 16 px hit area; above the range outline */
.euiSheet__fillHandle { position: absolute; z-index: 4; box-sizing: content-box; width: 10px; height: 10px; border: 2px solid var(--euiSheet-plain, #FFF); background: var(--euiSheet-primary, #0B64DD); cursor: crosshair; transition: transform 80ms ease-out; }
.euiSheet__fillHandle::before { content: ''; position: absolute; top: 50%; left: 50%; width: 16px; height: 16px; transform: translate(-50%, -50%); }
.euiSheet__fillHandle:hover { transform: scale(1.2); }
.euiSheet__rangeClip { position: absolute; z-index: 3; overflow: hidden; pointer-events: none; }
/* the range outline: 3 px inside the range's box, so on the range's edge it covers the active cell's 3 px ring exactly */
.euiSheet__range { position: absolute; box-sizing: border-box; border: 3px solid var(--euiSheet-primary, #0B64DD); pointer-events: none; }
.euiSheet--filling, .euiSheet--filling * { cursor: crosshair; }
.euiSheet--filling .euiSheet__fillHandle { pointer-events: none; }
.euiSheet .euiDataGridRowCell.euiSheet__cell--fillPreview { outline: 1px dashed var(--euiSheet-primary, #0B64DD); outline-offset: -2px; }
.euiSheet__ime { position: absolute; top: 0; left: 0; z-index: -1; width: 1px; height: 1px; margin: 0; padding: 0; border: 0; opacity: 0; pointer-events: none; }
.euiSheet__ime.euiSheet__ime--active { z-index: 2; padding: 0 6px; border: 2px solid var(--euiSheet-primary, #0B64DD); opacity: 1; pointer-events: auto; }
/* group header rows (V03 8.4, 9.1): one opaque background on every cell, hover included, no inner dividers (the grid frame's outer left and right edges stay, as on the add row), no outline or grid ::after of a cell (the row draws one ring); the row's first rendered cell carries the label, sticky at the left edge and as wide as the label (!important: over the grid's inline position, left and width; only here); the other cells show their summary */
.euiSheet .euiDataGridRow.euiSheet__groupRow > .euiDataGridRowCell, .euiSheet .euiDataGridRow.euiSheet__groupRow:hover > .euiDataGridRowCell { background-color: var(--euiSheet-group, #ECF1F9); background-image: none; color: var(--euiSheet-text, #343741); cursor: default; }
.euiSheet .euiDataGridRow.euiSheet__groupRow > .euiDataGridRowCell:not(.euiDataGridRowCell--lastColumn) { border-inline-end-color: transparent; }
.euiSheet .euiDataGridRow.euiSheet__groupRow > .euiDataGridRowCell:not(.euiDataGridRowCell--firstColumn) { border-inline-start-color: transparent; }
.euiSheet .euiDataGridRow.euiSheet__groupRow > .euiDataGridRowCell:focus, .euiSheet .euiDataGridRow.euiSheet__groupRow > .euiDataGridRowCell:focus-visible { outline: none; box-shadow: none; }
.euiSheet .euiDataGridRow.euiSheet__groupRow > .euiDataGridRowCell::after { content: none; }
.euiSheet .euiDataGridRow.euiSheet__groupRow > .euiDataGridRowCell:first-child { position: sticky !important; left: 0 !important; float: left; width: max-content !important; min-width: var(--euiSheetGroupMin, 0px); max-width: var(--euiSheetGroupMax, none); z-index: 2; }
.euiSheet .euiDataGridRow.euiSheet__groupRow > .euiDataGridRowCell:not(:first-child) .euiSheet__groupLabel, .euiSheet .euiDataGridRow.euiSheet__groupRow > .euiDataGridRowCell:first-child .euiSheet__groupSummary { display: none; }
.euiSheet .euiDataGridRow.euiSheet__groupRow:focus-within::after { content: ''; position: absolute; inset: 0; z-index: 3; pointer-events: none; outline: 2px solid var(--euiSheet-primary, #0B64DD); outline-offset: -2px; }
.euiSheet__groupLabel { display: inline-flex; align-items: center; gap: 8px; min-width: 0; max-width: 100%; overflow: hidden; white-space: nowrap; font-weight: 600; }
.euiSheet__groupTitle { overflow: hidden; text-overflow: ellipsis; }
.euiSheet__groupCount, .euiSheet__groupContinued { flex: none; font-weight: 400; color: var(--euiSheet-textSubdued, #69707D); }
/* the toggle (V03 8.3): a chevron and the title; hover tints the chevron's box, the row's focus colours it */
.euiSheet__groupToggle { display: inline-flex; flex: none; align-items: center; justify-content: center; width: 20px; height: 20px; margin-inline-end: -4px; border-radius: 4px; color: var(--euiSheet-textSubdued, #69707D); cursor: pointer; }
.euiSheet__groupToggle:hover { background-color: var(--euiSheet-selected, rgba(11, 100, 221, 0.12)); color: var(--euiSheet-primary, #0B64DD); }
.euiSheet .euiSheet__groupRow:focus-within .euiSheet__groupToggle { color: var(--euiSheet-primary, #0B64DD); }
.euiSheet__groupTitle[data-eui-sheet-group-toggle] { cursor: pointer; }
.euiSheet__groupTitle[data-eui-sheet-group-toggle]:hover { text-decoration: underline; }
.euiSheet__groupSummary { display: block; width: 100%; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; text-align: end; color: var(--euiSheet-textSubdued, #69707D); }
/* row colours (V03 10.2): a 4 px bar at the row's left edge, kept with the cell's own inset shadows */
.euiSheet .euiDataGridRowCell.euiSheet__rowColor { box-shadow: inset 4px 0 0 var(--euiSheetRowColor); }
.euiSheet .euiDataGridRowCell.euiSheet__rowColor.euiSheet__rowCell--selected, .euiSheet .euiDataGridRow:hover .euiDataGridRowCell.euiSheet__rowColor.euiSheet__rowCell--selected { box-shadow: inset 4px 0 0 var(--euiSheetRowColor), inset -3px 0 0 var(--euiSheet-primary, #0B64DD); }
.euiSheet .euiDataGridRowCell.euiSheet__rowColor.euiSheet__cell--invalid { box-shadow: inset 4px 0 0 var(--euiSheetRowColor), inset 0 0 0 1px var(--euiSheet-danger, #BD271E); }
.euiSheet--scrolledX .euiDataGridRowCell.euiSheet__rowColor.euiSheet__frozenEdge { box-shadow: inset 4px 0 0 var(--euiSheetRowColor), 4px 0 4px -2px var(--euiSheet-shadow, rgba(0, 0, 0, 0.2)); }
.euiSheet__rowColor--primary { --euiSheetRowColor: var(--euiSheet-rowPrimary, #0B64DD); }
.euiSheet__rowColor--accent { --euiSheetRowColor: var(--euiSheet-rowAccent, #BC1E70); }
.euiSheet__rowColor--success { --euiSheetRowColor: var(--euiSheet-rowSuccess, #008A5E); }
.euiSheet__rowColor--warning { --euiSheetRowColor: var(--euiSheet-rowWarning, #FACB3D); }
.euiSheet__rowColor--danger { --euiSheetRowColor: var(--euiSheet-rowDanger, #BD271E); }
.euiSheet__rowColor--neutral { --euiSheetRowColor: var(--euiSheet-rowNeutral, #69707D); }
/* button cells (V03 10.3.1): an EuiButtonEmpty-like span; the sheet presses it */
.euiSheet__button { display: inline-flex; align-items: center; gap: 4px; max-width: 100%; box-sizing: border-box; padding: 0 6px; border-radius: 4px; color: var(--euiSheet-link, #0B64DD); font-weight: 500; line-height: 22px; cursor: pointer; white-space: nowrap; }
.euiSheet__button:hover { background-color: var(--euiSheet-selected, rgba(11, 100, 221, 0.12)); text-decoration: underline; }
.euiSheet__buttonText { overflow: hidden; text-overflow: ellipsis; }
.euiSheet__button--success { color: var(--euiSheet-textSuccess, #00805B); }
.euiSheet__button--warning { color: var(--euiSheet-star, #8A6A0A); }
.euiSheet__button--danger { color: var(--euiSheet-textDanger, #BD271E); }
.euiSheet__button--text { color: var(--euiSheet-text, #343741); }
.euiSheet__button.euiSheet__button--disabled { color: var(--euiSheet-textSubdued, #69707D); cursor: default; opacity: 0.6; }
.euiSheet__button.euiSheet__button--disabled:hover { background-color: transparent; text-decoration: none; }
.euiSheet__button[aria-busy] { cursor: progress; }
/* barcode cells and the scan panel (V03 10.3.2) */
.euiSheet__barcode { display: inline-flex; align-items: center; gap: 6px; max-width: 100%; }
.euiSheet__barcodeMark { flex: none; width: 12px; height: 12px; opacity: 0.7; background: repeating-linear-gradient(90deg, currentColor 0 1px, transparent 1px 2px, currentColor 2px 4px, transparent 4px 5px); }
.euiSheet__barcodeText { overflow: hidden; text-overflow: ellipsis; font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace; }
.euiSheet__barcodeEditor { position: relative; height: 100%; }
.euiSheet__barcodeEditor .euiSheet__input { padding-right: 28px; }
.euiSheet__scanButton { position: absolute; top: 50%; right: 4px; transform: translateY(-50%); }
.euiSheet__scan { position: absolute; top: 100%; left: 0; z-index: 3; box-sizing: border-box; display: flex; flex-direction: column; gap: 6px; width: max(100%, 260px); margin-top: 4px; padding: 8px; border: 1px solid var(--euiSheet-border, #D3DAE6); border-radius: 6px; background: var(--euiSheet-plain, #FFF); color: var(--euiSheet-text, #343741); box-shadow: 0 4px 12px var(--euiSheet-elevation, rgba(0, 0, 0, 0.25)); }
.euiSheet__scanTitle { font-weight: 600; }
.euiSheet__scanVideo { width: 100%; max-height: 180px; border-radius: 4px; background: var(--euiSheet-subdued, #F7F8FC); object-fit: cover; }
.euiSheet__scanVideo.euiSheet__scanVideo--off { display: none; }
.euiSheet__scanError { color: var(--euiSheet-textDanger, #BD271E); }
/* row drag (V03 10.1): the grip, the moved rows, the insertion line */
.euiSheet__rowGrip { display: inline-flex; flex: none; margin-right: 2px; color: var(--euiSheet-textSubdued, #69707D); cursor: grab; visibility: hidden; }
.euiSheet .euiDataGridRow:hover .euiSheet__rowGrip, .euiSheet__rowCell:focus .euiSheet__rowGrip, .euiSheet--rowDragging .euiSheet__rowCell--moving .euiSheet__rowGrip { visibility: visible; }
.euiSheet__rowGrip:hover { color: var(--euiSheet-primary, #0B64DD); }
.euiSheet .euiDataGridRowCell.euiSheet__rowCell--moving [data-datagrid-cellcontent] { opacity: 0.45; }
.euiSheet--rowDragging, .euiSheet--rowDragging * { cursor: grabbing !important; }
.euiSheet--rowDragBlocked, .euiSheet--rowDragBlocked * { cursor: not-allowed !important; }
.euiSheet__dropLine { position: absolute; z-index: 5; box-sizing: border-box; height: 2px; margin-top: -1px; background: var(--euiSheet-primary, #0B64DD); pointer-events: none; }
.euiSheet__dropLine.euiSheet__dropLine--box { margin-top: 0; background: transparent; border: 2px solid var(--euiSheet-primary, #0B64DD); }
.euiSheet__dropLine.euiSheet__dropLine--blocked { background: var(--euiSheet-danger, #BD271E); }
.euiSheet__dropLine.euiSheet__dropLine--box.euiSheet__dropLine--blocked { background: transparent; border-color: var(--euiSheet-danger, #BD271E); }
@media (pointer: coarse) { .euiSheet__fillHandle { display: none; } }
@media (hover: none) {
  .euiSheet__rowGrip { visibility: visible; }
  .euiSheet__opener, .euiSheet__rowExpand { visibility: visible; }
  .euiSheet__rowCheck { display: inline-block; }
  .euiSheet__opener::after, .euiSheet__rowExpand::after, .euiSheet__rowCheck::before { content: ''; position: absolute; top: 50%; left: 50%; width: 32px; height: 32px; transform: translate(-50%, -50%); }
  .euiSheet__rowExpand, .euiSheet__rowCheck { position: relative; }
  .euiSheet [role=gridcell] { -webkit-touch-callout: none; }
}
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
    // with column drag the cell's parent is the draggable wrapper, exactly
    // its size: the wrapper is what sticks (V03 5.3)
    rules.push(
      `.euiSheet .euiDataGridHeaderCellDraggable:has(.euiSheet__frozenHeader--${i}) { left: var(--euiSheetFrozenLeft-${i}, 0px); }`
    );
  }
  return rules.join('\n');
}

/**
 * The headers of the selection's columns (V03 batch 1), as a rule for this
 * sheet only (`[data-eui-sheet-id]`), rendered in the sheet's own
 * `<style>`: the header cells are the grid's and take no class from the
 * sheet. `'columns'`: whole columns selected (the selection tint, a 3 px
 * bar at the bottom, the title in primary); `'cells'`: the light mark of a
 * cell range's columns. Drawn as an image over the header's own
 * background, so a frozen (sticky) header stays opaque.
 */
export function headerMarkRules(
  sheetId: string,
  colIndexes: number[],
  kind: 'columns' | 'cells'
): string {
  if (!colIndexes.length) return '';
  const cells = colIndexes.map(
    (index) =>
      `.euiSheet[data-eui-sheet-id="${sheetId}"] .euiDataGridHeaderCell[data-gridcell-column-index="${index}"]`
  );
  const tint =
    kind === 'columns'
      ? 'var(--euiSheet-selected, rgba(11, 100, 221, 0.12))'
      : 'var(--euiSheet-hover, rgba(105, 112, 125, 0.06))';
  const bar =
    kind === 'columns'
      ? ' box-shadow: inset 0 -3px 0 var(--euiSheet-primary, #0B64DD);'
      : '';
  return `${cells.join(', ')} { background-image: linear-gradient(${tint}, ${tint});${bar} }
${cells.map((cell) => `${cell} .euiDataGridHeaderCell__content`).join(', ')} { color: var(--euiSheet-primary, #0B64DD); }
${cells.map((cell) => `${cell} .euiDataGridHeaderCell__button`).join(', ')} { margin-inline-start: 0; transform: none; opacity: 1; }`;
}

export function ensureStyles(): void {
  if (typeof document === 'undefined') return;
  if (document.head.querySelector('style[data-eui-sheet]')) return;
  const style = document.createElement('style');
  style.setAttribute('data-eui-sheet', '');
  style.textContent = CSS;
  document.head.appendChild(style);
}
