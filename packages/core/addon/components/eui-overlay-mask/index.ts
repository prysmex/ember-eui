import GlimmerComponent from '@glimmer/component';

interface EuiOverlayMaskArgs {}
export default class EuiOverlayMaskComponent extends GlimmerComponent<EuiOverlayMaskArgs> {
  destinationElement = document.body;
}
