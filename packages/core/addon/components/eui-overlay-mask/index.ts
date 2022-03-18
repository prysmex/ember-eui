import GlimmerComponent from '@glimmer/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';

interface EuiOverlayMaskArgs {
  onClick(): void;
}
export default class EuiOverlayMaskComponent extends GlimmerComponent<EuiOverlayMaskArgs> {
  @tracked overlayMaskNode: HTMLDivElement | undefined;

  destinationElement = document.body;

  @action
  onClick(e: MouseEvent) {
    if (e.target === this.overlayMaskNode) {
      this.args.onClick();
    }
  }
}
