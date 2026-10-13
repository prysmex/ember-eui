import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { guidFor } from '@ember/object/internals';

import { and, eq, not, or } from 'ember-truth-helpers';

import { deprecateRemovedUpstream } from '../-private/removed-upstream.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiNotificationEventStyles } from '../utils/eui/notification-event.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
import EuiLink from './eui-link.gts';
import EuiTitle from './eui-title.gts';
import EuiNotificationEventMessages from './eui-notification-event-messages.gts';
import EuiNotificationEventMeta from './eui-notification-event-meta.gts';
import EuiNotificationEventReadButton from './eui-notification-event-read-button.gts';
import EuiNotificationEventReadIcon from './eui-notification-event-read-icon.gts';

import type { EuiBadgeSignature } from './eui-badge';
import type { EuiIconSignature } from './eui-icon';
import type { EuiNotificationEventMessagesSignature } from './eui-notification-event-messages';
import type { TextBlockSignature } from './text-block';
import type Owner from '@ember/owner';

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
     * `@onRead`, otherwise an icon) and makes unread titles bold; leave it
     * undefined to show none.
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

/**
 * Native Ember notification event. EUI 123 has no counterpart (upstream
 * removed it); the Borealis styles live in `utils/eui/notification-event.ts`.
 */
export default class EuiNotificationEvent extends Component<EuiNotificationEventSignature> {
  constructor(owner: Owner, args: EuiNotificationEventSignature['Args']) {
    super(owner, args);
    deprecateRemovedUpstream(
      'eui-notification-event',
      'EuiNotificationEvent',
      'Compose notifications from EuiPanel, EuiTitle, EuiText and EuiContextMenu instead.'
    );
  }

  titleId = `euiNotificationEventTitle${guidFor(this)}`;

  get context() {
    return getEuiThemeContext(this);
  }

  @cached
  get styles() {
    return useEuiBorealisStyles(this.context, euiNotificationEventStyles);
  }

  get tagName(): string {
    return this.args.tagName ?? 'article';
  }

  get headingLevel(): TextBlockSignature['Args']['tagName'] {
    return this.args.headingLevel ?? 'h2';
  }

  get hasReadState(): boolean {
    return typeof this.args.isRead === 'boolean';
  }

  @cached
  get classes(): string {
    return euiClass(this.context, this.styles.euiNotificationEvent);
  }

  @cached
  get readButtonClass(): string {
    return euiClass(this.context, this.styles.readButton);
  }

  @cached
  get contentClass(): string {
    return euiClass(this.context, this.styles.content);
  }

  @cached
  get primaryActionClass(): string {
    return euiClass(this.context, this.styles.primaryAction);
  }

  /** The `EuiTitle` `xs` heading's `css`: bold while unread, regular once read. */
  @cached
  get titleCss(): EuiCss {
    return [this.styles.title, this.args.isRead && this.styles.titleIsRead];
  }

  onClickTitle = (event: MouseEvent): void => {
    this.args.onClickTitle?.(event);
  };

  <template>
    {{#let
      (element this.tagName)
      (and (not (eq @hasContextMenuBlock false)) (has-block "contextMenu"))
      (and
        (not (eq @hasPrimaryActionBlock false)) (has-block "primaryAction")
      )
      as |Element hasContextMenuBlock hasPrimaryActionBlock|
    }}
      <Element
        aria-labelledby={{this.titleId}}
        key={{@id}}
        class="euiNotificationEvent {{this.classes}}"
        ...attributes
      >
        {{#if this.hasReadState}}
          <div class="euiNotificationEvent__readButton {{this.readButtonClass}}">
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

        <div class="euiNotificationEvent__content {{this.contentClass}}">
          <EuiNotificationEventMeta
            @id={{@id}}
            @eventName={{@title}}
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

          {{#if (or @href @onClickTitle)}}
            <EuiLink
              class="euiNotificationEvent__title"
              id={{this.titleId}}
              @href={{@href}}
              {{on "click" this.onClickTitle}}
            >
              <EuiTitle
                @tagName={{this.headingLevel}}
                @size="xs"
                @css={{this.titleCss}}
              >{{@title}}</EuiTitle>
            </EuiLink>
          {{else if @title}}
            <EuiTitle
              id={{this.titleId}}
              class="euiNotificationEvent__title"
              @tagName={{this.headingLevel}}
              @size="xs"
              @css={{this.titleCss}}
            >{{@title}}</EuiTitle>
          {{/if}}

          <EuiNotificationEventMessages
            @messages={{@messages}}
            @accordionButtonText={{@accordionButtonText}}
            @accordionHideText={{@accordionHideText}}
          />

          {{#if hasPrimaryActionBlock}}
            <div
              class="euiNotificationEvent__primaryAction {{this.primaryActionClass}}"
            >
              {{yield to="primaryAction"}}
            </div>
          {{/if}}
        </div>
      </Element>
    {{/let}}
  </template>
}
