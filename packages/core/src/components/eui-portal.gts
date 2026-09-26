import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { guidFor } from '@ember/object/internals';
import { isBlank } from '@ember/utils';
import type Owner from '@ember/owner';

import { keysOf } from './common.ts';

interface InsertPositionsMap {
  [key: string]: string;
}

export const insertPositions: InsertPositionsMap = {
  after: 'afterend',
  before: 'beforebegin'
};

export const INSERT_POSITIONS: EuiPortalInsertPosition[] =
  keysOf(insertPositions);

type EuiPortalInsertPosition = keyof typeof insertPositions;

export interface EuiPortalArgs {
  /**
   * Renders the portal next to an element instead of at the end of
   * `<body>`: `{ sibling: element, position: 'before' | 'after' }`.
   */
  insert?: { sibling: HTMLElement; position: EuiPortalInsertPosition };
  /** Called with the portal's element. */
  portalRef?: (ref: HTMLElement) => void;
}

/**
 * Renders its content at the end of `<body>` (or next to `@insert`'s
 * element), e.g. for overlays that must escape `overflow: hidden`.
 */
export interface EuiPortalSignature {
  Args: EuiPortalArgs;
  Element: HTMLDivElement;
  Blocks: {
    /** The content to move. */
    default: [];
  };
}

export default class EuiPortal extends Component<EuiPortalSignature> {
  @tracked portalNode?: HTMLElement;

  constructor(owner: Owner, args: EuiPortalArgs) {
    super(owner, args);

    const { insert } = this.args;

    this.portalNode = document.createElement('div');
    this.portalNode.id = `${guidFor({})}-portal`;

    if (isBlank(this.args.insert)) {
      document.body.appendChild(this.portalNode);
    } else {
      // inserting before or after an element
      const { sibling, position } = insert!;

      sibling.insertAdjacentElement(
        insertPositions[position] as InsertPosition,
        this.portalNode
      );
    }

    if (this.args.portalRef) {
      this.args.portalRef(this.portalNode);
    }
  }

  willDestroy(): void {
    super.willDestroy();

    if (this.portalNode?.parentNode) {
      this.portalNode.parentNode.removeChild(this.portalNode);
    }

    this.portalNode = undefined;
  }

  <template>
    {{#if this.portalNode}}
      {{#in-element this.portalNode}}
        {{yield}}
      {{/in-element}}
    {{/if}}
  </template>
}
