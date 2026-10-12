import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { service } from '@ember/service';

import { randomId } from '../-private/random-id.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiTextTruncate,
  euiTreeViewItemStyles,
  euiTreeViewStyles
} from '../utils/eui/styles.generated.ts';
import EuiIcon from './eui-icon.gts';
import EuiScreenReaderOnly from './eui-screen-reader-only.gts';

import type EuiI18n from '../services/eui-i18n';
import type { EuiIconSignature } from './eui-icon';

export interface EuiTreeViewNode {
  /** Unique id, also the id of the node's button. */
  id: string;
  /** The node's text. Use the `<:label>` block for markup. */
  label: string;
  /** Icon before the label, any `EuiIcon` type, e.g. `'folderClosed'`. */
  icon?: EuiIconSignature['Args']['type'];
  /** Icon while the node is open, e.g. `'folderOpen'`. */
  iconWhenExpanded?: EuiIconSignature['Args']['type'];
  /** Keeps the icon's space without an icon, to align with siblings. */
  useEmptyIcon?: boolean;
  /** Child nodes: the node opens and closes them. */
  children?: EuiTreeViewNode[];
  /** Starts open. */
  isExpanded?: boolean;
  /** Called when the node is clicked. */
  callback?: () => void;
  /** Extra classes for the node's button. */
  className?: string;
}

/**
 * A hierarchy of nodes (folders and files, sections and pages) that open
 * and close. Arrow keys move between nodes (up and down) and open or close
 * them (right and left). Give it an `aria-label`.
 */
export interface EuiTreeViewSignature {
  Element: HTMLUListElement;
  Args: {
    /** The top-level nodes; each may have `children`. */
    items: EuiTreeViewNode[];
    /** `'default'` or `'compressed'` (smaller text and spacing). */
    display?: 'default' | 'compressed';
    /** Opens every node that has children. */
    expandByDefault?: boolean;
    /** Shows an arrow before nodes that have children. */
    showExpansionArrows?: boolean;
    /** @private The root tree's id, for nested levels. */
    treeId?: string;
  };
  Blocks: {
    /** Renders a node's label yourself; yields the node. */
    label: [node: EuiTreeViewNode];
  };
}

/** Scoped stand-ins for React's global reset; upstream rules follow. */
const LIST_RESET = { boxSizing: 'border-box', padding: 0 } as const;
const ITEM_RESET = { boxSizing: 'border-box', margin: 0, padding: 0 } as const;
const BUTTON_RESET = {
  boxSizing: 'border-box',
  margin: 0,
  padding: 0,
  border: 'none',
  background: 'none',
  color: 'inherit',
  font: 'inherit',
  borderRadius: 0,
  textAlign: 'start',
  cursor: 'pointer'
} as const;
// upstream's `eui-textTruncate` utility class
const LABEL_TRUNCATE = euiTextTruncate();

function initiallyOpen(items: EuiTreeViewNode[], expandByDefault?: boolean): string[] {
  return items
    .filter((node) => node.children && (expandByDefault || node.isExpanded))
    .map((node) => node.id);
}

export default class EuiTreeView extends Component<EuiTreeViewSignature> {
  @service declare euiI18n: EuiI18n;

  @tracked openItems: string[] = initiallyOpen(this.args.items, this.args.expandByDefault);
  @tracked activeItem?: string;
  // only the levels shown at first follow @expandByDefault
  @tracked expandChildNodes = this.args.expandByDefault ?? false;

  ownTreeId = this.args.treeId ?? `euiTreeView_${randomId()}`;

  get isNested(): boolean {
    return Boolean(this.args.treeId);
  }

  get treeId(): string {
    return this.args.treeId ?? this.ownTreeId;
  }

  get instructionsId(): string {
    return `${this.treeId}--instruction`;
  }

  get instructions(): string {
    return this.euiI18n.lookupToken(
      'euiTreeView.listNavigationInstructions',
      'You can quickly navigate this list using arrow keys.'
    );
  }

