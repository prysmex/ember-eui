import Component from '@glimmer/component';
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
  };
}

export default class EuiSuperUpdateButton extends Component<EuiSuperUpdateButtonSignature> {
  @service declare euiI18n: EuiI18n;

  get isActive() {
    return Boolean(this.args.needsUpdate || this.args.isLoading);
  }

  get color() {
    return this.isActive ? 'success' : 'primary';
  }

  /** Upstream uses `push` while an update is pending or loading. */
  get iconType() {
    return this.isActive ? 'push' : 'refresh';
  }

  /** Upstream passes `size` to EuiButton, whose default is `m`. */
  get size() {
    return this.args.size ?? 'm';
  }

  get fill() {
    return this.args.fill ?? true;
  }

  get label() {
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
        {{! upstream minWidth={118} }}
        style="min-inline-size: 118px"
        data-test-subj="superDatePickerApplyTimeButton"
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
