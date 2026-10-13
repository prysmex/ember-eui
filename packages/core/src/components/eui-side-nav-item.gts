import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';

import optional from '@nullvoxpopuli/ember-composable-helpers/helpers/optional';
import add from 'ember-math-helpers/helpers/add';

import Button from '../components/eui-side-nav-item/button.gts';
import nullish from '../helpers/nullish.ts';
import { isItemOpen, isItemSelected } from '../helpers/is-item-open.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiSideNavItemButtonStyles,
  euiSideNavItemStyles,
  euiTextTruncate
} from '../utils/eui/styles.generated.ts';
import { getSecureRelForTarget, isValidHref } from './eui-link.gts';

import type { Item, EuiSideNavRenderItem } from './eui-side-nav';
import type { ComponentLike } from '@glint/template';

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
    /** Icon before the name: an icon type, or a component rendered as is. */
    icon?: string | ComponentLike<any>;
    /** Makes the item a button calling this function. */
    onClick?: () => void;
    /** Makes the item a link. */
    href?: string;
    /** Class for the item. */
    className?: string;
    /** `rel` of the link; `noreferrer` (and `noopener` for `_blank`) is added. */
    rel?: string;
    /** `target` of the link. */
    target?: string;
    /** Nested items. */
    items?: Item[];
    /** Nesting level. */
    depth?: number;
    /** @deprecated Has no effect; the name is the block content. */
    name?: string;
    /** Replaces the item's link, button or text, see `Item.renderItem`. */
    renderItem?: EuiSideNavRenderItem;
    /** Disables the item. */
    disabled?: boolean;
    /** Truncates a long name. Defaults to `@navTruncate`, else `true`. */
    truncate?: boolean;
    /** The side nav's `@truncate`, passed down to children. */
    navTruncate?: boolean;
    /** Bolder style with a background band. */
    emphasize?: boolean;
    /** Class for the item's button or link. */
    buttonClassName?: string;
    /**
     * A section item (children, no `href`/`onClick`) below the root: it
     * renders a button that opens and closes its children.
     */
    childrenOnly?: boolean;
    /** Extra classes for the icon. */
    buttonIconClasses?: string;
  };
  Blocks: {
    /** The item's name. */
    default: [];
  };
}

/** Upstream renders a section item below the root as an accordion. */
export function isChildrenOnly(item: Item, depth: number): boolean {
  return depth > 0 && !item.onClick && !item.href && Boolean(item.items);
}

/** Native Ember side nav item using the upstream EUI 123 / Borealis factories. */
export default class EuiSideNavItem extends Component<EuiSideNavItemSignature> {
  /** Accordion state toggled by the user; reset when `@isOpen` changes. */
  @tracked toggled?: { open: boolean; from: boolean };

  get context() {
    return getEuiThemeContext(this);
  }

  get depth(): number {
    return this.args.depth ?? 0;
  }

  get isRoot(): boolean {
    return this.depth === 0;
  }

  get isTrunk(): boolean {
    return this.depth === 1;
  }

  get isBranch(): boolean {
    return this.depth > 1;
  }

  get itemIsOpen(): boolean {
    const isOpen = Boolean(this.args.isOpen);
    const toggled = this.toggled;
    return toggled && toggled.from === isOpen ? toggled.open : isOpen;
  }

  get hasChildItems(): boolean {
    return Boolean(this.args.items?.length) && this.itemIsOpen;
  }

  get hasCaret(): boolean {
    return this.depth > 0 && Boolean(this.args.childrenOnly);
  }

  get href(): string | undefined {
    const { href } = this.args;
    return href && isValidHref(href) ? href : undefined;
  }

  get onClick(): (() => void) | undefined {
    return this.args.childrenOnly ? this.toggleOpen : this.args.onClick;
  }

  get kind(): 'a' | 'button' | 'div' {
    if (this.href && !this.args.disabled) return 'a';
    if (this.onClick || this.args.disabled) return 'button';
    return 'div';
  }

  get isLink(): boolean {
    return this.kind === 'a';
  }

  get isButton(): boolean {
    return this.kind === 'button';
  }

  get rel(): string {
    return getSecureRelForTarget(this.args.target, this.args.rel);
  }

  toggleOpen = (): void => {
    this.toggled = {
      open: !this.itemIsOpen,
      from: Boolean(this.args.isOpen)
    };
  };

  @cached
  get classes(): string {
    const context = this.context;
    const styles = useEuiBorealisStyles(context, euiSideNavItemStyles);
    const names = [
      'euiSideNavItem',
      this.isRoot && 'euiSideNavItem--root',
      this.isTrunk && 'euiSideNavItem--trunk',
      this.isBranch && 'euiSideNavItem--branch',
      this.args.emphasize && 'euiSideNavItem--emphasized',
      this.hasChildItems && 'euiSideNavItem-hasChildItems',
      this.args.className
    ];
    return [
      ...names,
      euiClass(
        context,
        { boxSizing: 'border-box' },
        styles.euiSideNavItem,
        this.isRoot && styles.root,
        this.isTrunk && styles.trunk,
        this.isBranch && styles.branch,
        this.args.emphasize && styles.emphasized
      )
    ]
      .filter(Boolean)
      .join(' ');
  }

  @cached
  get buttonStyles() {
    return useEuiBorealisStyles(this.context, euiSideNavItemButtonStyles);
  }

