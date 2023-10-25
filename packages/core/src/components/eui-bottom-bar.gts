import GlimmerComponent from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import set from 'ember-set-helper/helpers/set';
import { modifier } from 'ember-modifier';

import argOrDefault from '@ember-eui/core/helpers/arg-or-default';
import classNames from '@ember-eui/core/helpers/class-names';
import EuiPortal from '@ember-eui/core/components/eui-portal';
import resizeObserver from '@ember-eui/core/modifiers/resize-observer';
import screenReaderOnly from '@ember-eui/core/modifiers/screen-reader-only';

export interface EuiButtomBarArgs {
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

  <template>
    {{! TODO: Add landmarkSupport after having an <EuiI18n> component support }}
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
          ...attributes
        >
          {{yield}}
        </section>
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
        {{this.updateDisplacementModifier
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
    {{/if}}
  </template>
}
