import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** A row cell holding a checkbox, e.g. to select the row. */
export interface EuiTableRowCellCheckboxSignature {
  Element: HTMLTableCellElement;
  Blocks: {
    /** The checkbox. */
    default: [];
  };
}

const EuiTableRowCellCheckbox: TemplateOnlyComponent<EuiTableRowCellCheckboxSignature> =
  <template>
    <td class="euiTableRowCellCheckbox" ...attributes>
      <div class="euiTableCellContent">{{yield}}</div>
    </td>
  </template>;

export default EuiTableRowCellCheckbox;