  @cached
  get buttonClasses(): string {
    const context = this.context;
    const theme = context.upstream.euiTheme;
    const styles = this.buttonStyles;
    const { isSelected, emphasize } = this.args;
    // Scoped stand-in for React's global button/link reset; upstream after.
    const reset = {
      boxSizing: 'border-box' as const,
      margin: 0,
      padding: 0,
      border: 0,
      borderRadius: 0,
      background: 'none',
      fontFamily: theme.font.family,
      textDecoration: 'none'
    };
    return [
      'euiSideNavItemButton',
      this.depth > 0 &&
        this.itemIsOpen &&
        !isSelected &&
        'euiSideNavItemButton-isOpen',
      isSelected && 'euiSideNavItemButton-isSelected',
      this.args.buttonClassName,
      euiClass(
        context,
        reset,
        styles.euiSideNavItemButton,
        isSelected && styles.selected,
        emphasize && styles.emphasized,
        this.isRoot && styles.root,
        this.isTrunk && styles.trunk,
        this.isBranch && styles.branch
      )
    ]
      .filter(Boolean)
      .join(' ');
  }

  @cached
  get contentClass(): string {
    return euiClass(this.context, this.buttonStyles.euiSideNavItemButton__content);
  }

  get truncate(): boolean {
    return this.args.truncate ?? this.args.navTruncate ?? true;
  }

  @cached
  get labelClass(): string {
    const label = this.buttonStyles.label;
    return [
      this.truncate && 'eui-textTruncate',
      euiClass(
        this.context,
        label.euiSideNavItemButton__label,
        this.isRoot && label.root,
        // Upstream's `eui-textTruncate` utility class.
        this.truncate && euiTextTruncate()
      )
    ]
      .filter(Boolean)
      .join(' ');
  }

  @cached
  get itemsClass(): string {
    const items = useEuiBorealisStyles(this.context, euiSideNavItemStyles).items;
    return `euiSideNavItem__items ${euiClass(
      this.context,
      items.euiSideNavItem__items,
      this.isRoot && this.args.icon && items.rootWithIcon,
      this.isTrunk && items.trunk,
      this.isBranch && items.branch
    )}`;
  }

  isChildrenOnly = (item: Item): boolean => isChildrenOnly(item, this.depth + 1);

  isItemOpen = (item: Item): boolean => isItemOpen(item, this.args.selectedItem);

  isItemSelected = (item: Item): boolean =>
    !isChildrenOnly(item, this.depth + 1) &&
    isItemSelected(item, this.args.selectedItem);

  <template>
    <div class={{this.classes}}>
      {{#if @renderItem}}
        <@renderItem
          @href={{this.href}}
          @target={{@target}}
          @rel={{@rel}}
          @onClick={{this.onClick}}
          @disabled={{@disabled}}
          class={{this.buttonClasses}}
        >
          <Button
            @icon={{@icon}}
            @truncate={{this.truncate}}
            @buttonIconClasses={{@buttonIconClasses}}
            @caret={{this.hasCaret}}
            @isOpen={{this.itemIsOpen}}
            @contentClass={{this.contentClass}}
            @labelClass={{this.labelClass}}
          >
            {{yield}}
          </Button>
        </@renderItem>
      {{else if this.isLink}}
        <a
          class={{this.buttonClasses}}
          href={{this.href}}
          target={{@target}}
          rel={{this.rel}}
          {{on "click" (optional @onClick)}}
        >
          <Button
            @icon={{@icon}}
            @truncate={{this.truncate}}
            @buttonIconClasses={{@buttonIconClasses}}
            @contentClass={{this.contentClass}}
            @labelClass={{this.labelClass}}
          >
            {{yield}}
          </Button>
        </a>
      {{else if this.isButton}}
        <button
          type="button"
          class={{this.buttonClasses}}
          disabled={{@disabled}}
          aria-expanded={{if this.hasCaret (if this.itemIsOpen "true" "false")}}
          {{on "click" (optional this.onClick)}}
        >
          <Button
            @icon={{@icon}}
            @truncate={{this.truncate}}
            @buttonIconClasses={{@buttonIconClasses}}
            @caret={{this.hasCaret}}
            @isOpen={{this.itemIsOpen}}
            @contentClass={{this.contentClass}}
            @labelClass={{this.labelClass}}
          >
            {{yield}}
          </Button>
        </button>
      {{else}}
        <div class={{this.buttonClasses}}>
          <Button
            @icon={{@icon}}
            @truncate={{this.truncate}}
            @buttonIconClasses={{@buttonIconClasses}}
            @contentClass={{this.contentClass}}
            @labelClass={{this.labelClass}}
          >
            {{yield}}
          </Button>
        </div>
      {{/if}}
      {{#if this.hasChildItems}}
        <div class={{this.itemsClass}}>
          {{#each @items as |item|}}
            <EuiSideNavItem
              @selectedItem={{@selectedItem}}
              @isOpen={{nullish item.isOpen (this.isItemOpen item)}}
              @isSelected={{this.isItemSelected item}}
              @isParent={{if item.items true false}}
              @icon={{item.icon}}
              @onClick={{item.onClick}}
              @href={{item.href}}
              @className={{item.className}}
              @rel={{item.rel}}
              @target={{item.target}}
              @items={{item.items}}
              @depth={{add this.depth 1}}
              @disabled={{item.disabled}}
              @truncate={{item.truncate}}
              @navTruncate={{@navTruncate}}
              @emphasize={{item.emphasize}}
              @buttonClassName={{item.buttonClassName}}
              @childrenOnly={{this.isChildrenOnly item}}
              @renderItem={{if item.renderItem item.renderItem @renderItem}}
            >
              {{item.name}}
            </EuiSideNavItem>
          {{/each}}
        </div>
      {{/if}}
    </div>
  </template>
}
