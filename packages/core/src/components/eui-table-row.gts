import { on } from '@ember/modifier';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** A row of an `EuiTable` body. */
export interface EuiTableRowSignature {
  Element: HTMLTableRowElement;
  Args: {
    /** Highlights the row as selected. */
    isSelected?: boolean;
    /** The row has a selection checkbox. */
    isSelectable?: boolean;
    /** The row has an actions cell (with `@hasActions` on the cell). */
    hasActions?: boolean;
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

function classes(
  isSelectable?: boolean,
  isSelected?: boolean,
  hasActions?: boolean,
  isExpandedRow?: boolean,
  isExpandable?: boolean,
  isClickable?: boolean
): string {
  return [
    'euiTableRow',
    isSelectable && 'euiTableRow-isSelectable',
    isSelected && 'euiTableRow-isSelected',
    hasActions && 'euiTableRow-hasActions',
    isExpandedRow && 'euiTableRow-isExpandedRow',
    isExpandable && 'euiTableRow-isExpandable',
    isClickable && 'euiTableRow-isClickable'
  ]
    .filter(Boolean)
    .join(' ');
}

// Space would scroll the page: prevent it, and click on key up
function preventSpace(event: KeyboardEvent): void {
  if (event.key === ' ') event.preventDefault();
}

function clickOnKey(onClick: (event: Event) => void): (event: KeyboardEvent) => void {
  return (event) => {
    if (event.key === 'Enter' || event.key === ' ') onClick(event);
  };
}

const EuiTableRow: TemplateOnlyComponent<EuiTableRowSignature> = <template>
  {{#if @onClick}}
    <tr
      class={{classes
        @isSelectable
        @isSelected
        @hasActions
        @isExpandedRow
        @isExpandable
        true
      }}
      tabindex="0"
      {{on "click" @onClick}}
      {{on "keydown" preventSpace}}
      {{on "keyup" (clickOnKey @onClick)}}
      ...attributes
    >{{yield}}</tr>
  {{else}}
    <tr
      class={{classes
        @isSelectable
        @isSelected
        @hasActions
        @isExpandedRow
        @isExpandable
        false
      }}
      ...attributes
    >{{yield}}</tr>
  {{/if}}
</template>;

export default EuiTableRow;
