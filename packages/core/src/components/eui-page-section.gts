import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import style from 'ember-style-modifier/modifiers/style';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import {
  euiPageBoxSizing,
  euiPagePadding,
  euiPageRestrictWidthStyle,
  isRestricted
} from '../utils/eui/page-layout.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiBackgroundColor,
  euiPageSectionContentStyles,
  euiPageSectionStyles
} from '../utils/eui/styles.generated.ts';

import type {
  EuiPagePaddingSize,
  EuiPageRestrictWidth
} from '../utils/eui/page-layout.ts';
import type { EuiCss } from '../utils/eui/styles.ts';

export type EuiPageSectionColor =
  | 'transparent'
  | 'plain'
  | 'subdued'
  | 'highlighted'
  | 'accent'
  | 'accentSecondary'
  | 'primary'
  | 'success'
  | 'warning'
  | 'danger'
  | 'neutral'
  | 'risk';

export type EuiPageSectionAlignment = 'top' | 'center' | 'horizontalCenter';

/** Upstream `contentProps`: what goes on the inner content `<div>`. */
export interface EuiPageSectionContentProps {
  /** Extra class names. */
  className?: string;
  /** Styles composed last into the content's class (upstream's `css`). */
  css?: EuiCss;
  /** Inline styles, merged with the restricted max width. */
  style?: Record<string, string>;
  'aria-label'?: string;
  'data-test-subj'?: string;
}

/**
 * A full-width band of a page (upstream `EuiPageSection`), e.g. a header
 * area, a colored call to action or the main content. Its content is
 * wrapped in an inner `<div>` that `@restrictWidth` limits and centers.
 */
export interface EuiPageSectionSignature {
  Element: HTMLElement;
  Args: {
    /**
     * Padding: `'none'`, `'xs'`, `'s'`, `'m'`, `'l'` or `'xl'`. The
     * inline padding is on the section, the block padding on the content.
     * Defaults to `'l'`.
     */
    paddingSize?: EuiPagePaddingSize;
    /**
     * Background color: `'transparent'`, `'plain'`, `'subdued'`,
     * `'highlighted'`, `'accent'`, `'accentSecondary'`, `'primary'`,
     * `'success'`, `'warning'`, `'danger'`, `'neutral'` or `'risk'`.
     * Defaults to `'transparent'`.
     */
    color?: EuiPageSectionColor;
    /**
     * Adds a bottom border under the content; `'extended'` puts it on the
     * section so it spans the inline padding too.
     */
    bottomBorder?: boolean | 'extended';
    /**
     * Max width of the content, centered: `true` for EUI's default
     * (1200px), a number in px, or any CSS width. Defaults to `false`.
     */
    restrictWidth?: EuiPageRestrictWidth;
    /** Grows to fill the height of a flex column parent. Defaults to `false`. */
    grow?: boolean;
    /**
     * Alignment of the content: `'top'`, `'center'` (both axes) or
     * `'horizontalCenter'`. Defaults to `'top'`.
     */
    alignment?: EuiPageSectionAlignment;
    /** Class, styles, `@css` and labels of the inner content `<div>`. */
    contentProps?: EuiPageSectionContentProps;
    /** The element to render, e.g. `'main'` or `'div'`. Defaults to `'section'`. */
    component?: string;
    /** Styles composed last into the section's class (upstream's `css`). */
    css?: EuiCss;
  };
  Blocks: {
    /** The section content. */
    default: [];
  };
}

/** Theme-independent, so built once. */
const CONTENT_STYLES = euiPageSectionContentStyles();

export default class EuiPageSection extends Component<EuiPageSectionSignature> {
  get tagName(): string {
    return this.args.component ?? 'section';
  }

  get alignment(): EuiPageSectionAlignment {
    return this.args.alignment ?? 'top';
  }

  get paddingSize(): EuiPagePaddingSize {
    return this.args.paddingSize ?? 'l';
  }

  @cached
  get context() {
    return getEuiThemeContext(this);
  }

  @cached
  get classes() {
    const context = this.context;
    const styles = useEuiBorealisStyles(context, euiPageSectionStyles);
    return euiClass(
      context,
      euiPageBoxSizing,
      styles.euiPageSection,
      this.args.grow && styles.grow,
      euiPagePadding(context.upstream, this.paddingSize, 'horizontal'),
      this.args.bottomBorder === 'extended' && styles.border,
      styles[this.alignment],
      {
        backgroundColor: euiBackgroundColor(
          context.upstream,
          this.args.color ?? 'transparent'
        )
      },
      this.args.css
    );
  }

  @cached
  get contentClasses() {
    const context = this.context;
    const styles = useEuiBorealisStyles(context, euiPageSectionStyles);
    const contentProps = this.args.contentProps;
    return euiClass(
      context,
      euiPageBoxSizing,
      CONTENT_STYLES.euiPageSection__content,
      euiPagePadding(context.upstream, this.paddingSize, 'vertical'),
      this.args.bottomBorder === true && styles.border,
      this.alignment.toLowerCase().includes('center') && CONTENT_STYLES.center,
      isRestricted(this.args.restrictWidth) && CONTENT_STYLES.restrictWidth,
      contentProps?.css
    );
  }

  @cached
  get contentStyle() {
    return euiPageRestrictWidthStyle(
      this.args.restrictWidth,
      this.args.contentProps?.style
    );
  }

  <template>
    {{#let (element this.tagName) as |Tag|}}
      <Tag
        class="euiPageSection {{this.classes}}"
        {{!@glint-expect-error}}
        ...attributes
      >
        <div
          class="euiPageSection__content
            {{this.contentClasses}}
            {{@contentProps.className}}"
          aria-label={{@contentProps.aria-label}}
          data-test-subj={{@contentProps.data-test-subj}}
          {{style this.contentStyle}}
        >
          {{yield}}
        </div>
      </Tag>
    {{/let}}
  </template>
}
