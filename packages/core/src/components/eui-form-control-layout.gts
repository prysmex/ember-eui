import Component from '@glimmer/component';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import {
  iconAffordanceStyle,
  layoutBoxReset
} from '../utils/eui/form-controls.ts';
import {
  euiFormControlLayoutSideNodeStyles,
  euiFormControlLayoutStyles
} from '../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import EuiFormControlLayoutIcons from './eui-form-control-layout-icons.gts';

import type { EuiFormControlLayoutIconsSignature } from './eui-form-control-layout-icons';
import type { CSSInterpolation } from '@emotion/css/create-instance';

/**
 * The wrapper EUI's inputs use for icons, the clear button, the loading
 * spinner and prepend/append content. Use it around your own controls to
 * match them.
 */
export interface EuiFormControlLayoutSignature {
  Element: HTMLDivElement;
  Args: {
    /** Stretches the control to its container's width. */
    fullWidth?: boolean;
    /** Shorter control, for dense forms. */
    compressed?: boolean;
    /** Read-only styling. */
    readOnly?: boolean;
    /**
     * Styles the control as a group with its `<:prepend>` / `<:append>`
     * content. Defaults to `true`.
     */
    useGroup?: boolean;
    /** Disabled styling. */
    disabled?: boolean;
    /** Same as `@disabled`. */
    isDisabled?: boolean;
    /** Shows the danger warning icon on the right. */
    isInvalid?: boolean;
    /**
     * Shows a dropdown arrow on the right, as EuiSelect does. Hidden while
     * disabled or read-only.
     */
    isDropdown?: boolean;
    /** Icon inside the control, anything `EuiIcon`'s `@type` accepts. */
    icon?: EuiFormControlLayoutIconsSignature['Args']['icon'];
    /** Side of `@icon`: `'left'` or `'right'`. Defaults to `'left'`. */
    iconSide?: EuiFormControlLayoutIconsSignature['Args']['side'];
    /**
     * `'absolute'` overlays the icons on the control, `'static'` lays them
     * out beside it. Defaults to `'absolute'`.
     */
    iconsPosition?: 'absolute' | 'static';
    /** Shows a clear ("x") button calling this function. */
    clear?: EuiFormControlLayoutIconsSignature['Args']['clear'];
    /** Accessible label of the clear button. Defaults to "Clear input". */
    clearLabel?: string;
    /** Shows a spinner. */
    isLoading?: boolean;
    /** @deprecated Has no effect. */
    inputId?: string;
    /** @private Render the `<:prepend>` block. Defaults to `true`. */
    isPrependProvided?: boolean;
    /** @private Render the `<:append>` block. Defaults to `true`. */
    isAppendProvided?: boolean;
    /** @private Group styling without the `--group` class (EuiFormControlLayoutDelimited). */
    isDelimited?: boolean;
    /** @private Extra styles composed last onto the root class. */
    css?: CSSInterpolation[];
    /** @private Extra styles composed last onto the children wrapper. */
    wrapperCss?: CSSInterpolation[];
  };
  Blocks: {
    /**
     * Content before the control. It is wrapped in a
     * `.euiFormControlLayout__prepend` element; yields that class name.
     */
    prepend: [classes: 'euiFormControlLayout__prepend'];
    /** The control (e.g. an `<input>`); same as the default block. */
    field: [];
    /** The control. */
    default: [];
    /**
     * Content after the control. It is wrapped in a
     * `.euiFormControlLayout__append` element; yields that class name.
     */
    append: [classes: 'euiFormControlLayout__append'];
  };
}

export default class EuiFormControlLayout extends Component<EuiFormControlLayoutSignature> {
  get context() {
    return getEuiThemeContext(this);
  }
  get isDisabled() {
    return Boolean(this.args.disabled || this.args.isDisabled);
  }
  get compressed() {
    return Boolean(this.args.compressed);
  }
  get iconSide(): 'left' | 'right' {
    return this.args.iconSide === 'right' ? 'right' : 'left';
  }
  get hasDropdownIcon() {
    return Boolean(
      this.args.isDropdown && !this.args.readOnly && !this.isDisabled
    );
  }
  get hasLeftIcon() {
    return Boolean(this.args.icon) && this.iconSide === 'left';
  }
  get hasRightIcons() {
    return Boolean(
      (this.args.icon && this.iconSide === 'right') ||
        this.args.clear ||
        this.args.isLoading ||
        this.args.isInvalid ||
        this.hasDropdownIcon
    );
  }
  get rightIcon() {
    return this.iconSide === 'right' ? this.args.icon : undefined;
  }
  get iconStyle() {
    if (this.args.iconsPosition === 'static') return undefined;
    return iconAffordanceStyle({
      icon: this.args.icon,
      iconSide: this.iconSide,
      clear: this.args.clear,
      isLoading: this.args.isLoading,
      isInvalid: this.args.isInvalid,
      isDropdown: this.hasDropdownIcon
    });
  }

