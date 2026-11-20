/**
 * The button cell (V03 10.3.1): an `EuiButtonEmpty`-styled span with
 * `role="button"` and `data-eui-sheet-button` (no tabbable element in a
 * cell, P9; no `tabindex` either, so a click leaves focus on the cell).
 * The sheet presses it on a click on the span, or Enter / Space on the
 * selected cell. While the app's promise is pending a spinner takes the
 * icon's place.
 */
import Component from '@glimmer/component';

import EuiIcon from '@ember-eui/core/components/eui-icon';
import EuiLoadingSpinner from '@ember-eui/core/components/eui-loading-spinner';

import type { ButtonField } from '../../core/index.ts';
import type { SheetCellSignature } from '../../types.ts';

const COLORS = new Set(['primary', 'success', 'warning', 'danger', 'text']);

export default class ButtonCell extends Component<
  SheetCellSignature<null, ButtonField>
> {
  get color(): string {
    const color = this.args.field.color;
    return typeof color === 'string' && COLORS.has(color) ? color : 'primary';
  }

  get icon(): string | undefined {
    const icon = this.args.field.icon;
    return typeof icon === 'string' ? icon : undefined;
  }

  <template>
    <span
      class="euiSheet__button euiSheet__button--{{this.color}}
        {{if @disabled 'euiSheet__button--disabled'}}"
      role="button"
      aria-disabled={{if @disabled "true"}}
      aria-busy={{if @pending "true"}}
      data-eui-sheet-button
      data-test-subj="euiSheetButton"
    >{{#if @pending}}<EuiLoadingSpinner
          @size="s"
          data-test-subj="euiSheetButtonPending"
        />{{else if this.icon}}<EuiIcon
          @type={{this.icon}}
          @size="s"
          aria-hidden="true"
        />{{/if}}<span class="euiSheet__buttonText">{{@text}}</span></span>
  </template>
}
