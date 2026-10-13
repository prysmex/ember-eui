import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { service } from '@ember/service';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { buttonReset } from '../utils/eui/form-controls.ts';
import {
  euiFormAppendPrependStyles,
  euiFormLabelStyles
} from '../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import EuiFieldText from './eui-field-text.gts';
import { euiFormLabelReset } from './eui-form-label.gts';
import EuiIcon from './eui-icon.gts';
import EuiInputPopover from './eui-input-popover.gts';
import EuiRefreshInterval from './eui-refresh-interval.gts';
import { prettyInterval } from './eui-super-date-picker/utils/pretty-interval.ts';

import type EuiI18n from '../services/eui-i18n.ts';
import type { EuiFieldTextSignature } from './eui-field-text.gts';
import type { EuiRefreshIntervalSignature } from './eui-refresh-interval.gts';

type OnRefreshChange = NonNullable<
  EuiRefreshIntervalSignature['Args']['onRefreshChange']
>;

/**
 * A read-only text input showing the auto refresh state ("Off", "5 minutes")
 * with an "Auto refresh" prepend button; both open a popover with
 * `EuiRefreshInterval`. Upstream's `EuiAutoRefresh`; for a compact button use
 * `EuiAutoRefreshButton`. Attributes land on the input.
 */
export interface EuiAutoRefreshSignature {
  Element: HTMLInputElement;
  Args: {
    /** Whether refreshing is paused. Defaults to `true`. */
    isPaused?: boolean;
    /** The interval in milliseconds. Defaults to `1000`. */
    refreshInterval?: number;
    /** The smallest allowed interval in milliseconds. Defaults to `0`. */
    minInterval?: number;
    /**
     * By default the unit is rounded up to the next largest one (90 seconds
     * becomes 2 minutes). Pass `'s'`, `'m'` or `'h'` to fix it.
     */
    intervalUnits?: 's' | 'm' | 'h';
    /**
     * Called with `{ isPaused, refreshInterval, intervalUnits }` when the user
     * changes the refresh settings.
     */
    onRefreshChange: OnRefreshChange;
    /** Disables the input and its button. */
    isDisabled?: boolean;
    /**
     * The input is read-only by default because its value is edited in the
     * popover. Defaults to `true`.
     */
    readOnly?: boolean;
    /** Stretches the input to its container's width. */
    fullWidth?: boolean;
    /** Compressed input, for dense forms. */
    compressed?: boolean;
    /** Invalid state: danger border, warning icon and `aria-invalid`. */
    isInvalid?: boolean;
    /** Shows a spinner in the input. */
    isLoading?: boolean;
  };
  Blocks: {
    /**
     * Content after the input (upstream `append`), e.g. an
     * `EuiFormAppend`; yields the class to put on it and the input id.
     */
    append: EuiFieldTextSignature['Blocks']['append'];
  };
}

/** The label truncates, like upstream's `eui-textTruncate` utility. */
const TRUNCATE = {
  overflow: 'hidden',
  textOverflow: 'ellipsis',
  whiteSpace: 'nowrap'
} as const;

export default class EuiAutoRefresh extends Component<EuiAutoRefreshSignature> {
  @service declare euiI18n: EuiI18n;

  @tracked isOpen = false;

  get context() {
    return getEuiThemeContext(this);
  }

  get readOnly(): boolean {
    return this.args.readOnly ?? true;
  }

  get label(): string {
    return this.euiI18n.lookupToken('euiAutoRefresh.autoRefreshLabel', 'Auto refresh');
  }

  get value(): string {
    return prettyInterval(
      this.euiI18n,
      this.args.isPaused ?? true,
      this.args.refreshInterval ?? 1000,
      { unit: this.args.intervalUnits }
    );
  }

  /** Upstream `EuiFormPrepend` wrapper (focus ring around the button). */
  @cached
  get wrapperClass() {
    const styles = useEuiBorealisStyles(this.context, euiFormAppendPrependStyles);

    return euiClass(this.context, { boxSizing: 'border-box' }, styles.wrapper);
  }

  /** Upstream `EuiFormPrepend element="button"`. */
  @cached
  get buttonClass() {
    const context = this.context;
    const styles = useEuiBorealisStyles(context, euiFormAppendPrependStyles);
    const isDisabled = Boolean(this.args.isDisabled);

    return `euiFormPrepend euiFormControlLayout__prepend ${euiClass(
      context,
      buttonReset,
      { fontFamily: context.upstream.euiTheme.font.family },
      styles.side,
      this.args.compressed ? styles.compressed : styles.uncompressed,
      !isDisabled && styles.isInteractive,
      isDisabled && styles.disabled
    )}`;
  }

  /** The label is an `EuiFormLabel` look-alike `<span>` (inside a button). */
  @cached
  get labelClass() {
    const context = this.context;
    const styles = useEuiBorealisStyles(context, euiFormLabelStyles);

    return `euiFormLabel eui-textTruncate ${euiClass(
      context,
      euiFormLabelReset(context.upstream),
      styles.euiFormLabel,
      styles.notDisabled,
      TRUNCATE
    )}`;
  }

  hasNoAppend = (hasBlock: boolean) => !hasBlock;

  @action
  toggle(): void {
    this.isOpen = !this.isOpen;
  }

  @action
  close(): void {
    this.isOpen = false;
  }

  <template>
    <EuiInputPopover
      class="euiAutoRefresh"
      @fullWidth={{@fullWidth}}
      @isOpen={{this.isOpen}}
      @closePopover={{this.close}}
    >
      <:input>
        <EuiFieldText
          aria-label={{this.label}}
          @value={{this.value}}
          @readOnly={{this.readOnly}}
          @disabled={{@isDisabled}}
          @fullWidth={{@fullWidth}}
          @compressed={{@compressed}}
          @isInvalid={{@isInvalid}}
          @isLoading={{@isLoading}}
          @isFakeAppendBlock={{this.hasNoAppend (has-block "append")}}
          {{on "click" this.toggle}}
          ...attributes
        >
          <:prepend>
            <div class={{this.wrapperClass}}>
              <button
                type="button"
                class={{this.buttonClass}}
                disabled={{@isDisabled}}
                {{on "click" this.toggle}}
              >
                <EuiIcon @type="refreshTime" />
                <span class={{this.labelClass}}><strong>{{this.label}}</strong></span>
              </button>
            </div>
          </:prepend>
          <:append as |appendClasses inputId|>
            {{yield appendClasses inputId to="append"}}
          </:append>
        </EuiFieldText>
      </:input>
      <:content>
        <EuiRefreshInterval
          @isPaused={{@isPaused}}
          @refreshInterval={{@refreshInterval}}
          @minInterval={{@minInterval}}
          @intervalUnits={{@intervalUnits}}
          @onRefreshChange={{@onRefreshChange}}
        />
      </:content>
    </EuiInputPopover>
  </template>
}
