import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { uniqueId } from '../../helpers/unique-id';
import { keysOf } from '../common';

interface InsertPositionsMap {
  after: InsertPosition;
  before: InsertPosition;
}

export const insertPositions: InsertPositionsMap = {
  after: 'afterend',
  before: 'beforebegin'
};

export const INSERT_POSITIONS: EuiPortalInsertPosition[] = keysOf(insertPositions);

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
    this.portalNode.id = `${uniqueId()}-portal`;

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
}
