import GlimmerComponent from '@glimmer/component';
import { getOwner } from '@ember/application';

export default class EuiOverlayMaskComponent extends GlimmerComponent {

  destinationElement = document.body;

  constructor() {
    super(...arguments)
    let body = document.body;
    body.classList.add('euiBody-hasOverlayMask');
  }

  willDestroy () {
    let body = document.body;
    body.classList.remove('euiBody-hasOverlayMask');
  }
}