import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { guidFor } from '@ember/object/internals';
import { keysOf } from '@ember-eui/core/components/common';

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

type EuiPortalArgs = {
  insert?: { sibling: HTMLElement; position: EuiPortalInsertPosition };
  portalRef?: (ref: HTMLDivElement | null) => void;
};

export default class EuiPortal extends Component<EuiPortalArgs> {
  @tracked portalNode!: HTMLElement;

  constructor(owner: unknown, args: EuiPortalArgs) {
    super(owner, args);

    const { insert } = this.args;

    this.portalNode = document.createElement('div');
    this.portalNode.id = `${guidFor({})}-portal`;

    if (insert == null) {
      // no insertion defined, append to body
      document.body.appendChild(this.portalNode);
    } else {
      // inserting before or after an element
      const { sibling, position } = insert;
      sibling.insertAdjacentElement(insertPositions[position], this.portalNode);
    }
  }

  willDestroy(): void {
    super.willDestroy();
    if (this.portalNode.parentNode) {
      this.portalNode.parentNode.removeChild(this.portalNode);
    }
  }

  <template>
    {{#if this.portalNode}}
      {{#in-element this.portalNode}}
        {{yield}}
      {{/in-element}}
    {{/if}}
  </template>
}
