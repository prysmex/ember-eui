import type { TemplateOnlyComponent } from '@ember/component/template-only';

/**
 * A bar of `EuiFilterButton`s joined in one bordered group, usually next
 * to a search field, e.g. "On / Off" toggles and a "Status" popover.
 */
export interface EuiFilterGroupSignature {
  Element: HTMLDivElement;
  Args: {
    /** Takes the container's full width instead of its content's. */
    fullWidth?: boolean;
  };
  Blocks: {
    /** The `EuiFilterButton`s (and popovers anchored on them). */
    default: [];
  };
}

const EuiFilterGroup: TemplateOnlyComponent<EuiFilterGroupSignature> = <template>
  <div
    class="euiFilterGroup {{if @fullWidth 'euiFilterGroup--fullWidth'}}"
    ...attributes
  >{{yield}}</div>
</template>;

export default EuiFilterGroup;
