import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { inject as service } from '@ember/service';

import { randomId } from '../-private/random-id.ts';
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

  get isCompressed(): boolean {
    return this.args.display === 'compressed';
  }

  get classes(): string {
    return [
      'euiTreeView',
      this.isCompressed && 'euiTreeView--compressed',
      this.args.showExpansionArrows && 'euiTreeView--withArrows'
    ]
      .filter(Boolean)
      .join(' ');
  }

  isOpen = (node: EuiTreeViewNode): boolean => this.openItems.includes(node.id);

  nodeClasses = (node: EuiTreeViewNode): string =>
    [
      'euiTreeView__node',
      this.isCompressed && 'euiTreeView--compressed',
      this.isOpen(node) && 'euiTreeView__node--expanded'
    ]
      .filter(Boolean)
      .join(' ');

  buttonClasses = (node: EuiTreeViewNode): string =>
    [
      'euiTreeView__nodeInner',
      this.args.showExpansionArrows && node.children && 'euiTreeView__nodeInner--withArrows',
      this.activeItem === node.id && 'euiTreeView__node--active',
      node.className
    ]
      .filter(Boolean)
      .join(' ');

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
    <div class="euiText {{if this.isCompressed 'euiText--small' 'euiText--medium'}} euiTreeView__wrapper">
      {{#unless this.isNested}}
        <EuiScreenReaderOnly>
          <p id={{this.instructionsId}}>{{this.instructions}}</p>
        </EuiScreenReaderOnly>
      {{/unless}}
      <ul
        class={{this.classes}}
        id={{unless this.isNested this.treeId}}
        aria-describedby={{unless this.isNested this.instructionsId}}
        ...attributes
      >
        {{#each @items as |node|}}
          <li class={{this.nodeClasses node}}>
            <button
              type="button"
              id={{node.id}}
              class={{this.buttonClasses node}}
              aria-controls={{this.childrenId node}}
              aria-expanded={{if (this.isOpen node) "true" "false"}}
              data-test-subj="euiTreeViewButton-{{this.treeId}}"
              {{on "click" (fn this.onClick node)}}
              {{on "keydown" (fn this.onKeyDown node)}}
            >
              {{#if (and2 @showExpansionArrows node.children)}}
                <EuiIcon
                  class="euiTreeView__expansionArrow"
                  @size={{if this.isCompressed "s" "m"}}
                  @type={{if (this.isOpen node) "arrowDown" "arrowRight"}}
                />
              {{/if}}
              {{#if node.icon}}
                <span class="euiTreeView__iconWrapper">
                  <EuiIcon @type={{this.iconOf node}} />
                </span>
              {{else if node.useEmptyIcon}}
                <span class="euiTreeView__iconPlaceholder"></span>
              {{/if}}
              <span class="euiTreeView__nodeLabel">
                {{~#if (has-block "label")~}}
                  {{yield node to="label"}}
                {{~else~}}
                  {{node.label}}
                {{~/if~}}
              </span>
            </button>
            <div
              id={{this.childrenId node}}
              {{on "keydown" (fn this.onChildrenKeyDown node)}}
            >
              {{#if (and2 node.children (this.isOpen node))}}
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
          </li>
        {{/each}}
      </ul>
    </div>
  </template>
}

function childrenOf(node: EuiTreeViewNode): EuiTreeViewNode[] {
  return node.children ?? [];
}

function and2(a: unknown, b: unknown): boolean {
  return Boolean(a && b);
}
