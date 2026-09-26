import { on } from '@ember/modifier';

import optional from '@nullvoxpopuli/ember-composable-helpers/helpers/optional';
import { element } from 'ember-element-helper';
import { and, eq, or } from 'ember-truth-helpers';

import randomId from '../-private/random-id.ts';
import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import typeOf from '../helpers/type-of.ts';
import EuiLink from './eui-link.gts';
import EuiNotificationEventMessages from './eui-notification-event-messages.gts';
import EuiNotificationEventMeta from './eui-notification-event-meta.gts';
import EuiNotificationEventReadButton from './eui-notification-event-read-button.gts';
import EuiNotificationEventReadIcon from './eui-notification-event-read-icon.gts';
import TextBlock from './text-block.gts';

import type { EuiBadgeSignature } from './eui-badge';
import type { EuiIconSignature } from './eui-icon';
import type { EuiNotificationEventMessagesSignature } from './eui-notification-event-messages';
import type { TextBlockSignature } from './text-block';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

/**
 * One notification in a list (e.g. a flyout from the header): title,
 * source, time, messages, read state and actions.
 */
export interface EuiNotificationEventSignature {
  Element: any;
  Args: {
    /** Id of the event, for its read button/icon. */
    id?: string;
    /** Tag of the event. Defaults to `'article'`. */
    tagName?: string;
    /** @private Render the `<:contextMenu>` block. Defaults to `true`. */
    hasContextMenuBlock?: boolean;
    /** @private Render the `<:primaryAction>` block. Defaults to `true`. */
    hasPrimaryActionBlock?: boolean;
    /**
     * Read state. When a boolean, shows a read indicator (a button with
     * `@onRead`, otherwise an icon); leave it undefined to show none.
     */
    isRead?: boolean;
    /** Makes the title a link. */
    href?: string;
    /** Makes the title a button calling this function. */
    onClickTitle?: (event: MouseEvent) => void;
    /** Called by the read button; toggle `@isRead` here. */
    onRead?: (event: MouseEvent) => void;
    /** Called when the context menu button is clicked. */
    onOpenContextMenu?: (event: MouseEvent) => void;
    /** The event's title. */
    title?: string;
    /** Kind of event shown in a badge, e.g. "Alert" or "Report". */
    type?: string;
    /** Severity appended to the badge, e.g. "Critical" ("Alert: Critical"). */
    severity?: string;
    /** Color of the type badge, any `EuiBadge` color. */
    badgeColor?: EuiBadgeSignature['Args']['color'];
    /** Icon before the badge, e.g. the app it comes from. */
    iconType?: EuiIconSignature['Args']['type'];
    /** Accessible label of `@iconType`; without it the icon is decorative. */
    iconAriaLabel?: string;
    /** When it happened, e.g. "2 min ago". */
    time?: string;
    /** Color of `@iconType`. */
    iconColor?: string;
    /** Color of the read indicator. Defaults to `'primary'`. */
    readIconColor?: string;
    /** Heading tag of the title. Defaults to `'h2'`. */
    headingLevel?: TextBlockSignature['Args']['tagName'];
    /**
     * The event's messages: the first is shown, the rest behind a
     * "show more" accordion.
     */
    messages: EuiNotificationEventMessagesSignature['Args']['messages'];
    /** Text of the button revealing the other messages, e.g. "+ 2 more". */
    accordionButtonText?: EuiNotificationEventMessagesSignature['Args']['accordionButtonText'];
    /** Text shown next to it while closed, e.g. "Show". */
    accordionHideText?: EuiNotificationEventMessagesSignature['Args']['accordionHideText'];
  };
  Blocks: {
    /** Unused. */
    default: [];
    /** Context menu content, e.g. an `EuiContextMenuPanel` of actions. */
    contextMenu: [];
    /** A primary action below the messages, e.g. a "View" button. */
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
