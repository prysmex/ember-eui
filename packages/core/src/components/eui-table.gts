import type { TemplateOnlyComponent } from '@ember/component/template-only';

/**
 * A styled `<table>`, built from `EuiTableHeader`, `EuiTableHeaderCell`,
 * `EuiTableBody`, `EuiTableRow` and `EuiTableRowCell`. These components
 * only render the markup: sorting, selection and pagination stay yours
 * (or come from a headless table library).
 */
export interface EuiTableSignature {
  Element: HTMLTableElement;
  Args: {
    /** Smaller text and padding. */
    compressed?: boolean;
    /**
     * `'fixed'` (columns share the width, text wraps or truncates) or
     * `'auto'` (columns fit their content). Defaults to `'fixed'`.
     */
    tableLayout?: 'fixed' | 'auto';
    /** On small screens, rows become cards. Defaults to `true`. */
    responsive?: boolean;
  };
  Blocks: {
    /** The header, body and footer. */
    default: [];
  };
}

function classes(compressed?: boolean, tableLayout?: string, responsive?: boolean): string {
  return [
    'euiTable',
    compressed && 'euiTable--compressed',
    responsive !== false && 'euiTable--responsive',
    tableLayout === 'auto' && 'euiTable--auto'
  ]
    .filter(Boolean)
    .join(' ');
}

const EuiTable: TemplateOnlyComponent<EuiTableSignature> = <template>
  <table
    tabindex="-1"
    class={{classes @compressed @tableLayout @responsive}}
    ...attributes
  >{{yield}}</table>
</template>;

export default EuiTable;
