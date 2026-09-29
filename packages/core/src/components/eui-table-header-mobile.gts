import type { TemplateOnlyComponent } from '@ember/component/template-only';

/**
 * A bar shown above a responsive `EuiTable` on small screens (where the
 * header row is hidden), e.g. with "select all" and `EuiTableSortMobile`.
 */
export interface EuiTableHeaderMobileSignature {
  Element: HTMLDivElement;
  Blocks: {
    /** The controls. */
    default: [];
  };
}

const EuiTableHeaderMobile: TemplateOnlyComponent<EuiTableHeaderMobileSignature> = <template>
  <div class="euiTableHeaderMobile" ...attributes>{{yield}}</div>
</template>;

export default EuiTableHeaderMobile;
