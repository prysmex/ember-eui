/** The single-select cell: the option's label as an EuiBadge (a `<span>`, no `@onClick`). */
import Component from '@glimmer/component';

import EuiBadge from '@ember-eui/core/components/eui-badge';

import { fieldOptions } from '../../core/index.ts';

import type { SheetCellSignature } from '../../types.ts';

export default class SelectCell extends Component<
  SheetCellSignature<any, any>
> {
  get hasValue(): boolean {
    return this.args.value != null && this.args.value !== '';
  }

  get color(): string {
    const option = fieldOptions(this.args.field, this.args.record).find(
      (o) => o.value === this.args.value
    );
    return option?.color ?? 'hollow';
  }

  <template>
    {{#if this.hasValue}}
      <EuiBadge
        @color={{this.color}}
        data-test-subj="euiSheetChip"
      >{{@text}}</EuiBadge>
    {{/if}}
  </template>
}
