/**
 * The checkbox cell: a box drawn in CSS. Not focusable (P9): Space on the
 * cell (the type's navKey) or a click on the box toggles it.
 */
import Component from '@glimmer/component';
import { on } from '@ember/modifier';

import type { SheetCellSignature } from '../../types.ts';

export default class CheckboxCell extends Component<
  SheetCellSignature<any, any>
> {
  toggle = (): void => {
    if (!this.args.readOnly) this.args.onCommit(this.args.value !== true);
  };

  <template>
    <span
      class="euiSheet__checkbox {{if @value 'euiSheet__checkbox--checked'}}"
      role="img"
      aria-label={{@text}}
      data-test-subj="euiSheetCheckbox"
      {{on "click" this.toggle}}
    ></span>
  </template>
}
