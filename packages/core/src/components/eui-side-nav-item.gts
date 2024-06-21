import { on } from '@ember/modifier';

import optional from 'ember-composable-helpers/helpers/optional';
import add from 'ember-math-helpers/helpers/add';
import { and,eq, gt, not, or } from 'ember-truth-helpers';

import Button from '../components/eui-side-nav-item/button.gts';
import classNames from '../helpers/class-names.ts';
import isItemOpen from '../helpers/is-item-open.ts';

import type { Item } from './eui-side-nav';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiSideNavItemSignature {
  Args: {
    selectedItem?: string;
    isOpen?: boolean;
    isSelected?: boolean;
    isParent?: boolean;
    icon?: string;
    onClick?: () => void;
    href?: string;
    className?: string;
    rel?: string;
    target?: string;
    items?: Item[];
    depth?: number;
    name?: string;
    renderItem?: unknown;
    disabled?: boolean;
    truncate?: boolean;
    emphasize?: boolean;
    buttonClassName?: string;
    childrenOnly?: boolean;
    buttonIconClasses?: string;
  };
  Blocks: {
    default: [];
  };
}

const EuiSideNavItem: TemplateOnlyComponent<EuiSideNavItemSignature> =
  <template>
    <div
      class={{classNames
        "euiSideNavItem"
        (if (eq @depth 1) "euiSideNavItem--trunk")
        (if (eq @depth 0) "euiSideNavItem--root")
        (if (and (eq @depth 0) @icon) "euiSideNavItem--rootIcon")
        (if (gt @depth 1) "euiSideNavItem--branch")
        (if @items.length "euiSideNavItem--hasChildItems")
        (if @emphasize "euiSideNavItem--emphasized")
      }}
    >
      {{#let
        (classNames
          "euiSideNavItemButton"
          (if (or @onClick @href) "euiSideNavItemButton--isClickable")
          (if
            (and (gt @depth 0) @isOpen (not @isSelected))
            "euiSideNavItemButton-isOpen"
          )
          (if @isSelected "euiSideNavItemButton-isSelected")
          @buttonClassName
        )
        (and (gt @depth 0) @isParent (not @isOpen) (not @isSelected))
        as |className caret|
      }}
        {{#if (and @href (not @disabled))}}
          <a
            class={{className}}
            href={{@href}}
            target={{@target}}
            rel={{@rel}}
            {{on "click" (optional @onClick)}}
          >
            <Button
              @icon={{@icon}}
              @buttonIconClasses={{@buttonIconClasses}}
              @caret={{caret}}
            >
              {{yield}}
            </Button>
          </a>
        {{else if (or @onClick @disabled)}}
          <button
            type="button"
            class={{className}}
            disabled={{@disabled}}
            {{on "click" (optional @onClick)}}
          >
            <Button
              @icon={{@icon}}
              @truncate={{@truncate}}
              @buttonIconClasses={{@buttonIconClasses}}
              @caret={{caret}}
            >
              {{yield}}
            </Button>
          </button>
        {{else}}
          <div class={{className}}>
            <Button
              @icon={{@icon}}
              @truncate={{@truncate}}
              @buttonIconClasses={{@buttonIconClasses}}
              @caret={{caret}}
            >
              {{yield}}
            </Button>
          </div>
        {{/if}}
      {{/let}}
      {{#if (or (eq @depth 0) (and @items.length @isOpen))}}
        <div class="euiSideNavItem__items">
          {{#each @items as |item|}}
            {{#let
              (and
                (gt @depth 0)
                (not item.onClick)
                (not item.href)
                (not (not item.items))
              )
              as |childrenOnly|
            }}
              <EuiSideNavItem
                @selectedItem={{@selectedItem}}
                @isOpen={{isItemOpen item @selectedItem}}
                @isSelected={{and
                  (not childrenOnly)
                  (eq item.id @selectedItem)
                }}
                @isParent={{not (not item.items)}}
                @icon={{item.icon}}
                @onClick={{item.onClick}}
                @href={{item.href}}
                @className={{item.className}}
                @rel={{item.rel}}
                @target={{item.target}}
                @items={{item.items}}
                @depth={{add @depth 1}}
                @name={{item.name}}
                @renderItem={{item.renderItem}}
                @disabled={{item.disabled}}
                @truncate={{item.truncate}}
                @emphasize={{item.emphasize}}
                @buttonClassName={{item.buttonClassName}}
                @childrenOnly={{childrenOnly}}
              >
                {{item.name}}
              </EuiSideNavItem>
            {{/let}}
          {{/each}}
        </div>
      {{/if}}
    </div>
  </template>;

export default EuiSideNavItem;
