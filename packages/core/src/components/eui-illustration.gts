import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { htmlSafe } from '@ember/template';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiIllustrationStyles } from '../utils/eui/styles.generated.ts';

import type { EuiCss } from '../utils/eui/styles.ts';

/**
 * An illustration asset (upstream's contract, e.g. an export of
 * `@elastic/eui-illustrations`). `light` and `dark` are inlined as-is: only
 * pass trusted, package-authored SVG markup, never user-supplied markup.
 */
export interface EuiIllustrationType {
  /** Unique id for the illustration. */
  id: string;
  /** Human-readable title, used as the default accessible label. */
  title: string;
  /** Trusted SVG markup for the light color mode. */
  light: string;
  /** Trusted SVG markup for the dark color mode. */
  dark: string;
}

/**
 * An inline SVG illustration that follows the nearest theme's color mode.
 */
export interface EuiIllustrationSignature {
  Element: HTMLSpanElement;
  Args: {
    /**
     * The illustration asset (`{ id, title, light, dark }`), typically
     * imported from `@elastic/eui-illustrations`. Its markup is inlined
     * verbatim, so it must be trusted.
     */
    type: EuiIllustrationType;
    /**
     * Accessible label; pass `''` to mark the illustration as decorative
     * (`aria-hidden`). Defaults to the illustration's `title`.
     */
    alt?: string;
    /**
     * When `true`, the SVG stretches to the container's full width; when
     * `false`, it keeps its intrinsic width. Defaults to `true`.
     */
    fullWidth?: boolean;
    /**
     * Extra styles composed last into this component's class (like upstream's
     * `css` prop).
     */
    css?: EuiCss;
  };
}

export default class EuiIllustration extends Component<EuiIllustrationSignature> {
  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiIllustrationStyles);
    return euiClass(
      context,
      styles.euiIllustration,
      (this.args.fullWidth ?? true) ? styles.fullWidth : undefined,
      this.args.css
    );
  }

  get svg() {
    const { type } = this.args;
    const dark = getEuiThemeContext(this).colorMode === 'dark';
    // Trusted asset markup, as upstream's dangerouslySetInnerHTML.
    return htmlSafe(dark ? type.dark : type.light);
  }

  get isDecorative() {
    return this.args.alt === '';
  }

  get label() {
    return this.isDecorative ? undefined : (this.args.alt ?? this.args.type.title);
  }

  <template>
    <span
      class="euiIllustration {{this.classes}}"
      aria-hidden={{if this.isDecorative "true"}}
      role={{unless this.isDecorative "img"}}
      aria-label={{this.label}}
      ...attributes
    >{{this.svg}}</span>
  </template>
}
