import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { concat, fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { guidFor } from '@ember/object/internals';

import optional from '@nullvoxpopuli/ember-composable-helpers/helpers/optional';
import queue from '@nullvoxpopuli/ember-composable-helpers/helpers/queue';
import { and, eq, not } from 'ember-truth-helpers';

import { deprecateRemovedUpstream } from '../-private/removed-upstream.ts';
import useState from '../helpers/use-state.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiNotificationEventStyles } from '../utils/eui/notification-event.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import EuiBadge from './eui-badge.gts';
import EuiButtonIcon from './eui-button-icon.gts';
import EuiIcon from './eui-icon.gts';
import EuiPopover from './eui-popover.gts';

import type { EuiBadgeSignature } from './eui-badge';
import type { EuiIconSignature } from './eui-icon';
import type Owner from '@ember/owner';

/** @private The source, time and menu row of an EuiNotificationEvent. */
export interface EuiNotificationEventMetaSignature {
  Element: HTMLDivElement;
  Args: {
    /** Id of the event. */
    id?: string;
    /** The event's title, for the context menu button's label. */
    eventName?: string;
    /** When it happened. */
    time?: string;
    /** Kind of event, shown in a badge. */
    type?: string;
    /** Appended to the badge. */
    severity?: string;
    /** Icon before the badge. */
    iconType?: EuiIconSignature['Args']['type'];
    /** Color of the icon. */
    iconColor?: EuiIconSignature['Args']['color'];
    /** Accessible label of the icon. */
    iconAriaLabel?: EuiIconSignature['Args']['aria-label'];
    /** Color of the badge. */
    badgeColor?: EuiBadgeSignature['Args']['color'];
    /** @private Render the context menu. Defaults to `true`. */
    hasDefaultBlock?: boolean;
    /** Called when the context menu button is clicked. */
    onOpenContextMenu?: (e: MouseEvent) => void;
  };
  Blocks: {
    /** Context menu content. */
    default: [];
  };
}

/** @deprecated Use `EuiNotificationEventMetaSignature`. */
export type EuiNotificationEventSignature = EuiNotificationEventMetaSignature;

export default class EuiNotificationEventMeta extends Component<EuiNotificationEventMetaSignature> {
  constructor(owner: Owner, args: EuiNotificationEventMetaSignature['Args']) {
    super(owner, args);
    deprecateRemovedUpstream(
      'eui-notification-event-meta',
      'EuiNotificationEventMeta',
      'Compose notifications from EuiPanel, EuiTitle, EuiText and EuiContextMenu instead.'
    );
  }

  popoverId = `euiNotificationEventMeta${guidFor(this)}`;

  get context() {
    return getEuiThemeContext(this);
  }

  @cached
  get styles() {
    return useEuiBorealisStyles(this.context, euiNotificationEventStyles);
  }

  @cached
  get sectionClass(): string {
    return euiClass(this.context, this.styles.metaSection);
  }

  @cached
  get timeClass(): string {
    return euiClass(this.context, this.styles.metaTime);
  }

  @cached
  get contextMenuClass(): string {
    return euiClass(this.context, this.styles.metaContextMenu);
  }

  get iconCss() {
    return this.styles.metaIcon;
  }

  metaClass = (hasContextMenu: boolean): string =>
    euiClass(
      this.context,
      this.styles.meta,
      hasContextMenu && this.styles.metaHasContextMenu
    );

  get contextMenuLabel(): string {
    return `Menu for ${this.args.eventName ?? ''}`.trim();
  }

  <template>
    {{#let
      (and (not (eq @hasDefaultBlock false)) (has-block))
      as |hasDefaultBlock|
    }}
      <div
        class="euiNotificationEventMeta {{this.metaClass hasDefaultBlock}}"
        ...attributes
      >
        <div class="euiNotificationEventMeta__section {{this.sectionClass}}">
          {{#if @iconType}}
            <EuiIcon
              @iconClasses="euiNotificationEventMeta__icon"
              @type={{@iconType}}
              @color={{@iconColor}}
              @aria-label={{@iconAriaLabel}}
              @css={{this.iconCss}}
            />
          {{/if}}

          {{#if @type}}
            <EuiBadge
              class="euiNotificationEventMeta__badge"
              @color={{@badgeColor}}
            >
              {{#if @severity}}
                {{@type}}:
                {{@severity}}
              {{else}}
                {{@type}}
              {{/if}}
            </EuiBadge>
          {{/if}}
        </div>

        <div class="euiNotificationEventMeta__section {{this.sectionClass}}">
          <span class="euiNotificationEventMeta__time {{this.timeClass}}">{{@time}}</span>
        </div>

        {{#if hasDefaultBlock}}
          {{#let (useState false) as |isPopoverOpen|}}
            <div
              class="euiNotificationEventMeta__contextMenuWrapper {{this.contextMenuClass}}"
            >
              <EuiPopover
                id={{this.popoverId}}
                @ownFocus={{true}}
                @repositionOnScroll={{true}}
                @isOpen={{isPopoverOpen.value}}
                @panelPaddingSize="none"
                @anchorPosition="leftUp"
                @closePopover={{fn isPopoverOpen.setState false}}
              >
                <:button>
                  <EuiButtonIcon
                    aria-label={{this.contextMenuLabel}}
                    aria-controls={{this.popoverId}}
                    aria-expanded={{if isPopoverOpen.value "true" "false"}}
                    aria-haspopup="true"
                    @iconType="boxesVertical"
                    @color="text"
                    data-test-subj={{concat @id "-notificationEventMetaButton"}}
                    {{on
                      "click"
                      (if
                        isPopoverOpen.value
                        (fn isPopoverOpen.setState false)
                        (fn isPopoverOpen.setState true)
                      )
                    }}
                  />
                </:button>

                {{! The EuiContextMenu is wrapped with a div so it closes after an item is clicked }}
                <:content>
                  <div
                    {{on
                      "click"
                      (queue
                        (optional @onOpenContextMenu)
                        (fn isPopoverOpen.setState false)
                      )
                    }}
                    role="button"
                  >
                    {{yield}}
                  </div>
                </:content>
              </EuiPopover>
            </div>
          {{/let}}
        {{/if}}
      </div>
    {{/let}}
  </template>
}
