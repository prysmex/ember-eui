import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiButtonDisplaysColors,
  euiFocusRing,
  euiHeaderLogoStyles,
  euiTitleStyles
} from '../utils/eui/styles.generated.ts';
import EuiIcon from './eui-icon.gts';
import { getSecureRelForTarget, isValidHref } from './eui-link.gts';

import type { EuiIconSignature } from './eui-icon';

/** The app's logo (and name) linking home, first in the header. */
export interface EuiHeaderLogoSignature {
  Element: HTMLAnchorElement;
  Args: {
    /** Where the logo links to, usually `'/'`. A `javascript:` URL is dropped. */
    href?: string;
    /** `target` of the link. */
    target?: string;
    /**
     * Merged into upstream's secure `rel` (`noreferrer`, plus `noopener`
     * for `_blank`).
     */
    rel?: string;
    /**
     * Accessible name of the logo. Needed when there is no text in the
     * block.
     */
    iconTitle?: string;
    /** The logo, anything `EuiIcon`'s `@type` accepts. Defaults to `'logoElastic'`. */
    iconType?: EuiIconSignature['Args']['type'];
  };
  Blocks: {
    /** The app's name, next to the logo. */
    default: [];
  };
}

/**
 * Upstream `EuiHeaderLogo` (`euiHeaderLogoStyles` + the empty-button `text`
 * color). Latest upstream only renders the Elastic glyph or wordmark; Ember
 * keeps `@iconType` and the text block (`.euiHeaderLogo__text`, styled as an
 * `xxs` title, which upstream's dark header still recolors).
 */
export default class EuiHeaderLogo extends Component<EuiHeaderLogoSignature> {
  get href() {
    const { href } = this.args;
    return href && !isValidHref(href) ? '' : href;
  }

  get rel() {
    return getSecureRelForTarget(this.args.target, this.args.rel);
  }

  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiHeaderLogoStyles);
    const colors = useEuiBorealisStyles(context, euiButtonDisplaysColors);
    return euiClass(
      context,
      // React's global reset for anchors.
      { boxSizing: 'border-box', textDecoration: 'none' },
      `&:focus { ${euiFocusRing(context.upstream)} }`,
      styles.euiHeaderLogo,
      colors['empty']!['text']
    );
  }

  @cached
  get textClasses(): string {
    const context = getEuiThemeContext(this);
    const title = useEuiBorealisStyles(context, euiTitleStyles);
    return euiClass(context, title.euiTitle, title.xxs, {
      // Ember-only: the color follows the link (and the dark header).
      color: 'inherit',
      paddingInlineStart: context.upstream.euiTheme.size.s
    });
  }

  <template>
    <a
      class="euiHeaderLogo {{this.classes}}"
      href={{this.href}}
      target={{@target}}
      rel={{this.rel}}
      ...attributes
    >
      <EuiIcon
        @aria-label={{@iconTitle}}
        @iconClasses="euiHeaderLogo__icon"
        @size="l"
        @type={{if @iconType @iconType "logoElastic"}}
      />
      {{#if (has-block)}}
        <span class="euiHeaderLogo__text {{this.textClasses}}">
          {{yield}}
        </span>
      {{/if}}
    </a>
  </template>
}
