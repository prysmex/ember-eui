import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiContextMenuPanelSignature {
  Element: HTMLDivElement;
  Blocks: {
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
