import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { service } from '@ember/service';

import classNames from '../../helpers/class-names.ts';
import EuiButton from '../eui-button.gts';
import EuiButtonIcon from '../eui-button-icon.gts';

import type EuiI18n from '../../services/eui-i18n';
import type { EuiButtonSignature } from '../eui-button';
import type { EuiButtonIconSignature } from '../eui-button-icon';

/** @private EuiSuperDatePicker's refresh / update button. */
export interface EuiSuperUpdateButtonSignature {
  Element: EuiButtonIconSignature['Element'] | EuiButtonSignature['Element'];
  Args: {
    /** Extra class(es). */
    className?: string;
    /** Solid button. Defaults to `true` (upstream). */
    fill?: boolean;
    /** Shows only the icon (the label stays as its accessible name). */
    iconOnly?: boolean;
    /** Disables it. */
    isDisabled?: boolean;
    /** Loading state. */
    isLoading?: boolean;
    /** Highlights that the range changed and needs applying. */
    needsUpdate?: boolean;
    /** Called on click. */
    onClick: (e: MouseEvent) => void;
    /** Size of the button. */
    size?: EuiButtonIconSignature['Args']['size'];
    /** Classes for the text. */
    textClasses?: string;
    /**
     * Button color, instead of `primary` (`success` while an update is
     * pending or loading).
     */
    color?: EuiButtonSignature['Args']['color'];
    /** Icon, instead of `refresh` (`push` while an update is pending). */
    iconType?: string;
    /**
     * Custom label (upstream `children`), instead of "Refresh" / "Update" /
     * "Updating"; keep it in sync with `@needsUpdate` and `@isLoading`.
     */
    label?: string;
    /**
     * Minimum width of the text button, a number of px or a CSS length;
     * `false` removes it. Defaults to `118`.
     */
    minWidth?: number | string | false;
  };
}

/**
 * Upstream `EuiSuperUpdateButtonProps` as EuiSuperDatePicker's
 * `@updateButtonProps` takes them (the arguments it can forward).
 */
export interface EuiSuperUpdateButtonProps {
  fill?: boolean;
  color?: EuiButtonSignature['Args']['color'];
  size?: EuiButtonIconSignature['Args']['size'];
  iconType?: string;
  iconOnly?: boolean;
  className?: string;
  /** A custom label (upstream `children`). */
  children?: string;
  minWidth?: number | string | false;
  'data-test-subj'?: string;
}

export default class EuiSuperUpdateButton extends Component<EuiSuperUpdateButtonSignature> {
  @service declare euiI18n: EuiI18n;

  get isActive() {
    return Boolean(this.args.needsUpdate || this.args.isLoading);
  }

  get color() {
    return this.args.color ?? (this.isActive ? 'success' : 'primary');
  }

  /** Upstream uses `push` while an update is pending or loading. */
  get iconType() {
    return this.args.iconType ?? (this.isActive ? 'push' : 'refresh');
  }

  /** Upstream `minWidth={118}` (an inline style), overridable through the props. */
  @cached
  get minWidthCss() {
    const { minWidth } = this.args;
    if (minWidth === false) return undefined;
    const value = minWidth ?? 118;
    return { minInlineSize: typeof value === 'number' ? `${value}px` : value };
  }

  /** Upstream passes `size` to EuiButton, whose default is `m`. */
  get size() {
    return this.args.size ?? 'm';
  }

  get fill() {
    return this.args.fill ?? true;
  }

  get label() {
    if (this.args.label) return this.args.label;

    if (this.args.isLoading) {
      return this.euiI18n.lookupToken(
        'euiSuperUpdateButton.updatingButtonLabel',
        'Updating'
      );
    }

    if (this.args.needsUpdate) {
      return this.euiI18n.lookupToken(
        'euiSuperUpdateButton.updateButtonLabel',
        'Update'
      );
    }

    return this.euiI18n.lookupToken(
      'euiSuperUpdateButton.refreshButtonLabel',
      'Refresh'
    );
  }

  <template>
    {{#if @iconOnly}}
      <EuiButtonIcon
        class={{classNames "euiSuperUpdateButton" @className}}
        aria-label={{this.label}}
        data-test-subj="superDatePickerApplyTimeButton"
        @display={{if this.fill "fill" "base"}}
        @color={{this.color}}
        @iconType={{this.iconType}}
        @isDisabled={{@isDisabled}}
        @isLoading={{@isLoading}}
        @size={{this.size}}
        {{on "click" @onClick}}
        ...attributes
      />
    {{else}}
      <EuiButton
        class={{classNames "euiSuperUpdateButton" @className}}
        data-test-subj="superDatePickerApplyTimeButton"
        @css={{this.minWidthCss}}
        @fill={{this.fill}}
        @textClasses={{@textClasses}}
        @color={{this.color}}
        @iconType={{this.iconType}}
        @isDisabled={{@isDisabled}}
        @isLoading={{@isLoading}}
        @size={{this.size}}
        {{on "click" @onClick}}
        ...attributes
      >
        {{this.label}}
      </EuiButton>
    {{/if}}
  </template>
}
