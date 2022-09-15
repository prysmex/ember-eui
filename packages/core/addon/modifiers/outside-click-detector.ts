import Modifier from 'ember-modifier';
import { guidFor } from '@ember/object/internals';
import { action } from '@ember/object';

interface OutsideClickDetectorModifierArgs {
  positional: [];
  named: {
    onOutsideClick: (event: Event) => void;
    isDisabled?: boolean;
    onMouseDown?: (event: MouseEvent) => void;
    onMouseUp?: (event: MouseEvent) => void;
    onTouchStart?: (event: MouseEvent) => void;
    onTouchEnd?: (event: MouseEvent) => void;
  };
}

export interface EuiEvent extends Event {
  euiGeneratedBy: string[];
}

export default class OutsideClickDetector extends Modifier<OutsideClickDetectorModifierArgs> {
  id!: string;
  capturedDownIds: string[] = [];

  @action
  onClickOutside(e: Event): void {
    const { isDisabled, onOutsideClick } = this.args.named;

    if (isDisabled) {
      this.capturedDownIds = [];
      return;
    }

    const event = e as unknown as EuiEvent;

    if (
      (event.euiGeneratedBy && event.euiGeneratedBy.includes(this.id)) ||
      this.capturedDownIds.includes(this.id)
    ) {
      this.capturedDownIds = [];
      return;
    }

    this.capturedDownIds = [];
    return onOutsideClick(event);
  }

  didInstall(): void {
    this.id = guidFor({});
    document.addEventListener('mouseup', this.onClickOutside);
    document.addEventListener('touchend', this.onClickOutside);
    this.addElementEvents();
  }

  addElementEvents(): void {
    this.element.addEventListener('mousedown', this.onChildMouseDown);
    this.element.addEventListener('touchstart', this.onChildMouseDown);
    this.element.addEventListener('mouseup', this.onChildMouseUp);
    this.element.addEventListener('touchend', this.onChildMouseUp);
  }

  removeElementEvents(): void {
    this.element.removeEventListener('mousedown', this.onChildMouseDown);
    this.element.removeEventListener('touchstart', this.onChildMouseDown);
    this.element.removeEventListener('mouseup', this.onChildMouseUp);
    this.element.removeEventListener('touchend', this.onChildMouseUp);
  }

  willRemove(): void {
    document.removeEventListener('mouseup', this.onClickOutside);
    document.removeEventListener('touchend', this.onClickOutside);
    this.removeElementEvents();
  }

  @action
  onChildClick(event: MouseEvent, cb: (event: MouseEvent) => void): void {
    // to support nested click detectors, build an array
    // of detector ids that have been encountered;

    if (event.hasOwnProperty('euiGeneratedBy')) {
      (event as unknown as EuiEvent).euiGeneratedBy.push(this.id);
    } else {
      (event as unknown as EuiEvent).euiGeneratedBy = [this.id];
    }
    if (cb) cb(event);
  }

  @action
  onChildMouseDown(event: MouseEvent): void {
    this.onChildClick(event, (e) => {
      const nativeEvent = e as unknown as EuiEvent;
      this.capturedDownIds = nativeEvent.euiGeneratedBy;
      if (this.args.named.onMouseDown) this.args.named.onMouseDown(e);
      if (this.args.named.onTouchStart) this.args.named.onTouchStart(e);
    });
  }

  @action
  onChildMouseUp(event: MouseEvent): void {
    this.onChildClick(event, (e) => {
      if (this.args.named.onMouseUp) this.args.named.onMouseUp(e);
      if (this.args.named.onTouchEnd) this.args.named.onTouchEnd(e);
    });
  }
}
