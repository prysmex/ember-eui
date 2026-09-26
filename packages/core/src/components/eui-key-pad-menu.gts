import EuiFormLabel from './eui-form-label.gts';

import type { EuiIconSignature } from './eui-icon';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

const KeyComponent: TemplateOnlyComponent<{
  Blocks: {
    default: [];
  };
}> = <template><li>{{yield}}</li></template>;

/**
 * A grid of large square buttons (`EuiKeyPadMenuItem`s), e.g. an app
 * switcher in a header popover.
 */
export interface EuiKeyPadMenuSignature {
  Element: HTMLUListElement | HTMLFieldSetElement;
  Args: {
    /**
     * Makes the menu a group of radios or checkboxes (items with
     * `@checkable`) under a visible `legend`, or an invisible `ariaLegend`.
     */
    checkable?: {
      legend?: string;
      ariaLegend?: string;
    };
    /** @deprecated Has no effect. */
    iconType?: EuiIconSignature['Args']['type'];
  };
  Blocks: {
    /**
     * The items. Wrap each in the yielded `<Key>` (an `<li>`), except for
     * checkable menus: `as |Key|` → `<Key><EuiKeyPadMenuItem …/></Key>`.
     */
    default: [typeof KeyComponent?];
  };
}

const EuiKeyPadMenu: TemplateOnlyComponent<EuiKeyPadMenuSignature> = <template>
  {{#if @checkable.legend}}
    <fieldset
      class="euiKeyPadMenu"
      aria-label={{@checkable.ariaLegend}}
      ...attributes
    >
      <EuiFormLabel @type="legend">
        {{@checkable.legend}}
      </EuiFormLabel>
      {{yield}}
    </fieldset>
  {{else}}
    <ul class="euiKeyPadMenu" ...attributes>
      {{yield KeyComponent}}
    </ul>
  {{/if}}
</template>;

export default EuiKeyPadMenu;
