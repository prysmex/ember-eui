import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { EuiCardSelectProps, euiCardSelectableColor } from '../eui-card-select';

type EuiCardComponentArgs = {
  selectable?: EuiCardSelectProps;
};

export default class EuiCardComponent extends Component<EuiCardComponentArgs> {
  @tracked link: HTMLAnchorElement | HTMLButtonElement | null = null;

  outerOnClick = (e: MouseEvent) => {
    if (this.link && this.link !== e.target) {
      this.link.click();
    }
  };

  get selectableColorClass() {
    const selectable = this.args.selectable;
    return selectable
      ? `euiCard--isSelectable--${euiCardSelectableColor(
          selectable.color,
          selectable.isSelected
        )}`
      : undefined;
  }
}
