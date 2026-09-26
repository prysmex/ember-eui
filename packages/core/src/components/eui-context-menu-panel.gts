import type { TemplateOnlyComponent } from '@ember/component/template-only';

/**
 * A list of `EuiContextMenuItem`s, usually as a popover's content. Unlike
 * EUI's React version it has no built-in panel navigation.
 */
export interface EuiContextMenuPanelSignature {
  Element: HTMLDivElement;
  Blocks: {
    /** The `EuiContextMenuItem`s (and e.g. `EuiHorizontalRule`s). */
    default: [];
  };
}

const EuiContextMenuPanel: TemplateOnlyComponent<EuiContextMenuPanelSignature> =
  <template>
    {{! ToDo not yet implemented, only created to avoid creating divs with euiContextMenuPanel class }}

    <div class="euiContextMenuPanel" tabindex="-1" ...attributes>
      {{yield}}
    </div>
  </template>;

export default EuiContextMenuPanel;
