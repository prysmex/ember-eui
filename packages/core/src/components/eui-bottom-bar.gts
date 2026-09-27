import GlimmerComponent from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { htmlSafe } from '@ember/template';

import { modifier } from 'ember-modifier';
import set from 'ember-set-helper/helpers/set';

import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import resizeObserver from '../modifiers/resize-observer.ts';
import screenReaderOnly from '../modifiers/screen-reader-only.ts';
import EuiPortal from './eui-portal.gts';

export interface EuiButtomBarArgs {
  /**
   * With `@position="fixed"`, pads the bottom of `<body>` by the bar's height
   * so it does not cover the end of the page. Defaults to `true`.
   */
  affordForDisplacement?: boolean;
  /**
   * Class added to `<body>` while the bar is rendered.
   */
  bodyClassName?: string;
  /**
   * `'fixed'` renders the bar in a portal, fixed to the bottom of the
   * window. `'sticky'` keeps it at the bottom of its scrolling container,
   * `'static'` renders it in place. Defaults to `'fixed'`.
   */
  position?: 'fixed' | 'static' | 'sticky';
  /**
   * @deprecated Has no effect: the bar uses a portal when `@position` is
   * `'fixed'`.
   */
  usePortal?: boolean;
  /**
   * Padding inside the bar: `'none'`, `'s'`, `'m'` or `'l'`.
   * Defaults to `'m'`.
   */
  paddingSize?: 'none' | 's' | 'm' | 'l';
  /**
   * Accessible name of the bar's region landmark (announced to screen
   * readers). Defaults to "Page level controls". With `@position="fixed"`,
   * screen readers are also told the bar appeared at the end of the page.
   */
  landmarkHeading?: string;
  /**
   * Distance from the top in px (only for `'sticky'` / `'static'`).
   * Defaults to `0`.
   */
  top?: number;
  /**
   * Distance from the right edge in px. Defaults to `0`.
   */
  right?: number;
  /**
   * Distance from the left edge in px, e.g. the width of a side nav.
   * Defaults to `0`.
   */
  left?: number;
  /**
   * Distance from the bottom in px. Defaults to `0`.
   */
  bottom?: number;
}

const updateDisplacementModifier = modifier(function (
  _element: Element,
  _pos: unknown[],
  {
    affordForDisplacement,
    usePortal,
    bodyClassName,
    dimensions
  }: {
    affordForDisplacement: boolean;
    usePortal: boolean;
    bodyClassName?: string;
    dimensions?: { height: number };
  }
) {
  if (affordForDisplacement && usePortal && dimensions) {
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

export interface EuiBottomBarSignature {
  Element: HTMLElement;
  Args: EuiButtomBarArgs;
  Blocks: {
    /** The bar's content, usually buttons in an EuiFlexGroup. */
    default: [];
  };
}

export default class EuiBottomBarComponent extends GlimmerComponent<EuiBottomBarSignature> {
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

  get bottomBarStyles(): ReturnType<typeof htmlSafe> {
    if (this.position === 'fixed') {
      return htmlSafe(
        `left:${this.left}px;right:${this.right}px;bottom:${this.bottom}px`
      );
    } else {
      return htmlSafe(
        `top:${this.top}px;left:${this.left}px;right:${this.right}px;bottom:${this.bottom}px`
      );
    }
  }

  <template>
    {{#if this.usePortal}}
      <EuiPortal>
        <section
          style={{this.bottomBarStyles}}
          {{resizeObserver onResize=(set this "dimensions")}}
          class={{classNames
            componentName="EuiBottomBar"
            paddingSize=(argOrDefault @paddingSize "m")
            positionType=(argOrDefault this.position "fixed")
          }}
          {{updateDisplacementModifier
            affordForDisplacement=this.affordForDisplacement
            usePortal=this.usePortal
            dimensions=this.dimensions
            bodyClassName=@bodyClassName
          }}
          aria-label={{if
            @landmarkHeading
            @landmarkHeading
            "Page level controls"
          }}
          ...attributes
        >
          <div {{screenReaderOnly}}>
            <h2>
              {{if @landmarkHeading @landmarkHeading "Page level controls"}}
            </h2>
          </div>
          {{yield}}
        </section>
        <div {{screenReaderOnly}}>
          <p aria-live="assertive">
            {{#if @landmarkHeading}}
              There is a new region landmark called
              {{@landmarkHeading}}
              with page level controls at the end of the document.
            {{else}}
              There is a new region landmark with page level controls at the end
              of the document.
            {{/if}}
          </p>
        </div>
      </EuiPortal>
    {{else}}
      <section
        style={{this.bottomBarStyles}}
        {{resizeObserver onResize=(set this "dimensions")}}
        class={{classNames
          componentName="EuiBottomBar"
          paddingSize=(argOrDefault @paddingSize "m")
          positionType=(argOrDefault this.position "fixed")
        }}
        aria-label={{if
          @landmarkHeading
          @landmarkHeading
          "Page level controls"
        }}
        {{updateDisplacementModifier
          affordForDisplacement=this.affordForDisplacement
          usePortal=this.usePortal
          dimensions=this.dimensions
          bodyClassName=@bodyClassName
        }}
        ...attributes
      >
        <div {{screenReaderOnly}}>
          <h2>
            {{if @landmarkHeading @landmarkHeading "Page level controls"}}
          </h2>
        </div>
        {{yield}}
      </section>
    {{/if}}
  </template>
}
