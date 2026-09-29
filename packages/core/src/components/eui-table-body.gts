import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** The `<tbody>` of an `EuiTable`. */
export interface EuiTableBodySignature {
  Element: HTMLTableSectionElement;
  Blocks: {
    /** The `EuiTableRow`s. */
    default: [];
  };
}

const EuiTableBody: TemplateOnlyComponent<EuiTableBodySignature> = <template>
  <tbody ...attributes>{{yield}}</tbody>
</template>;

export default EuiTableBody;
