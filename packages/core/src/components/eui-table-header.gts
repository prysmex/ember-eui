import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** The `<thead>` of an `EuiTable`, with its row of `EuiTableHeaderCell`s. */
export interface EuiTableHeaderSignature {
  Element: HTMLTableSectionElement;
  Args: {
    /** Wraps the cells in a `<tr>`. Defaults to `true`. */
    wrapWithTableRow?: boolean;
  };
  Blocks: {
    /** The header cells (or rows, without `@wrapWithTableRow`). */
    default: [];
  };
}

function wrap(value?: boolean): boolean {
  return value !== false;
}

const EuiTableHeader: TemplateOnlyComponent<EuiTableHeaderSignature> = <template>
  <thead ...attributes>
    {{#if (wrap @wrapWithTableRow)}}
      <tr>{{yield}}</tr>
    {{else}}
      {{yield}}
    {{/if}}
  </thead>
</template>;

export default EuiTableHeader;