  get display(): 'default' | 'compressed' {
    return this.args.display === 'compressed' ? 'compressed' : 'default';
  }

  get isCompressed(): boolean {
    return this.display === 'compressed';
  }

  /** Upstream `euiTreeViewStyles`: list reset, nested indent, font size. */
  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiTreeViewStyles);

    return `euiTreeView ${euiClass(
      context,
      LIST_RESET,
      styles.euiTreeView,
      styles[this.display]
    )}`;
  }

  @cached
  get nodeStyles(): { closed: string; expanded: string } {
    const context = getEuiThemeContext(this);
    const { li } = useEuiBorealisStyles(context, euiTreeViewItemStyles);
    const base = [ITEM_RESET, li.euiTreeView__node, li[this.display]];

    return {
      closed: euiClass(context, ...base),
      expanded: euiClass(context, ...base, li.expanded)
    };
  }

  @cached
  get buttonStyles(): string {
    const context = getEuiThemeContext(this);
    const { button } = useEuiBorealisStyles(context, euiTreeViewItemStyles);

    return euiClass(
      context,
      BUTTON_RESET,
      button.euiTreeView__nodeInner,
      button[this.display]
    );
  }

  /** Icon wrapper and arrow placeholder (upstream `icon` slots). */
  @cached
  get iconWrapperStyles(): string {
    const context = getEuiThemeContext(this);
    const { icon } = useEuiBorealisStyles(context, euiTreeViewItemStyles);

    return euiClass(context, icon.euiTreeView__iconWrapper, icon[this.display]);
  }

  @cached
  get labelStyles(): string {
    const context = getEuiThemeContext(this);

    return `euiTreeView__nodeLabel eui-textTruncate ${euiClass(context, LABEL_TRUNCATE)}`;
  }

  isOpen = (node: EuiTreeViewNode): boolean => this.openItems.includes(node.id);

  /** `aria-expanded` only for nodes with children (upstream). */
  ariaExpanded = (node: EuiTreeViewNode): 'true' | 'false' | undefined =>
    node.children ? (this.isOpen(node) ? 'true' : 'false') : undefined;

  nodeClasses = (node: EuiTreeViewNode): string => {
    const expanded = Boolean(node.children) && this.isOpen(node);

    return expanded
      ? `euiTreeView__node euiTreeView__node--expanded ${this.nodeStyles.expanded}`
      : `euiTreeView__node ${this.nodeStyles.closed}`;
  };

  buttonClasses = (node: EuiTreeViewNode): string =>
    [
      'euiTreeView__nodeInner',
      node.className,
      this.activeItem === node.id && 'euiTreeView__node--active',
      this.buttonStyles
    ]
      .filter(Boolean)
      .join(' ');

  hasIcon = (node: EuiTreeViewNode): boolean =>
    Boolean(node.icon || (node.iconWhenExpanded && this.isOpen(node)));

  iconOf = (node: EuiTreeViewNode): EuiIconSignature['Args']['type'] =>
    (this.isOpen(node) && node.iconWhenExpanded) || node.icon || 'empty';

  childrenId = (node: EuiTreeViewNode): string => `${this.treeId}_${node.id}_children`;

  toggle(node: EuiTreeViewNode): void {
    this.expandChildNodes = false;

    if (this.isOpen(node)) {
      this.openItems = this.openItems.filter((id) => id !== node.id);
    } else {
      this.openItems = [...this.openItems, node.id];
      this.activeItem = node.id;
    }
  }

  @action
  onClick(node: EuiTreeViewNode): void {
    this.toggle(node);
    node.callback?.();
  }

  @action
  onKeyDown(node: EuiTreeViewNode, event: KeyboardEvent): void {
    const button = event.currentTarget as HTMLElement;

    switch (event.key) {
      case 'ArrowDown':
      case 'ArrowUp': {
        const buttons = Array.from(
          document.querySelectorAll<HTMLElement>(
            `[data-test-subj="euiTreeViewButton-${this.treeId}"]`
          )
        );
        const index = buttons.indexOf(button);
        const next = buttons[index + (event.key === 'ArrowDown' ? 1 : -1)];

        if (index > -1 && next) {
          event.preventDefault();
          event.stopPropagation();
          next.focus();
        }
        break;
      }
      case 'ArrowRight':
        if (!this.isOpen(node)) {
          event.preventDefault();
          event.stopPropagation();
          this.toggle(node);
        }
        break;
      case 'ArrowLeft':
        if (this.isOpen(node)) {
          event.preventDefault();
          event.stopPropagation();
          this.toggle(node);
        }
        break;
    }
  }

  /** Arrow left inside a node's children moves back to that node. */
  @action
  onChildrenKeyDown(node: EuiTreeViewNode, event: KeyboardEvent): void {
    if (event.key !== 'ArrowLeft') return;

    event.preventDefault();
    event.stopPropagation();
    document.getElementById(node.id)?.focus();
  }

  <template>
    {{#unless this.isNested}}
      <EuiScreenReaderOnly>
        <p id={{this.instructionsId}}>{{this.instructions}}</p>
      </EuiScreenReaderOnly>
    {{/unless}}
    {{! role="list": VoiceOver drops the list role with list-style none (upstream) }}
    <ul
      class={{this.classes}}
      id={{unless this.isNested this.treeId}}
      aria-describedby={{unless this.isNested this.instructionsId}}
      role="list"
      ...attributes
    >
      {{#each @items as |node|}}
        <li class={{this.nodeClasses node}}>
          <button
            type="button"
            id={{node.id}}
            class={{this.buttonClasses node}}
            aria-controls={{if node.children (this.childrenId node)}}
            aria-expanded={{this.ariaExpanded node}}
            data-test-subj="euiTreeViewButton-{{this.treeId}}"
            {{on "click" (fn this.onClick node)}}
            {{on "keydown" (fn this.onKeyDown node)}}
          >
            {{#if @showExpansionArrows}}
              {{#if node.children}}
                <EuiIcon
                  class="euiTreeView__expansionArrow"
                  @size={{if this.isCompressed "s" "m"}}
                  @type={{if (this.isOpen node) "arrowDown" "arrowRight"}}
                />
              {{else}}
                <span
                  class="euiTreeView__arrowPlaceholder {{this.iconWrapperStyles}}"
                ></span>
              {{/if}}
            {{/if}}
            {{#if (this.hasIcon node)}}
              <span class="euiTreeView__iconWrapper {{this.iconWrapperStyles}}">
                <EuiIcon @type={{this.iconOf node}} />
              </span>
            {{else if node.useEmptyIcon}}
              <span
                class="euiTreeView__iconWrapper {{this.iconWrapperStyles}}"
              ></span>
            {{/if}}
            <span class={{this.labelStyles}}>
              {{~#if (has-block "label")~}}
                {{yield node to="label"}}
              {{~else~}}
                {{node.label}}
              {{~/if~}}
            </span>
          </button>
          {{#if node.children}}
            <div
              id={{this.childrenId node}}
              {{on "keydown" (fn this.onChildrenKeyDown node)}}
            >
              {{#if (this.isOpen node)}}
                <EuiTreeView
                  @items={{childrenOf node}}
                  @display={{@display}}
                  @showExpansionArrows={{@showExpansionArrows}}
                  @expandByDefault={{this.expandChildNodes}}
                  @treeId={{this.treeId}}
                  aria-labelledby={{node.id}}
                >
                  <:label as |child|>
                    {{~#if (has-block "label")~}}
                      {{yield child to="label"}}
                    {{~else~}}
                      {{child.label}}
                    {{~/if~}}
                  </:label>
                </EuiTreeView>
              {{/if}}
            </div>
          {{/if}}
        </li>
      {{/each}}
    </ul>
  </template>
}

function childrenOf(node: EuiTreeViewNode): EuiTreeViewNode[] {
  return node.children ?? [];
}
