import Component from '@glimmer/component';
import { on } from '@ember/modifier';
import { service } from '@ember/service';

import optional from '@nullvoxpopuli/ember-composable-helpers/helpers/optional';

import EuiButton from './eui-button.gts';

import type EuiI18n from '../services/eui-i18n';
import type { EuiButtonSignature } from './eui-button';

export type EuiCardSelectProps = {
  /**
   * Is in the selected state: shows a check icon, the "Selected" text and
   * the `success` color.
   */
  isSelected?: boolean;
  /** Disables the button and shows "Unavailable". */
  isDisabled?: boolean;
  /** Id of the button (EuiCard sets one). */
  buttonId?: string;
  /**
   * `EuiButton` color. Defaults to `'success'` when selected, `'text'`
   * otherwise.
   */
  color?: EuiButtonSignature['Args']['color'];
  /** Shows a spinner in the button. */
  isLoading?: EuiButtonSignature['Args']['isLoading'];
  /** Makes the button a link. */
  href?: EuiButtonSignature['Args']['href'];
  /** Side of the check icon. */
  iconSide?: EuiButtonSignature['Args']['iconSide'];
  /**
   * @deprecated Has no effect: upstream's card select is a full-width
   * EuiButton, which has no flush option.
   */
  flush?: 'left' | 'right' | 'both';
  /** `type` of the button. */
  type?: EuiButtonSignature['Args']['type'];
  /** Called when the button (or the whole card, in EuiCard) is clicked; toggle `isSelected` here. */
  onClick?: (e: MouseEvent) => void;
};

export function euiCardSelectableColor(
  color: string | undefined,
  isSelected: boolean | undefined
): string {
  let calculatedColor;

  if (color) {
    calculatedColor = color;
  } else if (isSelected) {
    calculatedColor = 'success';
  } else {
    calculatedColor = 'text';
  }

  return calculatedColor;
}

export interface EuiCardSelectSignature {
  Element: EuiButtonSignature['Element'];
  Args: EuiCardSelectProps;
  Blocks: {
    /** Custom text, instead of "Select" / "Selected" / "Unavailable". */
    default: [];
  };
}

/**
 * Upstream `EuiCardSelect` (EUI 123.1.0): a full-width `m` EuiButton with
 * `role="switch"`. Texts use the i18n tokens `euiCardSelect.select`,
 * `euiCardSelect.selected` and `euiCardSelect.unavailable`.
 */
export default class EuiCardSelectComponent extends Component<EuiCardSelectSignature> {
  @service declare euiI18n: EuiI18n;

  get color(): string {
    return euiCardSelectableColor(this.args.color, this.args.isSelected);
  }

  get text(): string {
    if (this.args.isSelected)
      return this.euiI18n.lookupToken('euiCardSelect.selected', 'Selected');
    if (this.args.isDisabled)
      return this.euiI18n.lookupToken(
        'euiCardSelect.unavailable',
        'Unavailable'
      );
    return this.euiI18n.lookupToken('euiCardSelect.select', 'Select');
  }

  <template>
    <EuiButton
      class="euiCardSelect"
      id={{@buttonId}}
      @color={{this.color}}
      @size="m"
      @fullWidth={{true}}
      @isDisabled={{@isDisabled}}
      @iconType={{if @isSelected "check" undefined}}
      @isLoading={{@isLoading}}
      @href={{@href}}
      @iconSide={{@iconSide}}
      @type={{@type}}
      role="switch"
      aria-checked={{if @isSelected "true" "false"}}
      {{on "click" (optional @onClick)}}
      ...attributes
    >
      {{#if (has-block)}}
        {{yield}}
      {{else}}
        {{this.text}}
      {{/if}}
    </EuiButton>
  </template>
}
