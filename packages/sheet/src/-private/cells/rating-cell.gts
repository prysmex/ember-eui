/**
 * The rating cell: `max` star spans (`[data-eui-sheet-star="n"]`). A click
 * on star n saves n, on the current value's star clears it. Spans only (P9):
 * the keyboard sets a rating with a digit (the type's navKey).
 */
import Component from '@glimmer/component';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';

import type { SheetCellSignature } from '../../types.ts';

interface Star {
  n: number;
  on: boolean;
}

export default class RatingCell extends Component<
  SheetCellSignature<any, any>
> {
  get stars(): Star[] {
    const max = Number(this.args.field['max'] ?? 5);
    const value = typeof this.args.value === 'number' ? this.args.value : 0;
    return Array.from({ length: Math.max(0, max) }, (_, i) => ({
      n: i + 1,
      on: i + 1 <= value
    }));
  }

  pick = (n: number): void => {
    if (this.args.readOnly) return;
    this.args.onCommit(this.args.value === n ? null : n);
  };

  <template>
    <span
      class="euiSheet__rating"
      role={{if @text "img"}}
      aria-label={{if @text @text}}
      data-test-subj="euiSheetRating"
    >
      {{#each this.stars key="n" as |star|}}
        {{! template-lint-disable no-invalid-interactive }}
        <span
          class="euiSheet__star {{if star.on 'euiSheet__star--on'}}"
          data-eui-sheet-star={{star.n}}
          aria-hidden="true"
          {{on "click" (fn this.pick star.n)}}
        >★</span>
      {{/each}}
    </span>
  </template>
}
