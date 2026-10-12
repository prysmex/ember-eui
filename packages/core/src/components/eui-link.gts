import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import screenReaderOnly from '../modifiers/screen-reader-only.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiLinkStyles } from '../utils/eui/styles.generated.ts';
import EuiIcon from './eui-icon.gts';

import type { CSSObject } from '@emotion/css/create-instance';

/** Latest upstream named link colors. */
export const LINK_COLORS = [
  'primary',
  'subdued',
  'success',
  'accent',
  'danger',
  'warning',
  'text',
  'ghost'
] as const;

export type EuiLinkColor = (typeof LINK_COLORS)[number];

function isLinkColor(color: string): color is EuiLinkColor {
  return (LINK_COLORS as readonly string[]).includes(color);
}

/**
 * Upstream `getSecureRelForTarget`: every link gets `noreferrer`, and
 * `target="_blank"` links also get `noopener`. Parts are sorted and deduped.
 */
export function getSecureRelForTarget(target = '', rel?: string): string {
  const parts = (rel ?? '')
    .split(' ')
    .filter((part) => part.length && part !== 'noreferrer');
  parts.push('noreferrer');
  if (target.includes('_blank') && !parts.includes('noopener')) {
    parts.push('noopener');
  }
  return [...new Set(parts)].sort().join(' ').trim();
}

/**
 * Upstream `validateHref`: a `javascript:` URL is not a valid link, so
 * EuiLink renders it as a disabled button instead.
 */
export function isValidHref(href: string): boolean {
  try {
    return new URL(href, 'https://ember-eui.invalid/').protocol !== 'javascript:';
  } catch {
    return !/^\s*javascript:/i.test(href);
  }
}

// Upstream `euiScreenReaderOnly` mixin. EuiScreenReaderOnly is not migrated,
// so its vendor class has no styles without the legacy stylesheet.
const screenReaderOnlyCss: CSSObject = {
  position: 'absolute',
  insetBlockStart: 'auto',
  insetInlineStart: '-10000px',
  inlineSize: '1px',
  blockSize: '1px',
  clip: 'rect(0 0 0 0)',
  clipPath: 'inset(50%)',
  overflow: 'hidden',
  margin: '-1px'
};

/**
 * A text link: an `<a>` with `@href`, otherwise a `<button>` styled as a
 * link (add `{{on "click" …}}`).
 */
export interface EuiLinkSignature {
  Element: HTMLAnchorElement | HTMLButtonElement;
  Args: {
    /**
     * `'primary'`, `'subdued'`, `'success'`, `'accent'`, `'danger'`,
     * `'warning'`, `'ghost'` or `'text'`. Defaults to `'text'` (paragraph
     * color that turns primary on hover and focus), as upstream.
     */
    color?: EuiLinkColor | (string & {});
    /**
     * Disables the link. A disabled link with `@href` renders as a disabled
     * `<button>`, because anchors cannot be disabled.
     */
    disabled?: boolean;
    /**
     * Shows the external link icon. Defaults to `true` for
     * `@target="_blank"`.
     */
    external?: boolean;
    /**
     * Where it links to; without it the link is a button. A `javascript:`
     * URL renders a disabled button instead.
     */
    href?: string;
    /**
     * `rel` of the link. `noreferrer` is always added, and `noopener` too for
     * `@target="_blank"`.
     */
    rel?: string;
    /**
     * `target` of the link. `'_blank'` also adds the external icon and a
     * screen reader note that it opens a new tab.
     */
    target?: string;
    /** `type` of the button (without `@href`). Defaults to `'button'`. */
    type?: string;
  };
  Blocks: {
    /** The link's text. */
    default: [];
  };
}

export default class EuiLink extends Component<EuiLinkSignature> {
  get isDisabled(): boolean {
    const { href } = this.args;
    return Boolean(this.args.disabled || (href && !isValidHref(href)));
  }

  // Unlike upstream, a disabled link with `@href` is a disabled button, and
  // an empty `@href` renders a button (existing Ember behavior).
  get isAnchor(): boolean {
    return Boolean(this.args.href) && !this.isDisabled;
  }

  get rel(): string {
    return getSecureRelForTarget(this.args.target, this.args.rel);
  }

  get showExternalIcon(): boolean {
    const { external, target } = this.args;
    return (target === '_blank' && external !== false) || external === true;
  }

  get opensNewTab(): boolean {
    return this.args.target === '_blank';
  }

  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const theme = context.upstream.euiTheme;
    const styles = useEuiBorealisStyles(context, euiLinkStyles);
    const color = this.args.color ?? 'text';
    // Scoped stand-in for React's global reset; upstream styles come after.
    const reset: CSSObject = {
      boxSizing: 'border-box',
      margin: 0,
      padding: 0,
      border: 'none',
      verticalAlign: 'baseline',
      cursor: 'pointer',
      ...(this.isAnchor
        ? {}
        : {
            background: 'none',
            color: 'inherit',
            borderRadius: 0,
            fontSize: 'inherit',
            fontFamily: theme.font.family
          }),
      // EuiIcon sizes itself (`@size="s"`); only the link's spacing here.
      '& .euiLink__externalIcon': { marginInlineStart: theme.size.xs },
      '& .euiLink__screenReaderOnly': screenReaderOnlyCss
    };
    const colorStyles = this.isDisabled
      ? styles.disabled
      : isLinkColor(color)
        ? styles[color]
        : undefined;
    return `euiLink ${euiClass(context, reset, styles.euiLink, colorStyles)}`;
  }

  <template>
    {{#if this.isAnchor}}
      <a
        class={{this.classes}}
        href={{@href}}
        target={{@target}}
        rel={{this.rel}}
        ...attributes
      >
        {{yield}}
        {{#if this.showExternalIcon}}
          <EuiIcon
            @type="popout"
            @size="s"
            class="euiLink__externalIcon"
            role="presentation"
          />
          <span class="euiLink__screenReaderOnly" {{screenReaderOnly}}>
            {{#if this.opensNewTab}}
              (external, opens in a new tab or window)
            {{else}}
              (external)
            {{/if}}
          </span>
        {{/if}}
      </a>
    {{else}}
      <button
        class={{this.classes}}
        type={{if @type @type "button"}}
        disabled={{this.isDisabled}}
        ...attributes
      >
        {{yield}}
      </button>
    {{/if}}
  </template>
}
