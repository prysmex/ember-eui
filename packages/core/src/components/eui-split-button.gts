import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { htmlSafe } from '@ember/template';
import { getTokenName } from '@elastic/eui-theme-common';
import { provide } from 'ember-provide-consume-context';

import { EUI_SPLIT_BUTTON_CONTEXT } from '../-private/eui-split-button-context.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import {
  splitButtonDividerStyles,
  splitButtonStyles
} from '../utils/eui/split-button.ts';
import {
  getEuiButtonColorValues,
  getEuiFilledButtonColorValues
} from '../utils/eui/styles.generated.ts';
import { euiClass } from '../utils/eui/styles.ts';
import EuiSplitButtonActionPrimary from './eui-split-button/eui-split-button-action-primary.gts';
import EuiSplitButtonActionSecondary from './eui-split-button/eui-split-button-action-secondary.gts';

import type { EuiSplitButtonContext } from '../-private/eui-split-button-context.ts';
import type { EuiCss } from '../utils/eui/styles.ts';

type ButtonColorValues = { backgroundColor: string; color: string };

export interface EuiSplitButtonSignature {
  Element: HTMLDivElement;
  Args: {
    /** `'s'` or `'m'` (32/40px). Defaults to `'m'`. */
    size?: 'xs' | 's' | 'm';
    /**
     * `'primary'`, `'accent'`, `'accentSecondary'`, `'neutral'`,
     * `'success'`, `'warning'`, `'risk'`, `'danger'` or `'text'`. Defaults
     * to `'primary'`.
     */
    color?: string;
    /** Solid background. Defaults to `false`. */
    fill?: boolean;
    /** Disables both actions. */
    isDisabled?: boolean;
    /**
     * Beta: renders the disabled actions with `aria-disabled` instead of
     * `disabled`, so they stay focusable (e.g. for a tooltip).
     */
    hasAriaDisabled?: boolean;
    /** Shows a loading spinner in both actions and disables them. */
    isLoading?: boolean;
    /**
     * Extra styles composed last into this component's class (like upstream's
     * `css` prop). Prefer this to an extra class when styling it from a parent.
     */
    css?: EuiCss;
  };
  Blocks: {
    /**
     * The two actions, in this order: `<split.ActionPrimary>` then
     * `<split.ActionSecondary>`.
     */
    default: [
      {
        ActionPrimary: typeof EuiSplitButtonActionPrimary;
        ActionSecondary: typeof EuiSplitButtonActionSecondary;
      }
    ];
  };
}

/**
 * A primary action and a secondary icon action (often opening a popover of
 * related actions) joined into one control (upstream `EuiSplitButton`).
 */
export default class EuiSplitButton extends Component<EuiSplitButtonSignature> {
  actions = {
    ActionPrimary: EuiSplitButtonActionPrimary,
    ActionSecondary: EuiSplitButtonActionSecondary
  };

  get context() {
    return getEuiThemeContext(this);
  }
  get size(): 'xs' | 's' | 'm' {
    const size = this.args.size;
    return size === 'xs' || size === 's' ? size : 'm';
  }
  get color() {
    return this.args.color ?? 'primary';
  }
  get fill() {
    return Boolean(this.args.fill);
  }

  @provide(EUI_SPLIT_BUTTON_CONTEXT)
  get splitButtonContext(): EuiSplitButtonContext {
    // eslint-disable-next-line @typescript-eslint/no-this-alias
    const split = this;
    return {
      get size() {
        return split.size;
      },
      get color() {
        return split.color;
      },
      get fill() {
        return split.fill;
      },
      get isDisabled() {
        return split.args.isDisabled;
      },
      get hasAriaDisabled() {
        return split.args.hasAriaDisabled;
      },
      get isLoading() {
        return split.args.isLoading;
      },
      get dividerClass() {
        return split.dividerClass;
      }
    };
  }

  @cached
  get colors(): { filled: ButtonColorValues; base: ButtonColorValues } {
    const color = this.args.isDisabled ? 'disabled' : this.color;
    const theme = this.context.upstream;
    return {
      filled: getEuiFilledButtonColorValues(theme, color),
      base: getEuiButtonColorValues(theme, color)
    };
  }

  /** Upstream `dividerColor` (also the `--euiSplitButtonBorderColor`). */
  @cached
  get dividerColor(): string {
    const { euiTheme } = this.context.upstream;
    const color = this.color;
    if (color === 'warning' && this.fill) return this.colors.filled.color;
    const token =
      color === 'text' ? 'borderBasePlain' : getTokenName('borderBase', color);
    return (euiTheme.colors as unknown as Record<string, string>)[token]!;
  }

  @cached
  get classes() {
    const context = this.context;
    const styles = splitButtonStyles(
      context,
      this.fill
        ? this.colors.filled.backgroundColor
        : this.colors.base.backgroundColor
    );
    return `euiSplitButton ${euiClass(
      context,
      { boxSizing: 'border-box' },
      styles.euiSplitButton,
      (this.color === 'text' || Boolean(context.upstream.highContrastMode)) &&
        styles.hasBorder,
      this.args.css
    )}`;
  }

  @cached
  get dividerClass() {
    const context = this.context;
    const styles = splitButtonDividerStyles(
      context,
      context.upstream.highContrastMode && this.fill
        ? this.colors.filled.color
        : this.dividerColor
    );
    return `euiSplitButton__divider ${euiClass(
      context,
      { boxSizing: 'border-box' },
      styles.divider
    )}`;
  }

  @cached
  get style() {
    return htmlSafe(`--euiSplitButtonBorderColor: ${this.dividerColor}`);
  }

  <template>
    <div
      role="group"
      class={{this.classes}}
      data-size={{this.size}}
      data-fill={{if this.fill "true"}}
      style={{this.style}}
      ...attributes
    >
      {{yield this.actions}}
    </div>
  </template>
}
