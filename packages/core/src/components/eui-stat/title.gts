import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { service } from '@ember/service';

import { getEuiThemeContext } from '../../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../../utils/eui/styles.ts';
import {
  euiStatTitleStyles,
  euiTitleStyles
} from '../../utils/eui/styles.generated.ts';

import type EuiI18n from '../../services/eui-i18n';
import type { EuiTitleSignature } from '../eui-title';

/** Upstream's named stat title colors (`stat.js` `COLORS`). */
export const STAT_TITLE_COLORS = [
  'default',
  'subdued',
  'primary',
  'success',
  'warning',
  'danger',
  'accent'
] as const;

export type EuiStatTitleColor = (typeof STAT_TITLE_COLORS)[number];

/** @private The title of an EuiStat. */
export interface EuiStatTitleSignature {
  Element: any;
  Args: {
    /** Size, any `EuiTitle` size. Defaults to `'l'`. */
    titleSize?: EuiTitleSignature['Args']['size'];
    /** A named stat color or any CSS color. Defaults to `'default'`. */
    titleColor?: EuiStatTitleColor | string;
    /** Tag of the title. Defaults to `'p'`. */
    titleElement?: string;
    /** Pulses the title and labels it "Statistic is loading". */
    isLoading?: boolean;
    /** @deprecated Has no effect; named colors are detected from `@titleColor`. */
    isColorClass?: boolean;
  };
  Blocks: {
    /** The text. */
    default: [];
  };
}

export default class EuiStatTitle extends Component<EuiStatTitleSignature> {
  @service declare euiI18n: EuiI18n;

  get tagName(): string {
    return this.args.titleElement ?? 'p';
  }

  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    const title = useEuiBorealisStyles(context, euiTitleStyles);
    const stat = useEuiBorealisStyles(context, euiStatTitleStyles);
    const color = this.args.titleColor ?? 'default';
    const named = (STAT_TITLE_COLORS as readonly string[]).includes(color);
    // Upstream EuiTitle clones its classes onto the title element; the stat
    // `css` follows. Custom colors are a class instead of an inline style.
    return euiClass(
      context,
      // React's global reset zeroes the element box and sets the font.
      {
        boxSizing: 'border-box',
        margin: 0,
        padding: 0,
        fontFamily: context.upstream.euiTheme.font.family
      },
      title.euiTitle,
      title[this.args.titleSize ?? 'l'],
      stat.euiStat__title,
      named ? stat[color as EuiStatTitleColor] : { color },
      this.args.isLoading && stat.isLoading
    );
  }

  get loadingLabel(): string | undefined {
    return this.args.isLoading
      ? this.euiI18n.lookupToken('euiStat.loadingText', 'Statistic is loading')
      : undefined;
  }

  <template>
    {{#let (element this.tagName) as |TitleElement|}}
      <TitleElement
        class="euiTitle euiStat__title {{this.classes}}"
        aria-label={{this.loadingLabel}}
        ...attributes
      >{{yield}}</TitleElement>
    {{/let}}
  </template>
}
