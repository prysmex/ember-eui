import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import {
  euiFormControlLayoutDelimited__delimiter,
  euiFormControlLayoutDelimited__input,
  euiFormControlLayoutDelimitedStyles,
  euiTextStyles
} from '../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import EuiFormControlLayout from './eui-form-control-layout.gts';
import { euiTextColorCss } from './eui-text-color.gts';

import type { EuiFormControlLayoutSignature } from './eui-form-control-layout';

/**
 * Two controls in one field with a delimiter between them, e.g. a number
 * range ("0 → 100") or start and end dates.
 */
export interface EuiFormControlLayoutDelimitedSignature {
  Element: HTMLDivElement;
  Args: {
    /** Icon at the start of the control, anything `EuiIcon`'s `@type` accepts. */
    icon?: string;
    /**
     * Side of `@icon`: `'left'` or `'right'` (upstream `icon.side`).
     * Defaults to `'left'`.
     */
    iconSide?: EuiFormControlLayoutSignature['Args']['iconSide'];
    /** Shows a clear ("x") button calling this function. */
    clear?: EuiFormControlLayoutSignature['Args']['clear'];
    /** Stretches the control to its container's width. */
    fullWidth?: EuiFormControlLayoutSignature['Args']['fullWidth'];
    /** Shows a spinner. */
    isLoading?: EuiFormControlLayoutSignature['Args']['isLoading'];
    /** Shorter control, for dense forms. */
    compressed?: EuiFormControlLayoutSignature['Args']['compressed'];
    /** Read-only styling. */
    readOnly?: EuiFormControlLayoutSignature['Args']['readOnly'];
    /** Disabled styling. */
    disabled?: EuiFormControlLayoutSignature['Args']['disabled'];
    /** Same as `@disabled`. */
    isDisabled?: EuiFormControlLayoutSignature['Args']['isDisabled'];
    /**
     * Invalid styling: a danger underline/border, a danger delimiter and the
     * warning icon (not while disabled or read-only).
     */
    isInvalid?: boolean;
    /** Text between the two controls. Defaults to `'→'`. */
    delimiter?: string;
    /** @deprecated Has no effect: the delimited layout is always a group. */
    useGroup?: boolean;
    /**
     * Renders the `<:prepend>` block. Defaults to `true`. Lets a wrapper
     * that always passes the block hide it without remounting the layout
     * (upstream passes `prepend={undefined}`).
     */
    isPrependProvided?: boolean;
    /**
     * Renders the `<:append>` block. Defaults to `true`. Lets a wrapper
     * that always passes the block hide it without remounting the layout
     * (upstream passes `append={undefined}`).
     */
    isAppendProvided?: boolean;
  };
  Blocks: {
    /** Content before the controls; yields the class to put on it. */
    prepend: EuiFormControlLayoutSignature['Blocks']['prepend'];
    /**
     * The first control, e.g. an `EuiFieldNumber @controlOnly={{true}}`;
     * yields the class to put on it (it carries the delimited input styles).
     */
    startControl: [classes: string];
    /** Custom delimiter content, instead of `@delimiter`. */
    delimiter: [];
    /** The second control; yields the class to put on it. */
    endControl: [classes: string];
    /** Content after the controls; yields the class to put on it. */
    append: EuiFormControlLayoutSignature['Blocks']['append'];
  };
}

export default class EuiFormControlLayoutDelimited extends Component<EuiFormControlLayoutDelimitedSignature> {
  get context() {
    return getEuiThemeContext(this);
  }
  get isDisabled() {
    return Boolean(this.args.disabled || this.args.isDisabled);
  }
  get showInvalidState() {
    return Boolean(
      this.args.isInvalid && !this.isDisabled && !this.args.readOnly
    );
  }
  /** A side shows when its block is passed and not switched off. */
  provided = (hasBlock: boolean, isProvided: boolean | undefined) =>
    hasBlock && isProvided !== false;
  get delimiter() {
    return this.args.delimiter ?? '→';
  }
  @cached
  get styles() {
    return useEuiBorealisStyles(
      this.context,
      euiFormControlLayoutDelimitedStyles
    );
  }
  get rootCss() {
    const styles = this.styles;
    return [
      styles.delimited,
      this.isDisabled && styles.disabled,
      this.args.readOnly && styles.readOnly
    ];
  }
  get wrapperCss() {
    const styles = this.styles;
    return [
      styles.childrenWrapper.delimited,
      this.showInvalidState && styles.childrenWrapper.invalid,
      this.args.readOnly && styles.childrenWrapper.readOnly
    ];
  }
  /** The class yielded to each control: upstream's cloned input styles. */
  @cached
  get inputClass() {
    return `euiFormControlLayoutDelimited__input ${euiClass(
      this.context,
      euiFormControlLayoutDelimited__input
    )}`;
  }
  /** Upstream renders the delimiter as `EuiText size="s"` with these styles last. */
  @cached
  get delimiterClass() {
    const context = this.context;
    const text = useEuiBorealisStyles(context, euiTextStyles);
    return euiClass(
      context,
      { boxSizing: 'border-box' },
      text.euiText,
      text.s,
      euiTextColorCss(context, this.showInvalidState ? 'danger' : 'subdued'),
      euiFormControlLayoutDelimited__delimiter(context.upstream)
    );
  }

  <template>
    <EuiFormControlLayout
      class="euiFormControlLayoutDelimited
        {{if this.showInvalidState 'euiFormControlLayoutDelimited--isInvalid'}}"
      @isDelimited={{true}}
      @iconsPosition="static"
      @css={{this.rootCss}}
      @wrapperCss={{this.wrapperCss}}
      @icon={{@icon}}
      @iconSide={{@iconSide}}
      @clear={{@clear}}
      @fullWidth={{@fullWidth}}
      @isLoading={{@isLoading}}
      @isInvalid={{@isInvalid}}
      @compressed={{@compressed}}
      @readOnly={{@readOnly}}
      @disabled={{this.isDisabled}}
      @isPrependProvided={{this.provided (has-block "prepend") @isPrependProvided}}
      @isAppendProvided={{this.provided (has-block "append") @isAppendProvided}}
      ...attributes
    >
      <:prepend as |prependClasses|>
        {{yield prependClasses to="prepend"}}
      </:prepend>
      <:field>
        {{yield this.inputClass to="startControl"}}
        <div
          class="euiText euiFormControlLayoutDelimited__delimiter
            {{this.delimiterClass}}"
        >
          {{#if (has-block "delimiter")}}
            {{yield to="delimiter"}}
          {{else}}
            {{this.delimiter}}
          {{/if}}
        </div>
        {{yield this.inputClass to="endControl"}}
      </:field>
      <:append as |appendClasses|>
        {{yield appendClasses to="append"}}
      </:append>
    </EuiFormControlLayout>
  </template>
}
