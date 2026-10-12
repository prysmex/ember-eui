import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { CELL_RESET, tableContext } from '../-private/table.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiTableCellCheckboxStyles } from '../utils/eui/styles.generated.ts';

/**
 * A row cell holding a checkbox, e.g. to select the row. In the cards
 * layout it sits in the card's top left corner (give the row
 * `@hasSelection` or `@isSelectable` to reserve room for it).
 */
export interface EuiTableRowCellCheckboxSignature {
  Element: HTMLTableCellElement;
  Blocks: {
    /** The checkbox. */
    default: [];
  };
}

export default class EuiTableRowCellCheckbox extends Component<EuiTableRowCellCheckboxSignature> {
  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiTableCellCheckboxStyles);
    return euiClass(
      context,
      CELL_RESET,
      styles.euiTableRowCellCheckbox,
      tableContext(this).isResponsive ? styles.mobile : styles.desktop
    );
  }

  <template>
    <td class="euiTableRowCellCheckbox {{this.classes}}" ...attributes>
      <div class="euiTableCellContent">{{yield}}</div>
    </td>
  </template>
}

