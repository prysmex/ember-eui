import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiKeyPadMenuStyles } from '../utils/eui/styles.generated.ts';
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
     * Makes the menu a `<fieldset>` of radios or checkboxes (items with
     * `@checkable`): `true`, or `{ legend }` for a visible legend and/or
     * `{ ariaLegend }` for an `aria-label`.
     */
    checkable?:
      | boolean
      | {
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

/** Scoped stand-in for React's global list/fieldset reset. */
const RESET = {
  boxSizing: 'border-box' as const,
  margin: 0,
  padding: 0,
  border: 0,
  minInlineSize: 0,
  listStyle: 'none',
  '& > li': { margin: 0, padding: 0 }
};

/** Native Ember key pad menu using the upstream EUI 123 / Borealis factory. */
export default class EuiKeyPadMenu extends Component<EuiKeyPadMenuSignature> {
  Key = KeyComponent;

  get context() {
    return getEuiThemeContext(this);
  }

  @cached
  get styles() {
    return useEuiBorealisStyles(this.context, euiKeyPadMenuStyles);
  }

  get isCheckable(): boolean {
    return Boolean(this.args.checkable);
  }

  get legend(): string | undefined {
    const { checkable } = this.args;
    return typeof checkable === 'object' ? checkable.legend : undefined;
  }

  get ariaLegend(): string | undefined {
    const { checkable } = this.args;
    return typeof checkable === 'object' ? checkable.ariaLegend : undefined;
  }

  @cached
  get classes(): string {
    return `euiKeyPadMenu ${euiClass(this.context, RESET, this.styles.euiKeyPadMenu)}`;
  }

  @cached
  get legendClass(): string {
    return euiClass(this.context, this.styles.euiKeyPadMenu__legend);
  }

  <template>
    {{#if this.isCheckable}}
      <fieldset class={{this.classes}} aria-label={{this.ariaLegend}} ...attributes>
        {{#if this.legend}}
          <EuiFormLabel @type="legend" class={{this.legendClass}}>
            {{this.legend}}
          </EuiFormLabel>
        {{/if}}
        {{yield}}
      </fieldset>
    {{else}}
      <ul class={{this.classes}} ...attributes>
        {{yield this.Key}}
      </ul>
    {{/if}}
  </template>
}
