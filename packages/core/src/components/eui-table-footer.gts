import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** The `<tfoot>` of an `EuiTable`, with a row of `EuiTableFooterCell`s. */
export interface EuiTableFooterSignature {
  Element: HTMLTableSectionElement;
  Blocks: {
    /** The footer cells. */
    default: [];
  };
}

const EuiTableFooter: TemplateOnlyComponent<EuiTableFooterSignature> = <template>
  <tfoot ...attributes><tr>{{yield}}</tr></tfoot>
</template>;

export default EuiTableFooter;
