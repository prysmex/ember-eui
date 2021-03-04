import GlimmerComponent from '@glimmer/component';

interface EuiOverlayMaskArgs {}

export default class EuiOverlayMaskComponent extends GlimmerComponent<EuiOverlayMaskArgs> {
  destinationElement = document.body;

  constructor(owner: unknown, args: EuiOverlayMaskArgs) {
    super(owner, args);
    let body = document.body;
    body.classList.add('euiBody-hasOverlayMask');
  }

  willDestroy() {
    let body = document.body;
    body.classList.remove('euiBody-hasOverlayMask');
  }
}
