import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';

import { eq } from 'ember-truth-helpers';

import { getEuiThemeContext } from '../../../utils/emotion/consume.ts';
import { euiPaddingSize } from '../../../utils/eui/styles.generated.ts';
import type { EuiCss } from '../../../utils/eui/styles.ts';
import EuiButton from '../../eui-button.gts';
import EuiI18n from '../../eui-i18n.gts';
import EuiText from '../../eui-text.gts';

/** @private The "Now" tab of the date popover. */
export interface NowTabSignature {
  Args: {
    /** `'start'` or `'end'` of the range. */
    position?: 'start' | 'end';
    /** Called with the new value. */
    onChange: (value: string, event?: Event) => void;
  };
}

export default class EuiSuperDatePickerDatePopoverNowTab extends Component<NowTabSignature> {
  /** Upstream pads the text with `useEuiPaddingCSS().m` (EuiText `css`). */
  @cached
  get paddingCss(): EuiCss {
    const context = getEuiThemeContext(this);
    return { padding: euiPaddingSize(context.upstream, 'm') };
  }

  <template>
    <EuiText
      class="euiDatePopoverContent__now"
      @size="s"
      @color="subdued"
      @css={{this.paddingCss}}
    >
      <p>
        <EuiI18n
          @token="euiDatePopoverContent.nowTabContent"
          @default="Setting the time to now means that on every refresh this time will be set to the time of the refresh."
          as |Token|
        >
          <Token as |value|>
            {{value}}
          </Token>
        </EuiI18n>
      </p>
      <EuiButton
        data-test-subj="superDatePickerNowButton"
        @fullWidth={{true}}
        @size="s"
        @fill={{true}}
        {{on "click" (fn @onChange "now")}}
      >
        {{#if (eq @position "start")}}
          <EuiI18n
            @token="euiDatePopoverContent.nowTabButtonStart"
            @default="Set start date and time to now"
            as |Token|
          >
            <Token as |value|>
              {{value}}
            </Token>
          </EuiI18n>
        {{else}}
          <EuiI18n
            @token="euiDatePopoverContent.nowTabButtonEnd"
            @default="Set end date and time to now"
            as |Token|
          >
            <Token as |value|>
              {{value}}
            </Token>
          </EuiI18n>
        {{/if}}
      </EuiButton>
    </EuiText>
  </template>
}
