import GlimmerComponent from '@glimmer/component';
import { action } from '@ember/object';

interface EuiButtomBarArgs {
  affordForDisplacement: boolean;
  bodyClassName: string;
}
export default class EuiBottomBarComponent extends GlimmerComponent<EuiButtomBarArgs> {
  get affordForDisplacement() {
    return this.args.affordForDisplacement ?? true;
  }

  @action
  didInsert(element: HTMLElement) {
    if (this.affordForDisplacement) {
      const height = element.clientHeight;
      document.body.style.paddingBottom = `${height}px`;
    }

    if (this.args.bodyClassName) {
      document.body.classList.add(this.args.bodyClassName);
    }
  }

  @action
  updateDisplacement(element: HTMLElement) {
    let prevAffordForDisplacement = document.body.style.paddingBottom !== '';
    if (prevAffordForDisplacement !== this.affordForDisplacement) {
      if (this.affordForDisplacement) {
        // start affording for displacement
        const height = element.clientHeight;
        document.body.style.paddingBottom = `${height}px`;
      } else {
        // stop affording for displacement
        document.body.style.paddingBottom = '';
      }
    }

    //TODO: Add/Remove bodyClassName prop from body classes when updated
  }

  willDestroy() {
    if (this.affordForDisplacement) {
      document.body.style.paddingBottom = '';
    }

    if (this.args.bodyClassName) {
      document.body.classList.remove(this.args.bodyClassName);
    }
  }
}
