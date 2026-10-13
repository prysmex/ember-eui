import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';

import { buttonReset } from '../-private/table.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiTableHeaderFooterCellStyles,
  euiTextTruncate
} from '../utils/eui/styles.generated.ts';
import EuiIcon from './eui-icon.gts';
import EuiInnerText from './eui-inner-text.gts';

import type { EuiIconSignature } from './eui-icon';

/**
 * A button in a header cell, e.g. a column that opens a menu. Upstream
 * removed this component; it uses the header sort button's styles
 * (full width, primary underline on hover and focus).
 */
export interface EuiTableHeaderButtonSignature {
  Element: HTMLButtonElement;
  Args: {
    /** Icon after the text, any `EuiIcon` type. */
    iconType?: EuiIconSignature['Args']['type'];
  };
  Blocks: {
    /** The text. */
    default: [];
  };
}

const TRUNCATE = euiTextTruncate();
const LAYOUT = {
  display: 'inline-flex',
  alignItems: 'center',
  maxInlineSize: '100%'
} as const;

export default class EuiTableHeaderButton extends Component<EuiTableHeaderButtonSignature> {
  @cached
  get styles() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiTableHeaderFooterCellStyles);
    return {
      button: euiClass(
        context,
        buttonReset(context.upstream),
        styles.euiTableHeaderCell__button,
        LAYOUT,
        styles.euiTableHeaderCell__content
      ),
      text: euiClass(context, TRUNCATE)
    };
  }

  <template>
    <button
      type="button"
      class="euiTableHeaderButton {{this.styles.button}}"
      ...attributes
    >
      <EuiInnerText as |ref innerText|>
        <span
          class={{this.styles.text}}
          title={{innerText}}
          {{didInsert ref}}
        >{{yield}}</span>
      </EuiInnerText>
      {{#if @iconType}}
        <EuiIcon
          class="euiTableHeaderButton__icon"
          @type={{@iconType}}
          @size="m"
          aria-hidden="true"
        />
      {{/if}}
    </button>
  </template>
}
