/**
 * The multi-select and linked-record cell: one chip per item (EuiBadge's
 * `<span>`, no `@onClick`: nothing tabbable, P9), at most three, then "+N".
 */
import Component from '@glimmer/component';

import EuiHighlight from '@ember-eui/core/components/eui-highlight';
import { getEuiThemeContext } from '@ember-eui/core/utils/emotion/consume';

import { fieldOptions } from '../../core/index.ts';
import Chip, { chipClasses, chipTitle } from './chip.gts';

import type { SheetCellSignature } from '../../types.ts';
import type { ChipClasses } from './chip.gts';

/** Chips shown before "+N". */
export const MAX_CHIPS = 3;

interface ChipView {
  key: string;
  label: string;
  classes: ChipClasses;
  title: string;
}

export default class ChipsCell extends Component<SheetCellSignature<any, any>> {
  get items(): unknown[] {
    return Array.isArray(this.args.value) ? this.args.value : [];
  }

  get chips(): ChipView[] {
    const field = this.args.field;
    const options =
      field.type === 'multiSelect'
        ? fieldOptions(field, this.args.record)
        : null;
    const context = getEuiThemeContext(this);
    const chip = (key: string, label: string, color: string): ChipView => ({
      key,
      label,
      classes: chipClasses(context, color),
      title: chipTitle(label)
    });
    return this.items.slice(0, MAX_CHIPS).map((item, i) => {
      if (options) {
        const option = options.find((o) => o.value === item);
        return chip(
          `${i}:${String(item)}`,
          option?.label ?? String(item),
          option?.color ?? 'hollow'
        );
      }
      const record = item as { id?: string | number; label?: string };
      return chip(
        `${i}:${String(record?.id)}`,
        record?.label ?? String(record?.id ?? ''),
        'hollow'
      );
    });
  }

  get more(): number {
    return Math.max(0, this.items.length - MAX_CHIPS);
  }

  <template>
    <span class="euiSheet__chips">
      {{#each this.chips key="key" as |chip|}}
        <Chip @classes={{chip.classes}} @title={{chip.title}}>{{#if
            @highlight
          }}<EuiHighlight
              @text={{chip.label}}
              @search={{@highlight}}
              @highlightAll={{true}}
            />{{else}}{{chip.label}}{{/if}}</Chip>
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
