import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';
import { and } from 'ember-truth-helpers';
import { concat } from '@ember/helper';
import { guidFor } from '@ember/object/internals';
import EuiPopover from './eui-popover';
import EuiIcon from './eui-icon';
import EuiButtonIcon from './eui-button-icon';
import EuiBadge from './eui-badge';
import { optional } from 'ember-composable-helpers';
import { on } from '@ember/modifier';
import { fn } from '@ember/helper';

import useState from '@ember-eui/core/helpers/use-state';
import { queue } from 'ember-composable-helpers';

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
        {{#let (guidFor) (useState false) as |randomPopoverId isPopoverOpen|}}
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
                  aria-expanded={{this.isPopoverOpen}}
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
