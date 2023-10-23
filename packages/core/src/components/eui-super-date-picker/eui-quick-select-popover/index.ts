import { action } from '@ember/object';
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { ApplyTime } from '../types/global';

interface EuiQuickSelectPopoverArgs {
  applyTime: ApplyTime;
}

export default class EuiQuickSelectPopover extends Component<EuiQuickSelectPopoverArgs> {
  @tracked isOpen = false;

  @action applyTime({
    start,
    end,
    keepPopoverOpen = false
  }: {
    start: string;
    end: string;
    quickSelect?: { timeTense: string; timeValue: number; timeUnits: string };
    keepPopoverOpen?: boolean;
  }) {
    this.args.applyTime({
      start,
      end
    });
    // if (quickSelect) {
    //   this.setState({ prevQuickSelect: quickSelect });
    // }
    if (!keepPopoverOpen) {
      this.isOpen = false;
    }
  }
}
