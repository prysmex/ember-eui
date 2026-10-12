import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { action } from '@ember/object';

import { formControlLayoutContext } from '../../-private/eui-form-control-layout-context.ts';
import { getEuiThemeContext } from '../../utils/emotion/consume.ts';
import { buttonReset } from '../../utils/eui/form-controls.ts';
import {
  euiFormAppendPrependStyles,
  euiFormLabelStyles,
  euiTextTruncate
} from '../../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../../utils/eui/styles.ts';
import EuiFormLabel, { euiFormLabelReset } from '../eui-form-label.gts';
import EuiIcon from '../eui-icon.gts';

import type { EuiCss } from '../../utils/eui/styles.ts';
import type { EuiIconSignature } from '../eui-icon';

/** Arguments shared by `EuiFormAppend` and `EuiFormPrepend`. */
export interface EuiFormAppendPrependArgs {
  /**
   * `'button'` renders a `<button>` (interactive styles, label as text);
   * `'div'` a static node whose label is a `<label>` for `@inputId`.
   * Defaults to `'button'` when `@onClick` is passed, `'div'` otherwise.
   */
  element?: 'div' | 'button';
  /** Main text, rendered as an `EuiFormLabel` (a `<span>` in a button). */
  label?: string;
  /** Icon before the label; anything `EuiIcon`'s `@type` accepts. */
  iconLeft?: EuiIconSignature['Args']['type'];
  /** Icon after the label; anything `EuiIcon`'s `@type` accepts. */
  iconRight?: EuiIconSignature['Args']['type'];
  /**
   * Id of the control the `<label>` points to (`for`). Defaults to the
   * surrounding `EuiFormControlLayout`'s `@inputId`.
   */
  inputId?: string;
  /** Id of the label element (upstream passes `id` to the label). */
  id?: string;
  /**
   * Smaller padding. Defaults to the surrounding `EuiFormControlLayout`'s
   * `@compressed`.
   */
  compressed?: boolean;
  /**
   * Disables the button / greys out the node. A static node also follows
   * the surrounding layout's disabled state.
   */
  isDisabled?: boolean;
  /** Same as `@isDisabled`. */
  disabled?: boolean;
  /** Click handler; renders a `<button>` (upstream `onClick`). */
  onClick?: (event: MouseEvent) => void;
  /**
   * Extra styles composed last into this component's class (like upstream's
   * `css` prop). Prefer this to an extra class when styling it from a parent.
   */
  css?: EuiCss;
}

export interface EuiFormAppendPrependSignature {
  Element: HTMLDivElement | HTMLButtonElement;
  Args: EuiFormAppendPrependArgs & {
    /** @private Which side of the control: sets the root class. */
    side: 'append' | 'prepend';
  };
  Blocks: {
    /** Content after the label and icons. */
    default: [];
  };
}

/**
 * @private Upstream `EuiFormAppendPrepend`: the shared implementation of
 * `EuiFormAppend` / `EuiFormPrepend`.
 */
export default class EuiFormAppendPrepend extends Component<EuiFormAppendPrependSignature> {
  get context() {
    return getEuiThemeContext(this);
  }
  get layout() {
    return formControlLayoutContext(this);
  }
  get rootClass() {
    return this.args.side === 'append' ? 'euiFormAppend' : 'euiFormPrepend';
  }
  get isButton() {
    return (
      this.args.element === 'button' || typeof this.args.onClick === 'function'
    );
  }
  get compressed() {
    return this.args.compressed ?? this.layout.compressed;
  }
  get inputId() {
    return this.args.inputId ?? (this.layout.inputId || undefined);
  }
  get isDisabled() {
    return Boolean(
      this.args.isDisabled ||
        this.args.disabled ||
        (!this.isButton && this.layout.isDisabled)
    );
  }

  /** Upstream wrapper: draws the focus ring around a focused button side. */
  @cached
  get wrapperClass() {
    const styles = useEuiBorealisStyles(
      this.context,
      euiFormAppendPrependStyles
    );
    return euiClass(this.context, { boxSizing: 'border-box' }, styles.wrapper);
  }

  @cached
  get classes() {
    const context = this.context;
    const styles = useEuiBorealisStyles(context, euiFormAppendPrependStyles);
    const isButton = this.isButton;
    const isDisabled = this.isDisabled;
    return `${this.rootClass} ${euiClass(
      context,
      // React's global reset: border-box everywhere, and the button reset.
      { boxSizing: 'border-box' },
      isButton && buttonReset,
      isButton && { fontFamily: context.upstream.euiTheme.font.family },
      styles.side,
      this.compressed ? styles.compressed : styles.uncompressed,
      isButton && !isDisabled && styles.isInteractive,
      isDisabled && styles.disabled,
      this.args.css
    )}`;
  }

  /** `EuiFormLabel type="span"` (with the truncation utility) in a button. */
  @cached
  get spanLabelClass() {
    const context = this.context;
    const styles = useEuiBorealisStyles(context, euiFormLabelStyles);
    return `euiFormLabel eui-textTruncate ${euiClass(
      context,
      euiFormLabelReset(context.upstream),
      styles.euiFormLabel,
      styles.notDisabled,
      euiTextTruncate()
    )}`;
  }

  @action
  onClick(event: MouseEvent) {
    this.args.onClick?.(event);
  }

  <template>
    <div class={{this.wrapperClass}}>
      {{#if this.isButton}}
        <button
          type="button"
          class={{this.classes}}
          disabled={{this.isDisabled}}
          ...attributes
          {{on "click" this.onClick}}
        >
          {{#if @iconLeft}}
            <EuiIcon @type={{@iconLeft}} />
          {{/if}}
          {{#if @label}}
            <span id={{@id}} class={{this.spanLabelClass}}>{{@label}}</span>
          {{/if}}
          {{#if @iconRight}}
            <EuiIcon @type={{@iconRight}} />
          {{/if}}
          {{yield}}
        </button>
      {{else}}
        <div class={{this.classes}} ...attributes>
          {{#if @iconLeft}}
            <EuiIcon @type={{@iconLeft}} />
          {{/if}}
          {{#if @label}}
            <EuiFormLabel id={{@id}} @for={{this.inputId}}>{{@label}}</EuiFormLabel>
          {{/if}}
          {{#if @iconRight}}
            <EuiIcon @type={{@iconRight}} />
          {{/if}}
          {{yield}}
        </div>
      {{/if}}
    </div>
  </template>
}
