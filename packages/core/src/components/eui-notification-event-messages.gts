import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { guidFor } from '@ember/object/internals';

import { deprecateRemovedUpstream } from '../-private/removed-upstream.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiNotificationEventStyles } from '../utils/eui/notification-event.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import EuiAccordion from './eui-accordion.gts';
import EuiText from './eui-text.gts';
import type Owner from '@ember/owner';

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

export default class EuiNotificationEventMessages extends Component<EuiNotificationEventMessagesSignature> {
  constructor(owner: Owner, args: EuiNotificationEventMessagesSignature['Args']) {
    super(owner, args);
    deprecateRemovedUpstream(
      'eui-notification-event-messages',
      'EuiNotificationEventMessages',
      'Compose notifications from EuiPanel, EuiTitle, EuiText and EuiContextMenu instead.'
    );
  }

  accordionId = `euiNotificationEventMessagesAccordion${guidFor(this)}`;

  get context() {
    return getEuiThemeContext(this);
  }

  @cached
  get styles() {
    return useEuiBorealisStyles(this.context, euiNotificationEventStyles);
  }

  @cached
  get classes(): string {
    return euiClass(this.context, this.styles.messages);
  }

  @cached
  get contentClass(): string {
    return euiClass(this.context, this.styles.accordionContent);
  }

  /** Composed into the accordion trigger's own class (`buttonProps.css`). */
  @cached
  get buttonProps() {
    return { css: this.styles.accordionButton };
  }

  get first(): string | undefined {
    return this.args.messages?.[0];
  }

  /** Everything after the first message (duplicates of it included). */
  get rest(): string[] {
    return this.args.messages?.slice(1) ?? [];
  }

  <template>
    <div class="euiNotificationEventMessages {{this.classes}}" ...attributes>
      {{#if this.first}}
        <EuiText @size="s" @color="subdued">
          <p>{{this.first}}</p>
        </EuiText>
      {{/if}}

      {{#if this.rest.length}}
        <EuiAccordion
          @id={{this.accordionId}}
          class="euiNotificationEventMessages__accordion"
          @buttonClassName="euiNotificationEventMessages__accordionButton"
          @buttonProps={{this.buttonProps}}
          @arrowDisplay="none"
        >
          <:buttonContent as |isOpen|>
            {{@accordionButtonText}}
            {{#unless isOpen}}
              ({{@accordionHideText}})
            {{/unless}}
          </:buttonContent>

          <:content>
            <div
              class="euiNotificationEventMessages__accordionContent {{this.contentClass}}"
            >
              {{#each this.rest as |msg|}}
                <EuiText @size="s" @color="subdued">
                  <p>{{msg}}</p>
                </EuiText>
              {{/each}}
            </div>
          </:content>
        </EuiAccordion>
      {{/if}}
    </div>
  </template>
}
