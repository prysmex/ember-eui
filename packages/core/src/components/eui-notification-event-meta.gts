import { concat } from '@ember/helper';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';

import optional from '@nullvoxpopuli/ember-composable-helpers/helpers/optional';
import queue from '@nullvoxpopuli/ember-composable-helpers/helpers/queue';
import { and } from 'ember-truth-helpers';

import randomId from '../-private/random-id.ts';
import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import useState from '../helpers/use-state.ts';
import EuiBadge from './eui-badge.gts';
import EuiButtonIcon from './eui-button-icon.gts';
import EuiIcon from './eui-icon.gts';
import EuiPopover from './eui-popover.gts';

import type { EuiBadgeSignature } from './eui-badge';
import type { EuiIconSignature } from './eui-icon';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiNotificationEventSignature {
  Element: HTMLDivElement;
  Args: {
    id?: string;
    time?: string;
    type?: string;
    severity?: string;
    iconType?: EuiIconSignature['Args']['type'];
    iconColor?: EuiIconSignature['Args']['color'];
    iconAriaLabel?: EuiIconSignature['Args']['aria-label'];
    badgeColor?: EuiBadgeSignature['Args']['color'];
    hasDefaultBlock?: boolean;
    onOpenContextMenu?: (e: MouseEvent) => void;
  };
  Blocks: {
    default: [];
  };
}

const EuiNotificationEvent: TemplateOnlyComponent<EuiNotificationEventSignature> =
  <template>
    {{#let
      (and (argOrDefault @hasDefaultBlock true) (has-block))
      as |hasDefaultBlock|
    }}
      <div
        class={{classNames
          "euiNotificationEventMeta"
          (if hasDefaultBlock "euiNotificationEventMeta--hasContextMenu")
        }}
        ...attributes
      >
        <div class="euiNotificationEventMeta__section">

          {{#if @iconType}}
            <EuiIcon
              @iconClasses="euiNotificationEventMeta__icon"
              @type={{@iconType}}
              @color={{@iconColor}}
              {{! TODO only add one of the following html attributes }}
              aria-label={{@iconAriaLabel}}
              aria-hidden={{if @iconAriaLabel false true}}
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

        <div class="euiNotificationEventMeta__section">
          <span class="euiNotificationEventMeta__time">{{@time}}</span>
        </div>

        {{#if hasDefaultBlock}}
          {{#let
            (randomId) (useState false)
            as |randomPopoverId isPopoverOpen|
          }}
            <div class="euiNotificationEventMeta__contextMenuWrapper">
              <EuiPopover
                id={{randomPopoverId}}
                @ownFocus={{true}}
                @repositionOnScroll={{true}}
                @isOpen={{isPopoverOpen.value}}
                @panelPaddingSize="none"
                @anchorPosition="leftUp"
                @closePopover={{fn isPopoverOpen.setState false}}
              >

                <:button>
                  <EuiButtonIcon
                    {{! aria-label={contextMenuButton} }}
                    aria-controls={{randomPopoverId}}
                    aria-expanded={{isPopoverOpen.value}}
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
  </template>;

export default EuiNotificationEvent;
