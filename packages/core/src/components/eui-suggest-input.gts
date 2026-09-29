import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { action } from '@ember/object';

import EuiFieldText from './eui-field-text.gts';
import EuiIcon from './eui-icon.gts';
import EuiInputPopover from './eui-input-popover.gts';
import EuiToolTip from './eui-tool-tip.gts';

const STATUS = {
  unsaved: { icon: 'dot', color: 'accent', tooltip: 'Changes have not been saved.' },
  saved: { icon: 'checkInCircleFilled', color: 'success', tooltip: 'Saved.' }
} as const;

export type EuiSuggestStatus = 'unchanged' | 'unsaved' | 'saved' | 'loading';

/**
 * The text field of an `EuiSuggest`, opening a popover with the
 * suggestions while it has text. Usually rendered for you by `EuiSuggest`.
 */
export interface EuiSuggestInputSignature {
  Element: HTMLInputElement;
  Args: {
    /** Whether there are suggestions to show (the popover opens only then). */
    hasSuggestions: boolean;
    /**
     * `'unsaved'` (dot), `'saved'` (check), `'loading'` (spinner) or
     * `'unchanged'` (nothing). Defaults to `'unchanged'`.
     */
    status?: EuiSuggestStatus;
    /** Tooltip of the status icon, instead of "Saved." / "Changes have not been saved.". */
    tooltipContent?: string;
    /** Called with the field's text on every change. */
    sendValue?: (value: string) => void;
    /** Placeholder of the field. */
    placeholder?: string;
    /** @private Closes the popover (set after a suggestion is clicked). */
    registerClose?: (close: () => void) => void;
  };
  Blocks: {
    /** The suggestions, shown in the popover. */
    default: [];
    /** Content after the field (and the status icon). */
    append: [];
  };
}

export default class EuiSuggestInput extends Component<EuiSuggestInputSignature> {
  @tracked value = '';
  @tracked isPopoverOpen = false;

  constructor(...args: ConstructorParameters<typeof Component<EuiSuggestInputSignature>>) {
    super(...args);
    this.args.registerClose?.(this.closePopover);
  }

  get statusIcon(): (typeof STATUS)[keyof typeof STATUS] | undefined {
    const status = this.args.status;

    return status === 'saved' || status === 'unsaved' ? STATUS[status] : undefined;
  }

  get tooltip(): string | undefined {
    return this.args.tooltipContent ?? this.statusIcon?.tooltip;
  }

  @action
  onInput(event: Event): void {
    this.value = (event.target as HTMLInputElement).value;
    this.isPopoverOpen = this.value !== '';
    this.args.sendValue?.(this.value);
  }

  @action
  closePopover(): void {
    this.isPopoverOpen = false;
  }

  <template>
    <EuiInputPopover
      class="euiSuggestInput"
      @isOpen={{and2 @hasSuggestions this.isPopoverOpen}}
      @closePopover={{this.closePopover}}
      @panelPaddingSize="none"
      @fullWidth={{true}}
      @disableFocusTrap={{true}}
    >
      <:input>
        {{#if (or2 this.statusIcon (has-block "append"))}}
          <EuiFieldText
            @value={{this.value}}
            @fullWidth={{true}}
            @isLoading={{eq2 @status "loading"}}
            @placeholder={{@placeholder}}
            {{on "input" this.onInput}}
            ...attributes
          >
            <:append as |className|>
              <div class={{className}}>
                {{#if this.statusIcon}}
                  <EuiToolTip @position="left" @content={{this.tooltip}}>
                    <EuiIcon
                      class="euiSuggestInput__statusIcon"
                      @type={{this.statusIcon.icon}}
                      @color={{this.statusIcon.color}}
                    />
                  </EuiToolTip>
                {{/if}}
                {{yield to="append"}}
              </div>
            </:append>
          </EuiFieldText>
        {{else}}
          <EuiFieldText
            @value={{this.value}}
            @fullWidth={{true}}
            @isLoading={{eq2 @status "loading"}}
            @placeholder={{@placeholder}}
            {{on "input" this.onInput}}
            ...attributes
          />
        {{/if}}
      </:input>
      <:content>
        {{yield}}
      </:content>
    </EuiInputPopover>
  </template>
}

function and2(a: unknown, b: unknown): boolean {
  return Boolean(a && b);
}

function or2(a: unknown, b: unknown): boolean {
  return Boolean(a || b);
}

function eq2(a: unknown, b: unknown): boolean {
  return a === b;
}
