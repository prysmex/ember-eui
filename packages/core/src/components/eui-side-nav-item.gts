import { on } from '@ember/modifier';

import optional from '@nullvoxpopuli/ember-composable-helpers/helpers/optional';
import add from 'ember-math-helpers/helpers/add';
import { and, eq, gt, not, or } from 'ember-truth-helpers';

import Button from '../components/eui-side-nav-item/button.gts';
import classNames from '../helpers/class-names.ts';
import isItemOpen from '../helpers/is-item-open.ts';

import type { Item } from './eui-side-nav';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** @private One item of an EuiSideNav (rendered from its `@items`). */
export interface EuiSideNavItemSignature {
  Args: {
    /** The side nav's `@selectedItem`, passed down to children. */
    selectedItem?: string;
    /** Shows the children. */
    isOpen?: boolean;
    /** Highlights the item. */
    isSelected?: boolean;
    /** Has children. */
    isParent?: boolean;
    /** Icon before the name. */
    icon?: string;
    /** Makes the item a button calling this function. */
    onClick?: () => void;
    /** Makes the item a link. */
    href?: string;
    /** Class for the item. */
    className?: string;
    /** `rel` of the link. */
    rel?: string;
    /** `target` of the link. */
    target?: string;
    /** Nested items. */
    items?: Item[];
    /** Nesting level. */
    depth?: number;
    /** @deprecated Has no effect; the name is the block content. */
    name?: string;
    /** @deprecated Has no effect. */
    renderItem?: unknown;
    /** Disables the item. */
    disabled?: boolean;
    /** Truncates a long name. */
    truncate?: boolean;
    /** Bolder style. */
    emphasize?: boolean;
    /** Class for the item's button or link. */
    buttonClassName?: string;
    /** Renders the item as a section title (children, no action). */
    childrenOnly?: boolean;
    /** Extra classes for the icon. */
    buttonIconClasses?: string;
  };
  Blocks: {
    /** The item's name. */
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
