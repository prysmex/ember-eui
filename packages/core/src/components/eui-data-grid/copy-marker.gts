import { CHARS } from '../../utils/data-grid/tabular-copy.ts';

import type { TOC } from '@ember/component/template-only';
import type EuiDataGrid from '../eui-data-grid.gts';

export type CopyMarkerType = 'tab' | 'newline' | 'boundary' | 'no-copy';

const MARKER_CHARS: Record<CopyMarkerType, string> = {
  tab: CHARS.TAB,
  newline: CHARS.NEWLINE,
  boundary: CHARS.TABULAR_CONTENT_BOUND,
  'no-copy': CHARS.NO_COPY_BOUND
};

const markerChar = (type: CopyMarkerType): string => MARKER_CHARS[type];

/**
 * Upstream `tabularCopyMarkers`: a character hidden from sighted users and
 * screen readers (not `hidden`, which would drop it from the clipboard too)
 * that `onTabularCopy` turns into a tab/newline or uses as a bound.
 */
const EuiDataGridCopyMarker: TOC<{
  Args: { grid: EuiDataGrid; type: CopyMarkerType };
}> = <template><span
    class={{@grid.copyMarkerClass}}
    aria-hidden="true"
    data-tabular-copy-marker={{@type}}
  >{{markerChar @type}}</span></template>;

export default EuiDataGridCopyMarker;
