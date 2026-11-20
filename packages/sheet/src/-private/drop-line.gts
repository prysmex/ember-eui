/**
 * The insertion line of a row drag (V03 10.1, W6): 2 px of
 * `--euiSheet-primary` between the rows a drop goes between, or a box
 * around a collapsed group header. Placed in the wrapper's CSS px.
 */
import { htmlSafe } from '@ember/template';

import type { DropLine } from './sheet/row-drag.ts';
import type { TOC } from '@ember/component/template-only';

function lineStyle(line: DropLine) {
  const parts = [
    `top: ${line.top}px`,
    `left: ${line.left}px`,
    `width: ${line.width}px`
  ];
  if (line.height !== undefined) parts.push(`height: ${line.height}px`);
  return htmlSafe(parts.join('; '));
}

const DropLineComponent: TOC<{ Args: { line: DropLine } }> = <template>
  <div
    class="euiSheet__dropLine
      {{if @line.height 'euiSheet__dropLine--box'}}
      {{if @line.blocked 'euiSheet__dropLine--blocked'}}"
    data-test-subj="euiSheetDropLine"
    aria-hidden="true"
    style={{lineStyle @line}}
  ></div>
</template>;

export default DropLineComponent;
