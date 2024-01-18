import { on } from '@ember/modifier';

import optional from 'ember-composable-helpers/helpers/optional';
import { element } from 'ember-element-helper';
import { and,eq, or } from 'ember-truth-helpers';

import randomId from '../-private/random-id';
import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';
import typeOf from '../helpers/type-of';
import EuiLink from './eui-link.gts';
import EuiNotificationEventMessages from './eui-notification-event-messages.gts';
import EuiNotificationEventMeta from './eui-notification-event-meta.gts';
import EuiNotificationEventReadButton from './eui-notification-event-read-button.gts';
import EuiNotificationEventReadIcon from './eui-notification-event-read-icon.gts';
import TextBlock from './text-block.gts';

import type { EuiBadgeSignature } from './eui-badge';
import type { EuiNotificationEventMessagesSignature } from './eui-notification-event-messages';
import type { TextBlockSignature } from './text-block';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiNotificationEventSignature {
  Element: any;
  Args: {
    id?: string;
    tagName?: string;
    hasContextMenuBlock?: boolean;
    hasPrimaryActionBlock?: boolean;
    isRead?: boolean;
    href?: string;
    onClickTitle?: (event: MouseEvent) => void;
    onRead?: (event: MouseEvent) => void;
    onOpenContextMenu?: (event: MouseEvent) => void;
    title?: string;
    type?: string;
    severity?: string;
    badgeColor?: EuiBadgeSignature['Args']['color'];
    iconType?: string;
    iconAriaLabel?: string;
    time?: string;
    iconColor?: string;
    readIconColor?: string;
    headingLevel?: TextBlockSignature['Args']['tagName'];
    messages: EuiNotificationEventMessagesSignature['Args']['messages'];
    accordionButtonText?: EuiNotificationEventMessagesSignature['Args']['accordionButtonText'];
    accordionHideText?: EuiNotificationEventMessagesSignature['Args']['accordionHideText'];
  };
  Blocks: {
    default: [];
    contextMenu: [];
    primaryAction: [];
  };
}

const EuiNotificationEvent: TemplateOnlyComponent<EuiNotificationEventSignature> =
  <template>
    {{#let
      (randomId)
      (element (argOrDefault @tagName "article"))
      (and (argOrDefault @hasContextMenuBlock true) (has-block "contextMenu"))
      (and
        (argOrDefault @hasPrimaryActionBlock true) (has-block "primaryAction")
      )
      as |id Element hasContextMenuBlock hasPrimaryActionBlock|
    }}
      <Element
        aria-labelledby={{id}}
        key={{@id}}
        class={{classNames
          "euiNotificationEvent"
          (if
            (eq (typeOf @isRead) "boolean")
            "euiNotificationEvent--withReadState"
          )
        }}
        ...attributes
      >

        {{#if (eq (typeOf @isRead) "boolean")}}
          <div class="euiNotificationEvent__readButton">
            {{#if @onRead}}
              <EuiNotificationEventReadButton
                @id={{@id}}
                @isRead={{@isRead}}
                @eventName={{@title}}
                {{on "click" @onRead}}
              />
            {{else}}
              <EuiNotificationEventReadIcon
                @id={{@id}}
                @isRead={{@isRead}}
                @eventName={{@title}}
                @readIconColor={{@readIconColor}}
              />
            {{/if}}
          </div>
        {{/if}}

        <div class="euiNotificationEvent__content">
          <EuiNotificationEventMeta
            @id={{@id}}
            @type={{@type}}
            @severity={{@severity}}
            @badgeColor={{@badgeColor}}
            @iconType={{@iconType}}
            @iconAriaLabel={{@iconAriaLabel}}
            @time={{@time}}
            @onOpenContextMenu={{@onOpenContextMenu}}
            @hasDefaultBlock={{hasContextMenuBlock}}
            @iconColor={{@iconColor}}
          >
            {{yield to="contextMenu"}}
          </EuiNotificationEventMeta>

          {{#let
            (classNames
              "euiNotificationEvent__title"
              (if @isRead "euiNotificationEvent__title--isRead")
            )
            (argOrDefault @headingLevel "h2")
            as |classNames headingLevel|
          }}
            {{#if (or @href @onClickTitle)}}
              <EuiLink
                class={{classNames}}
                id={{id}}
                @href={{@href}}
                {{on "click" (optional @onClickTitle)}}
              >
                <TextBlock @tagName={{headingLevel}}>
                  {{@title}}
                </TextBlock>
              </EuiLink>
            {{else if @title}}
              <TextBlock
                id={{id}}
                class={{classNames}}
                @tagName={{headingLevel}}
              >
                {{@title}}
              </TextBlock>
            {{/if}}
          {{/let}}

          <EuiNotificationEventMessages
            @messages={{@messages}}
            @accordionButtonText={{@accordionButtonText}}
            @accordionHideText={{@accordionHideText}}
          />

          {{#if hasPrimaryActionBlock}}
            <div class="euiNotificationEvent__primaryAction">
              {{yield to="primaryAction"}}
            </div>
          {{/if}}

        </div>

      </Element>
    {{/let}}
  </template>;

export default EuiNotificationEvent;
