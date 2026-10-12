import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { on } from '@ember/modifier';

import { tableContext } from '../-private/table.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiTableRowStyles } from '../utils/eui/styles.generated.ts';

/** A row of an `EuiTable` body. */
export interface EuiTableRowSignature {
  Element: HTMLTableRowElement;
  Args: {
    /** Highlights the row as selected. */
    isSelected?: boolean;
    /**
     * The row's selection checkbox is enabled. Also reserves the cards
     * layout's checkbox column unless `@hasSelection` is given.
     */
    isSelectable?: boolean;
    /**
     * The table has a checkbox column (upstream): reserves room for it in
     * the cards layout and lines expanded rows up with the second column.
     * Defaults to `@isSelectable`.
     */
    hasSelection?: boolean;
    /**
     * The row has an actions cell (with `@hasActions` on the cell): shows
     * hover-only actions while the row is hovered; `true` reserves the
     * cards layout's right column.
     */
    hasActions?: boolean | 'custom';
    /** The row can expand (it has an expander cell). */
    isExpandable?: boolean;
    /** The row is the expanded content of the previous row. */
    isExpandedRow?: boolean;
    /** Makes the row clickable (also with Enter and Space). */
    onClick?: (event: Event) => void;
  };
  Blocks: {
    /** The cells. */
    default: [];
  };
}

// Space would scroll the page: prevent it, and click on key up
function onKeyDown(onClick?: (event: Event) => void) {
  return (event: KeyboardEvent): void => {
    if (onClick && event.key === ' ') event.preventDefault();
  };
}

function onKeyUp(onClick?: (event: Event) => void) {
  return (event: KeyboardEvent): void => {
    if (onClick && (event.key === 'Enter' || event.key === ' ')) onClick(event);
  };
}

function onRowClick(onClick?: (event: Event) => void) {
  return (event: MouseEvent): void => onClick?.(event);
}

export default class EuiTableRow extends Component<EuiTableRowSignature> {
  get hasSelection(): boolean | undefined {
    return this.args.hasSelection ?? this.args.isSelectable;
  }

  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiTableRowStyles);
    const { isResponsive, hasBackground } = tableContext(this);
    const {
      isSelected,
      isSelectable,
      hasActions,
      isExpandable,
      isExpandedRow,
      onClick
    } = this.args;
    const hasSelection = this.hasSelection;
    // Same order as upstream's `cssStyles`.
    const css = isResponsive
      ? [
          styles.euiTableRow,
          styles.mobile.mobile,
          hasBackground ? undefined : styles.mobile.hasBorder,
          hasBackground ? styles.mobile.hasBackground : undefined,
          isSelected ? styles.mobile.selected : undefined,
          isExpandedRow ? styles.mobile.expanded : undefined,
          hasActions === true || isExpandable || isExpandedRow
            ? styles.mobile.hasRightColumn
            : undefined,
          hasSelection ? styles.mobile.hasLeftColumn : undefined
        ]
      : [
          styles.euiTableRow,
          styles.desktop.desktop,
          onClick ? styles.desktop.clickable : undefined,
          isSelected ? styles.desktop.selected : undefined,
          isExpandedRow ? styles.desktop.expanded.expanded : undefined,
          isExpandedRow && hasBackground
            ? styles.desktop.expanded.hasBackground
            : undefined,
          isExpandedRow && hasSelection
            ? styles.desktop.checkboxOffset
            : undefined
        ];

    return [
      'euiTableRow',
      isSelectable && 'euiTableRow-isSelectable',
      isSelected && 'euiTableRow-isSelected',
      hasActions && 'euiTableRow-hasActions',
      isExpandedRow && 'euiTableRow-isExpandedRow',
      isExpandable && 'euiTableRow-isExpandable',
      onClick && 'euiTableRow-isClickable',
      euiClass(context, ...css)
    ]
      .filter(Boolean)
      .join(' ');
  }

  <template>
    {{! one element whether or not it is clickable, so toggling @onClick keeps it }}
    <tr
      class={{this.classes}}
      tabindex={{if @onClick "0"}}
      {{on "click" (onRowClick @onClick)}}
      {{on "keydown" (onKeyDown @onClick)}}
      {{on "keyup" (onKeyUp @onClick)}}
      ...attributes
    >{{yield}}</tr>
  </template>
}
