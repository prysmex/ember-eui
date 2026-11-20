import EuiIcon from '@ember-eui/core/components/eui-icon';
import type { TOC } from '@ember/component/template-only';

/**
 * The add row's "+ Add record" while the grid is scrolled sideways: every
 * add-row cell renders it while pinned (`pinsAddRow`; at rest the add
 * row's DOM is unchanged), and CSS shows it only in the row's first
 * rendered cell, made sticky and wide like a group header (V03 9.1), so it
 * stays at the left edge when the row-number cell and the first field
 * scroll away or unmount. The plus sits in a box as wide as the row-number
 * column (`--euiSheetAddPlus`, 0 without row numbers: then it is inline).
 */
const AddPinned: TOC<{ Args: { label: string; inline: boolean } }> = <template>
  <span
    class="euiSheet__addPinned {{if @inline 'euiSheet__addPinned--inline'}}"
    data-test-subj="euiSheetAddPinned"
    aria-hidden="true"
  >
    <span class="euiSheet__addPinnedPlus"><EuiIcon
        @type="plus"
        @size="s"
      /></span>
    <span class="euiSheet__addPinnedText">{{@label}}</span>
  </span>
</template>;

export default AddPinned;