  showPrepend = (hasBlock: boolean) =>
    hasBlock && this.args.isPrependProvided !== false;
  showAppend = (hasBlock: boolean) =>
    hasBlock && this.args.isAppendProvided !== false;
  isGroup = (hasPrepend: boolean, hasAppend: boolean) =>
    Boolean(this.args.isDelimited) ||
    (this.args.useGroup !== false &&
      (this.showPrepend(hasPrepend) || this.showAppend(hasAppend)));

  rootClasses = (isGroup: boolean) => {
    const context = this.context;
    const styles = useEuiBorealisStyles(context, euiFormControlLayoutStyles);
    const compressed = this.compressed;
    const css = euiClass(
      context,
      layoutBoxReset,
      styles.euiFormControlLayout,
      compressed ? styles.compressed : styles.uncompressed,
      this.args.fullWidth ? styles.fullWidth : styles.formWidth,
      ...(isGroup
        ? [
            styles.group.group,
            compressed ? styles.group.compressed : styles.group.uncompressed,
            (this.isDisabled || this.args.readOnly) && styles.group.disabled
          ]
        : []),
      ...(this.args.css ?? [])
    );
    return [
      'euiFormControlLayout',
      isGroup && !this.args.isDelimited && 'euiFormControlLayout--group',
      this.isDisabled && 'euiFormControlLayout-isDisabled',
      this.args.readOnly && 'euiFormControlLayout-readOnly',
      css
    ]
      .filter(Boolean)
      .join(' ');
  };

  wrapperClasses = (isGroup: boolean) => {
    const context = this.context;
    const styles = useEuiBorealisStyles(context, euiFormControlLayoutStyles);
    return euiClass(
      context,
      styles.children.euiFormControlLayout__childrenWrapper,
      isGroup && styles.children.inGroup,
      ...(this.args.wrapperCss ?? [])
    );
  };

  sideClasses = (side: 'prepend' | 'append') => {
    const context = this.context;
    const styles = useEuiBorealisStyles(
      context,
      euiFormControlLayoutSideNodeStyles
    );
    const sizes = this.compressed ? styles.compressed : styles.uncompressed;
    return euiClass(
      context,
      styles.euiFormControlLayout__side,
      this.compressed
        ? styles.compressed.compressed
        : styles.uncompressed.uncompressed,
      sizes[side],
      this.isDisabled && styles.disabled,
      this.args.readOnly && styles.readOnly
    );
  };

  <template>
    {{#let
      (this.isGroup (has-block "prepend") (has-block "append"))
      as |isGroup|
    }}
      <div class={{this.rootClasses isGroup}} ...attributes>
        {{#if (this.showPrepend (has-block "prepend"))}}
          <div class="euiFormControlLayout__prepend {{this.sideClasses 'prepend'}}">
            {{yield "euiFormControlLayout__prepend" to="prepend"}}
          </div>
        {{/if}}
        <div
          class="euiFormControlLayout__childrenWrapper {{this.wrapperClasses isGroup}}"
          style={{this.iconStyle}}
        >
          {{#if this.hasLeftIcon}}
            <EuiFormControlLayoutIcons
              @side="left"
              @icon={{@icon}}
              @iconsPosition={{@iconsPosition}}
              @compressed={{@compressed}}
              @isDisabled={{this.isDisabled}}
            />
          {{/if}}
          {{#if (has-block "field")}}
            {{yield to="field"}}
          {{else}}
            {{yield}}
          {{/if}}
          {{#if this.hasRightIcons}}
            <EuiFormControlLayoutIcons
              @side="right"
              @icon={{this.rightIcon}}
              @iconsPosition={{@iconsPosition}}
              @compressed={{@compressed}}
              @clear={{@clear}}
              @clearLabel={{@clearLabel}}
              @isLoading={{@isLoading}}
              @isInvalid={{@isInvalid}}
              @isDropdown={{this.hasDropdownIcon}}
              @isDisabled={{this.isDisabled}}
            />
          {{/if}}
        </div>
        {{#if (this.showAppend (has-block "append"))}}
          <div class="euiFormControlLayout__append {{this.sideClasses 'append'}}">
            {{yield "euiFormControlLayout__append" to="append"}}
          </div>
        {{/if}}
      </div>
    {{/let}}
  </template>
}
