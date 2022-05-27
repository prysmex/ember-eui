import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { EuiCardSelectProps, euiCardSelectableColor } from '../eui-card-select';

type EuiCardComponentArgs = {
  selectable?: EuiCardSelectProps;
  /**
   * Class that will apply to the card top section.
   */
  topClassName?: string;

  /**
   * Class that will apply to the card content section.
   */
  contentClassName?: string;
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

  get topClasses(): string {
    return ['euiCard__top', this.args.topClassName].join(' ');
  }

  get contentClasses(): string {
    return ['euiCard__content', this.args.contentClassName].join(' ');
  }
}
