import { CHARS } from '../utils/data-grid/tabular-copy.ts';

import type { TOC } from '@ember/component/template-only';

/**
 * Upstream `tabularCopyMarkers` (`services/copy/tabular_copy.tsx`): a
 * character hidden from sighted users and screen readers (not `hidden`,
 * which would drop it from the clipboard too) that `onTabularCopy` turns
 * into a tab or newline, or uses as a bound, when a selection is copied.
 */
export type TabularCopyMarkerType = 'tab' | 'newline' | 'boundary' | 'no-copy';

const MARKER_CHARS: Record<TabularCopyMarkerType, string> = {
  tab: CHARS.TAB,
  newline: CHARS.NEWLINE,
  boundary: CHARS.TABULAR_CONTENT_BOUND,
  'no-copy': CHARS.NO_COPY_BOUND
};

const markerChar = (type: TabularCopyMarkerType): string => MARKER_CHARS[type];

/** `@class` is the screen reader only class (`euiScreenReaderOnlyClass`). */
const TabularCopyMarker: TOC<{
  Args: { type: TabularCopyMarkerType; class: string };
}> = <template><span
    class={{@class}}
    aria-hidden="true"
    data-tabular-copy-marker={{@type}}
  >{{markerChar @type}}</span></template>;

export default TabularCopyMarker;
