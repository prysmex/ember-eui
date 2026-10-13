import Component from '@glimmer/component';
import { provide } from 'ember-provide-consume-context';

import { EUI_FORM_CONTROL_LAYOUT_CONTEXT } from '../-private/eui-form-control-layout-context.ts';

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
import type { EuiCss } from '../utils/eui/styles.ts';
import EuiFormControlLayoutIcons, {
  iconSideOf
} from './eui-form-control-layout-icons.gts';

import type { EuiFormControlLayoutContext } from '../-private/eui-form-control-layout-context.ts';
import type { CommonArgs } from './common.ts';
import type { EuiFormControlLayoutIconsSignature } from './eui-form-control-layout-icons';
import type { EuiIconSignature } from './eui-icon';

/** Supported keys of `@wrapperProps`. */
export type EuiFormControlLayoutWrapperProps = CommonArgs & { css?: EuiCss };

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
    /**
     * Icon inside the control, anything `EuiIcon`'s `@type` accepts, or an
     * icon shape object (upstream `IconShape`): `{ type, side, color,
     * onClick, … }`, where `onClick` makes it a button and other keys
     * (`aria-label`, `data-test-subj`, `tabIndex`, …) are its attributes.
     */
    icon?: EuiFormControlLayoutIconsSignature['Args']['icon'];
    /**
     * Side of `@icon`: `'left'` or `'right'`. Defaults to `'left'`. An icon
     * shape's `side` wins.
     */
    iconSide?: EuiFormControlLayoutIconsSignature['Args']['side'];
    /**
     * `'absolute'` overlays the icons on the control, `'static'` lays them
     * out beside it. Defaults to `'absolute'`.
     */
    iconsPosition?: 'absolute' | 'static';
    /**
     * Shows a clear ("x") button calling this function, or with these props
     * (upstream `clear`): `{ onClick, disabled, size, … }`, other keys
     * (`data-test-subj`, `aria-label`, …) being its attributes.
     */
    clear?: EuiFormControlLayoutIconsSignature['Args']['clear'];
    /** Accessible label of the clear button. Defaults to "Clear input". */
    clearLabel?: string;
    /** Shows a spinner. */
    isLoading?: boolean;
    /**
     * Id of the control. `EuiFormPrepend` / `EuiFormAppend` labels in the
     * `<:prepend>` / `<:append>` blocks point to it (upstream `inputId`).
     */
    inputId?: string;
    /** @private Render the `<:prepend>` block. Defaults to `true`. */
    isPrependProvided?: boolean;
    /** @private Render the `<:append>` block. Defaults to `true`. */
    isAppendProvided?: boolean;
    /** @private Group styling without the `--group` class (EuiFormControlLayoutDelimited). */
    isDelimited?: boolean;
    /**
     * Color of `@icon`, anything `EuiIcon`'s `@color` accepts (upstream's
     * `icon.color`).
     */
    iconColor?: EuiIconSignature['Args']['color'];
    /**
     * Extra styles composed last into `@icon`'s EuiIcon class (upstream's
     * `icon.css`).
     */
    iconCss?: EuiCss;
    /**
     * Extra styles composed last into this component's class (like upstream's
     * `css` prop). Prefer this to an extra class when styling it from a parent.
     */
    css?: EuiCss;
    /** @private Extra styles composed last onto the children wrapper. */
    wrapperCss?: EuiCss;
    /**
     * Extra props for the `.euiFormControlLayout__childrenWrapper` element
     * (upstream `wrapperProps`): `className`, `id`, `aria-label`,
     * `data-test-subj` and `css` (extra styles composed last into its
     * class).
     */
    wrapperProps?: EuiFormControlLayoutWrapperProps;
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
  /**
   * Upstream `EuiFormControlLayoutContext`: EuiFormAppend, EuiFormPrepend and
   * EuiFormControlButton inherit these (no DOM is rendered for it).
   */
  @provide(EUI_FORM_CONTROL_LAYOUT_CONTEXT)
  get formControlLayoutContext(): EuiFormControlLayoutContext {
    // eslint-disable-next-line @typescript-eslint/no-this-alias
    const layout = this;
    return {
      get compressed() {
        return layout.compressed;
      },
      get inputId() {
        return layout.args.inputId;
      },
      get isDisabled() {
        return layout.isDisabled;
      },
      get isInvalid() {
        return layout.args.isInvalid;
      },
      get isLoading() {
        return layout.args.isLoading;
      },
      get readOnly() {
        return layout.args.readOnly;
      }
    };
  }
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
    return iconSideOf(this.args.icon, this.args.iconSide);
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
      this.args.css
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
      this.args.wrapperProps?.css,
      this.args.wrapperCss
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
          class="euiFormControlLayout__childrenWrapper
            {{@wrapperProps.className}}
            {{this.wrapperClasses isGroup}}"
          id={{@wrapperProps.id}}
          aria-label={{@wrapperProps.aria-label}}
          data-test-subj={{@wrapperProps.data-test-subj}}
          style={{this.iconStyle}}
        >
          {{#if this.hasLeftIcon}}
            <EuiFormControlLayoutIcons
              @side="left"
              @icon={{@icon}}
              @iconColor={{@iconColor}}
              @iconCss={{@iconCss}}
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
              @iconColor={{@iconColor}}
              @iconCss={{@iconCss}}
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
