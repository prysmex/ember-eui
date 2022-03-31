import GlimmerComponent from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { modifier } from 'ember-modifier';

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

const updateDisplacementModifier = modifier(function (
  element: Element,
  _pos: unknown[],
  {
    affordForDisplacement,
    usePortal,
    bodyClassName,
    dimensions
  }: {
    affordForDisplacement: boolean;
    usePortal: boolean;
    bodyClassName: string;
    dimensions: { height: number };
  }
) {
  if (affordForDisplacement && usePortal) {
    document.body.style.paddingBottom = `${dimensions.height}px`;
  }

  if (bodyClassName) {
    document.body.classList.add(bodyClassName);
  }

  return () => {
    if (affordForDisplacement && usePortal) {
      document.body.style.paddingBottom = '';
    }

    if (bodyClassName) {
      document.body.classList.remove(bodyClassName);
    }
  };
});

export default class EuiBottomBarComponent extends GlimmerComponent<EuiButtomBarArgs> {
  updateDisplacementModifier = updateDisplacementModifier;

  @tracked dimensions: { height: number; width: number } | undefined;

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

  get bottomBarStyles(): string {
    if (this.position === 'fixed') {
      return `left:${this.left}px;right:${this.right}px;bottom:${this.bottom}px`;
    } else {
      return `top:${this.top}px;left:${this.left}px;right:${this.right}px;bottom:${this.bottom}px`;
    }
  }
}
