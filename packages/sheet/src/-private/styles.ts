/**
 * The sheet's few styles, added once to `document.head` (one
 * `<style data-eui-sheet>` per page, not one per sheet). Fixed colours in
 * v0.1; theming with EUI tokens is later (PACKAGE-DESIGN.md Q5).
 */
const CSS = `
.euiSheet { position: relative; }
.euiSheet__cell--selected { background: rgba(0, 119, 204, 0.12); }
.euiSheet__cell--invalid { color: #BD271E; box-shadow: inset 0 0 0 1px #BD271E; }
.euiSheet__editor { position: absolute; box-sizing: border-box; }
.euiSheet__editor--cell { z-index: 2; }
.euiSheet__editor--panel { z-index: 3; }
.euiSheet__input { display: block; box-sizing: border-box; width: 100%; height: 100%; margin: 0; padding: 0 6px; border: 2px solid #0B64DD; font: inherit; }
.euiSheet__checkbox { display: inline-block; box-sizing: border-box; width: 14px; height: 14px; vertical-align: middle; border: 1px solid #69707D; border-radius: 3px; background: #FFF; position: relative; cursor: pointer; }
.euiSheet__checkbox--checked { background: #0B64DD; border-color: #0B64DD; }
.euiSheet__checkbox--checked::after { content: ''; position: absolute; left: 4px; top: 1px; width: 4px; height: 8px; border: solid #FFF; border-width: 0 2px 2px 0; transform: rotate(45deg); }
`;

export function ensureStyles(): void {
  if (typeof document === 'undefined') return;
  if (document.head.querySelector('style[data-eui-sheet]')) return;
  const style = document.createElement('style');
  style.setAttribute('data-eui-sheet', '');
  style.textContent = CSS;
  document.head.appendChild(style);
}
