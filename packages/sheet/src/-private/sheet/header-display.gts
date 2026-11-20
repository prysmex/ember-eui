/** A field header with a description (V03C-DESIGN.md 3.2): moved from `components/eui-sheet.gts` as it was. */
import EuiIconTip from '@ember-eui/core/components/eui-icon-tip';

import type { ComponentLike } from '@glint/template';

/** The header of a field with a description: its label and an info tip (6.3). */
export function headerDisplay(
  label: string,
  description: string
): ComponentLike {
  return <template>
    <span class="euiSheet__headerTitle">{{label}}</span>
    <span
      class="euiSheet__headerTip"
      data-test-subj="euiSheetFieldDescription"
    ><EuiIconTip
        @content={{description}}
        @type="iInCircle"
        @size="s"
        @color="subdued"
      /></span>
  </template>;
}
