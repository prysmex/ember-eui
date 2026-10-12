import GlimmerComponent from '@glimmer/component';
import { tracked } from '@glimmer/tracking';

import { modifier } from 'ember-modifier';
import set from 'ember-set-helper/helpers/set';
import style from 'ember-style-modifier/modifiers/style';

import resizeObserver from '../modifiers/resize-observer.ts';
import screenReaderOnly from '../modifiers/screen-reader-only.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiScreenReaderOnlyCss } from '../utils/eui/page-layout.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiBottomBarStyles } from '../utils/eui/styles.generated.ts';
import EuiEmotionProvider from './eui-emotion-provider.gts';
import EuiPortal from './eui-portal.gts';

import type { EuiThemeContext } from '../utils/emotion/context.ts';

export interface EuiButtomBarArgs {
  /**
   * With `@position="fixed"` (in a portal), pads the bottom of `<body>` by
   * the bar's height so it does not cover the end of the page, and sets
   * the `--euiBottomBarOffset` CSS variable on `<html>`. Defaults to `true`.
   */
  affordForDisplacement?: boolean;
  /**
   * Class added to `<body>` while the bar is rendered.
   */
  bodyClassName?: string;
  /**
   * `'fixed'` fixes the bar to the bottom of the window (in a portal).
   * `'sticky'` keeps it at the bottom of its scrolling container,
   * `'static'` renders it in place. Defaults to `'fixed'`.
   */
  position?: 'fixed' | 'static' | 'sticky';
  /**
   * With `@position="fixed"`, renders the bar in a portal at the end of
   * `<body>`. `false` renders a fixed bar in place (and skips the body
   * displacement). Other positions never use a portal. Defaults to `true`.
   */
  usePortal?: boolean;
  /**
   * Padding inside the bar: `'none'`, `'s'`, `'m'` or `'l'`.
   * Defaults to `'m'`.
   */
  paddingSize?: 'none' | 's' | 'm' | 'l';
  /**
   * Accessible name of the bar's region landmark (announced to screen
   * readers). Defaults to "Page level controls". With a portal, screen
   * readers are also told the bar appeared at the end of the page.
   */
  landmarkHeading?: string;
  /**
   * Distance from the top, in px or any CSS length (`'sticky'` /
   * `'static'`). Defaults to none, so a sticky bar sticks to the bottom.
   */
  top?: number | string;
  /**
   * Distance from the right edge, in px or any CSS length. Defaults to `0`.
   */
  right?: number | string;
  /**
   * Distance from the left edge, in px or any CSS length, e.g. the width
   * of a side nav. Defaults to `0`.
   */
  left?: number | string;
  /**
   * Distance from the bottom, in px or any CSS length. Defaults to `0`.
   */
  bottom?: number | string;
}

const updateDisplacementModifier = modifier(function (
  _element: Element,
  _pos: unknown[],
  {
    affordForDisplacement,
    bodyClassName,
    dimensions
  }: {
    affordForDisplacement: boolean;
    bodyClassName?: string;
    dimensions?: { height: number };
  }
) {
  const displaces = affordForDisplacement && dimensions;
  if (displaces) {
    document.body.style.paddingBottom = `${dimensions.height}px`;
    // EUI doesn't use this variable, but it is useful for consumers.
    document.documentElement.style.setProperty(
      '--euiBottomBarOffset',
      `${dimensions.height}px`
    );
  }

  if (bodyClassName) {
    document.body.classList.add(bodyClassName);
  }

  return () => {
    if (displaces) {
      document.body.style.paddingBottom = '';
      document.documentElement.style.removeProperty('--euiBottomBarOffset');
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

function length(value: number | string | undefined) {
  return typeof value === 'number' ? `${value}px` : value;
}

/**
 * Upstream `EuiBottomBar` (`euiBottomBarStyles`). Like upstream, the bar is
 * always rendered in dark mode (a nested dark provider inheriting the
 * surrounding overrides and contrast mode).
 */
export default class EuiBottomBarComponent extends GlimmerComponent<EuiBottomBarSignature> {
  @tracked dimensions: { height: number; width: number } | undefined;

  get position(): 'fixed' | 'static' | 'sticky' {
    return this.args.position ?? 'fixed';
  }

  get usePortal(): boolean {
    return this.position === 'fixed' && this.args.usePortal !== false;
  }

  get affordForDisplacement(): boolean {
    return this.usePortal && (this.args.affordForDisplacement ?? true);
  }

  get landmarkHeading() {
    return this.args.landmarkHeading ?? 'Page level controls';
  }

  get inlineStyle() {
    return {
      left: length(this.args.left ?? 0),
      right: length(this.args.right ?? 0),
      bottom: length(this.args.bottom ?? 0),
      top: length(this.args.top)
    };
  }

  /** Classes from the bar's own (dark) theme context. */
  barClasses = (context: EuiThemeContext) => {
    const styles = useEuiBorealisStyles(context, euiBottomBarStyles);
    // Same order as upstream's `cssStyles`.
    return euiClass(
      context,
      {
        boxSizing: 'border-box',
        display: 'block',
        margin: 0,
        // Upstream clones the dark provider's color onto the bar.
        color: context.upstream.euiTheme.colors.textParagraph
      },
      styles.euiBottomBar,
      styles[this.position],
      styles[this.args.paddingSize ?? 'm'],
      { '& > .euiBottomBar__heading': euiScreenReaderOnlyCss }
    );
  };

  get screenReaderOnlyClass() {
    return euiClass(getEuiThemeContext(this), euiScreenReaderOnlyCss);
  }

  <template>
    {{#if this.usePortal}}
      <EuiPortal>
        <EuiEmotionProvider
          @colorMode="dark"
          @wrapper={{false}}
          @globalStyles={{false}}
          as |provider|
        >
          <section
            aria-label={{this.landmarkHeading}}
            class="euiBottomBar euiBottomBar--{{this.position}}
              {{this.barClasses provider.context}}"
            {{style this.inlineStyle}}
            {{resizeObserver onResize=(set this "dimensions")}}
            {{updateDisplacementModifier
              affordForDisplacement=this.affordForDisplacement
              dimensions=this.dimensions
              bodyClassName=@bodyClassName
            }}
            ...attributes
          >
            <div class="euiBottomBar__heading" {{screenReaderOnly}}>
              <h2>{{this.landmarkHeading}}</h2>
            </div>
            {{yield}}
          </section>
        </EuiEmotionProvider>
        <div class={{this.screenReaderOnlyClass}} {{screenReaderOnly}}>
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
      <EuiEmotionProvider
        @colorMode="dark"
        @wrapper={{false}}
        @globalStyles={{false}}
        as |provider|
      >
        <section
          aria-label={{this.landmarkHeading}}
          class="euiBottomBar euiBottomBar--{{this.position}}
            {{this.barClasses provider.context}}"
          {{style this.inlineStyle}}
          {{resizeObserver onResize=(set this "dimensions")}}
          {{updateDisplacementModifier
            affordForDisplacement=this.affordForDisplacement
            dimensions=this.dimensions
            bodyClassName=@bodyClassName
          }}
          ...attributes
        >
          <div class="euiBottomBar__heading" {{screenReaderOnly}}>
            <h2>{{this.landmarkHeading}}</h2>
          </div>
          {{yield}}
        </section>
      </EuiEmotionProvider>
    {{/if}}
  </template>
}
