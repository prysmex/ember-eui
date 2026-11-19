/**
 * The multi-select and linked-record cell: one EuiBadge per item (a
 * `<span>`, no `@onClick`: nothing tabbable, P9), at most three, then "+N".
 */
import Component from '@glimmer/component';

import EuiBadge from '@ember-eui/core/components/eui-badge';
import EuiHighlight from '@ember-eui/core/components/eui-highlight';

import { fieldOptions } from '../../core/index.ts';

import type { SheetCellSignature } from '../../types.ts';

/** Chips shown before "+N". */
export const MAX_CHIPS = 3;

interface Chip {
  key: string;
  label: string;
  color: string;
}

export default class ChipsCell extends Component<SheetCellSignature<any, any>> {
  get items(): unknown[] {
    return Array.isArray(this.args.value) ? this.args.value : [];
  }

  get chips(): Chip[] {
    const field = this.args.field;
    const options =
      field.type === 'multiSelect'
        ? fieldOptions(field, this.args.record)
        : null;
    return this.items.slice(0, MAX_CHIPS).map((item, i) => {
      if (options) {
        const option = options.find((o) => o.value === item);
        return {
          key: `${i}:${String(item)}`,
          label: option?.label ?? String(item),
          color: option?.color ?? 'hollow'
        };
      }
      const record = item as { id?: string | number; label?: string };
      return {
        key: `${i}:${String(record?.id)}`,
        label: record?.label ?? String(record?.id ?? ''),
        color: 'hollow'
      };
    });
  }

  get more(): number {
    return Math.max(0, this.items.length - MAX_CHIPS);
  }

  <template>
    <span class="euiSheet__chips">
      {{#each this.chips key="key" as |chip|}}
        <EuiBadge @color={{chip.color}} data-test-subj="euiSheetChip">{{#if
            @highlight
          }}<EuiHighlight
              @text={{chip.label}}
              @search={{@highlight}}
              @highlightAll={{true}}
            />{{else}}{{chip.label}}{{/if}}</EuiBadge>
      {{/each}}
      {{#if this.more}}
        <span
          class="euiSheet__more"
          data-test-subj="euiSheetMore"
        >+{{this.more}}</span>
      {{/if}}
    </span>
  </template>
}
