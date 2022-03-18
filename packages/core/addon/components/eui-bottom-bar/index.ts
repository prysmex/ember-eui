import GlimmerComponent from '@glimmer/component';
import { action } from '@ember/object';

interface EuiButtomBarArgs {
  affordForDisplacement: boolean;
  bodyClassName: string;
  position?: 'fixed' | 'static' | 'sticky';
  usePortal: boolean;
  paddingSize?: 'none' | 's' | 'm' | 'l';
  landmarkHeading?: string;
  top: number;
  right: number;
  left: number;
  bottom: number;
}
export default class EuiBottomBarComponent extends GlimmerComponent<EuiButtomBarArgs> {
  get affordForDisplacement(): boolean {
    return this.position !== 'fixed'
      ? false
      : this.args.affordForDisplacement ?? true;
  }

  get usePortal(): boolean {
    return this.position !== 'fixed' ? false : true;
  }

  get position(): string {
    return this.args.position || 'fixed';
  }

  get top(): number {
    return this.args.top ? this.args.top : 0;
  }

  get right(): number {
    return this.args.right ? this.args.right : 0;
  }

  get left(): number {
    return this.args.left ? this.args.left : 0;
  }

  get bottom(): number {
    return this.args.bottom ? this.args.bottom : 0;
  }

  get bottomBarStyles(): { [i: string]: string } {
    if (this.position === 'fixed') {
      return {
        left: `${this.left}px`,
        right: `${this.right}px`,
        bottom: `${this.bottom}px`
      };
    } else {
      return {
        top: `${this.top}px`,
        left: `${this.left}px`,
        right: `${this.right}px`,
        bottom: `${this.bottom}px`
      };
    }
  }

  @action
  didInsert(element: HTMLElement): void {
    if (this.affordForDisplacement && this.usePortal) {
      const height = element.clientHeight;
      document.body.style.paddingBottom = `${height}px`;
    }

    if (this.args.bodyClassName) {
      document.body.classList.add(this.args.bodyClassName);
    }
  }

  @action
  updateDisplacement(element: HTMLElement): void {
    const prevAffordForDisplacement = document.body.style.paddingBottom !== '';
    if (prevAffordForDisplacement !== this.affordForDisplacement) {
      if (this.affordForDisplacement && this.usePortal) {
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

  willDestroy(): void {
    if (this.affordForDisplacement) {
      document.body.style.paddingBottom = '';
    }

    if (this.args.bodyClassName) {
      document.body.classList.remove(this.args.bodyClassName);
    }
  }
}
