/** The single-select cell: the option's label as a chip (EuiBadge's `<span>`, no `@onClick`). */
import Component from '@glimmer/component';

import { getEuiThemeContext } from '@ember-eui/core/utils/emotion/consume';

import { fieldOptions } from '../../core/index.ts';
import Chip, { chipClasses, chipTitle } from './chip.gts';

import type { SheetCellSignature } from '../../types.ts';
import type { ChipClasses } from './chip.gts';

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

  get classes(): ChipClasses {
    return chipClasses(getEuiThemeContext(this), this.color);
  }

  get title(): string {
    return chipTitle(this.args.text);
  }

  <template>
    {{#if this.hasValue}}
      <Chip @classes={{this.classes}} @title={{this.title}}>{{@text}}</Chip>
    {{/if}}
  </template>
}
