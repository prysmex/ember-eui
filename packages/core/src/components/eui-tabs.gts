import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { on } from '@ember/modifier';

import { provide } from 'ember-provide-consume-context';

import { EUI_TABS_CONTEXT } from '../-private/eui-tabs-context.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiTabsStyles } from '../utils/eui/styles.generated.ts';

import type {
  EuiTabsContext,
  EuiTabsSize
} from '../-private/eui-tabs-context.ts';

const BOX_SIZING = { boxSizing: 'border-box' } as const;

/** A row of `EuiTab`s; you track the selected one. See also EuiTabbedContent. */
export interface EuiTabsSignature {
  Element: HTMLDivElement;
  Args: {
    /**
     * `'default'`, or `'condensed'`: an Ember alias kept for compatibility
     * that only turns the bottom border off (upstream removed the condensed
     * display). Defaults to `'default'`.
     */
    display?: 'default' | 'condensed';
    /**
     * `'s'`, `'m'` or `'l'`; affects the gap and the tabs' font size and
     * line height. `'xl'` is accepted as an alias of `'l'` (upstream has no
     * `xl`). Defaults to `'m'`.
     */
    size?: EuiTabsSize | 'xl';
    /** Evenly stretches the tabs to fill the width. Defaults to `false`. */
    expand?: boolean;
    /** Border under the tabs. Defaults to `true` (not for `'condensed'`). */
    bottomBorder?: boolean;
    /** Extra class(es). */
    className?: string;
  };
  Blocks: {
    /** The `EuiTab`s. */
    default: [];
  };
}

export default class EuiTabs
  extends Component<EuiTabsSignature>
  implements EuiTabsContext
{
  @provide(EUI_TABS_CONTEXT)
  get tabsContext(): EuiTabsContext {
    return this;
  }

  get size(): EuiTabsSize {
    const size = this.args.size ?? 'm';
    return size === 'xl' ? 'l' : size;
  }

  get expand(): boolean {
    return this.args.expand ?? false;
  }

  get bottomBorder(): boolean {
    return this.args.display === 'condensed'
      ? false
      : (this.args.bottomBorder ?? true);
  }

  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiTabsStyles);
    return [
      'euiTabs',
      euiClass(
        context,
        // Scoped stand-in for React's global box-sizing reset.
        BOX_SIZING,
        styles.euiTabs,
        styles[this.size],
        this.bottomBorder && styles.bottomBorder
      ),
      this.args.className
    ]
      .filter(Boolean)
      .join(' ');
  }

  /** Upstream: left/right arrows move focus between the enabled tabs, wrapping. */
  onKeyDown = (event: KeyboardEvent) => {
    if (event.key !== 'ArrowLeft' && event.key !== 'ArrowRight') return;
    const tablist = event.currentTarget as HTMLElement;
    const tabs = Array.from(
      tablist.querySelectorAll<HTMLElement>(
        '[role="tab"]:not(:disabled, [inert])'
      )
    );
    if (!tabs.length) return;
    const current = tabs.findIndex((tab) => tab.matches(':focus'));
    const next =
      event.key === 'ArrowLeft'
        ? (current <= 0 ? tabs.length : current) - 1
        : current === tabs.length - 1
          ? 0
          : current + 1;
    tabs[next]!.focus();
  };

  <template>
    <div
      role="tablist"
      class={{this.classes}}
      {{on "keydown" this.onKeyDown}}
      ...attributes
    >
      {{yield}}
    </div>
  </template>
}
