import { concat } from '@ember/helper';

import randomId from '../-private/random-id.ts';
import EuiAccordion from './eui-accordion.gts';
import EuiText from './eui-text.gts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

const objectAt = <T,>(pos: number, array: T[]) => array[pos];
// everything after the first message (duplicates of it included)
const afterFirst = <T,>(array: T[]) => array.slice(1);

/** @private The messages of an EuiNotificationEvent. */
export interface EuiNotificationEventMessagesSignature {
  Element: HTMLDivElement;
  Args: {
    /** The messages: the first is shown, the rest in an accordion. */
    messages: string[];
    /** Text of the accordion button. */
    accordionButtonText?: string;
    /** Text next to the button while closed. */
    accordionHideText?: string;
    /** @deprecated Has no effect. */
    accordionAriaLabelButtonText?: string;
  };
}

const EuiNotificationEventMessages: TemplateOnlyComponent<EuiNotificationEventMessagesSignature> =
  <template>
    <div class="euiNotificationEventMessages" ...attributes>
      {{#let
        (objectAt 0 @messages) (afterFirst @messages)
        as |first rest|
      }}

        {{#if first}}
          <EuiText @size="s" @color="subdued">
            <p>{{first}}</p>
          </EuiText>
        {{/if}}

        {{#if rest}}

          <EuiAccordion
            id={{concat "euiNotificationEventMessagesAccordion" (randomId)}}
            class="euiNotificationEventMessages__accordion"
            @buttonClassName="euiNotificationEventMessages__accordionButton"
            @arrowDisplay="none"
          >
            <:buttonContent as |isOpen|>
              {{@accordionButtonText}}
              {{#unless isOpen}}
                ({{@accordionHideText}})
              {{/unless}}
            </:buttonContent>

            <:content>
              <div class="euiNotificationEventMessages__accordionContent">
                {{#each rest as |msg|}}
                  <EuiText @size="s" @color="subdued">
                    <p>{{msg}}</p>
                  </EuiText>
                {{/each}}
              </div>
            </:content>

          </EuiAccordion>
        {{/if}}

      {{/let}}
    </div>
  </template>;

export default EuiNotificationEventMessages;
