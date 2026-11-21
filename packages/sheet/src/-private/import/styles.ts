/**
 * The import screen's styles (v0.4 10), added once to `document.head` in
 * their own `<style data-eui-sheet-import>`, so the sheet's styles do not
 * carry them. Colours are the sheet's `--euiSheet-*` properties, which the
 * screen's root defines from the EUI theme (`theme.ts`).
 */
const CSS = `
.euiSheetImport { display: flex; flex-direction: column; gap: 16px; color: var(--euiSheet-text, #343741); font-size: 14px; line-height: 20px; min-width: 0; }
.euiSheetImport__section { display: flex; flex-direction: column; gap: 8px; min-width: 0; }
.euiSheetImport__title { margin: 0; font-size: 16px; line-height: 24px; font-weight: 600; color: var(--euiSheet-text, #343741); }
.euiSheetImport__fileRow { display: flex; flex-wrap: wrap; align-items: center; gap: 8px 20px; }
.euiSheetImport__fileName { font-weight: 600; overflow-wrap: anywhere; }
.euiSheetImport__subdued { color: var(--euiSheet-textSubdued, #69707D); }
.euiSheetImport__inline { display: inline-flex; align-items: center; gap: 8px; }
.euiSheetImport__inline .euiFormControlLayout { width: auto; }
.euiSheetImport__scroll { overflow-x: auto; max-width: 100%; border: 1px solid var(--euiSheet-border, #D3DAE6); border-radius: 6px; }
.euiSheetImport__table { width: 100%; border-collapse: collapse; font-size: 13px; line-height: 18px; }
.euiSheetImport__table caption { caption-side: top; text-align: start; padding: 6px 8px; color: var(--euiSheet-textSubdued, #69707D); font-size: 12px; }
.euiSheetImport__table th { text-align: start; font-weight: 600; font-size: 12px; padding: 6px 8px; background: var(--euiSheet-subdued, #F7F8FC); border-bottom: 1px solid var(--euiSheet-border, #D3DAE6); white-space: nowrap; }
.euiSheetImport__table td { padding: 6px 8px; vertical-align: top; border-bottom: 1px solid var(--euiSheet-border, #D3DAE6); }
.euiSheetImport__table tbody tr:last-child > td { border-bottom: 0; }
.euiSheetImport__columns td { min-width: 120px; }
.euiSheetImport__columns td.euiSheetImport__colFile { min-width: 140px; max-width: 220px; }
.euiSheetImport__header { font-weight: 600; overflow-wrap: anywhere; }
.euiSheetImport__sample { display: block; max-width: 220px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; color: var(--euiSheet-textSubdued, #69707D); font-size: 12px; }
.euiSheetImport__stack { display: flex; flex-direction: column; align-items: flex-start; gap: 6px; }
.euiSheetImport__stack > .euiFormControlLayout { width: 100%; min-width: 160px; }
.euiSheetImport__note { font-size: 12px; color: var(--euiSheet-textSubdued, #69707D); }
.euiSheetImport__danger { color: var(--euiSheet-textDanger, #BD271E); }
.euiSheetImport__detail > td { background: var(--euiSheet-subdued, #F7F8FC); }
.euiSheetImport__form { max-width: 360px; }
.euiSheetImport__valueMap { width: auto; min-width: 320px; background: var(--euiSheet-plain, #FFF); border: 1px solid var(--euiSheet-border, #D3DAE6); }
.euiSheetImport__preview td { white-space: nowrap; max-width: 240px; overflow: hidden; text-overflow: ellipsis; }
.euiSheetImport__preview td.euiSheetImport__line, .euiSheetImport__preview th.euiSheetImport__line { width: 1%; color: var(--euiSheet-textSubdued, #69707D); text-align: end; }
.euiSheetImport__cell--error { color: var(--euiSheet-textDanger, #BD271E); box-shadow: inset 0 0 0 1px var(--euiSheet-danger, #BD271E); }
.euiSheetImport__cellMessage { display: block; font-size: 11px; line-height: 14px; white-space: normal; }
.euiSheetImport__cellBadge { margin-inline-start: 6px; }
.euiSheetImport__totals { display: flex; flex-wrap: wrap; align-items: center; gap: 8px 20px; }
.euiSheetImport__actions { display: flex; flex-wrap: wrap; justify-content: flex-end; gap: 8px; }
`;

export function ensureImportStyles(): void {
  if (typeof document === 'undefined') return;
  if (document.head.querySelector('style[data-eui-sheet-import]')) return;
  const style = document.createElement('style');
  style.setAttribute('data-eui-sheet-import', '');
  style.textContent = CSS;
  document.head.appendChild(style);
}
