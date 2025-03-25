import { registerDestructor } from '@ember/destroyable';
import { action } from '@ember/object';
import { guidFor } from '@ember/object/internals';

import Modifier from 'ember-modifier';

interface Named {
  onOutsideClick: (event: Event) => void;
  isDisabled?: boolean;
  onMouseDown?: (event: MouseEvent | TouchEvent) => void;
  onMouseUp?: (event: MouseEvent | TouchEvent) => void;
  onTouchStart?: (event: MouseEvent | TouchEvent) => void;
  onTouchEnd?: (event: MouseEvent | TouchEvent) => void;
}

type Positional = [];

interface OutsideClickDetectorModifierArgs {
  Element: Element;
  Args: {
    Positional: Positional;
    Named: Named;
  };
}

export interface EuiEvent extends Event {
  euiGeneratedBy: string[];
}

export default class OutsideClickDetector extends Modifier<OutsideClickDetectorModifierArgs> {
  id!: string;
  capturedDownIds: string[] = [];

  element?: HTMLElement;
  named?: Named;
  positional?: Positional;

  @action
  onClickOutside(e: Event): void {
    const { isDisabled, onOutsideClick } = this.named!;

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

  modify(element: HTMLElement, positional: Positional, named: Named): void {
    this.element = element;
    this.named = named;
    this.positional = positional;
    this._setup();
    registerDestructor(this, () => this._teardown());
  }

  _setup(): void {
    this.id = guidFor({});
    document.addEventListener('mouseup', this.onClickOutside);
    document.addEventListener('touchend', this.onClickOutside);
    this.addElementEvents();
  }

  _teardown(): void {
    document.removeEventListener('mouseup', this.onClickOutside);
    document.removeEventListener('touchend', this.onClickOutside);
    this.removeElementEvents();
    this.element = undefined;
    this.named = undefined;
    this.positional = undefined;
  }

  addElementEvents(): void {
    if (this.element) {
      this.element.addEventListener('mousedown', this.onChildMouseDown);
      this.element.addEventListener('touchstart', this.onChildMouseDown);
      this.element.addEventListener('mouseup', this.onChildMouseUp);
      this.element.addEventListener('touchend', this.onChildMouseUp);
    }
  }

  removeElementEvents(): void {
    if (this.element) {
      this.element.removeEventListener('mousedown', this.onChildMouseDown);
      this.element.removeEventListener('touchstart', this.onChildMouseDown);
      this.element.removeEventListener('mouseup', this.onChildMouseUp);
      this.element.removeEventListener('touchend', this.onChildMouseUp);
    }
  }

  @action
  onChildClick(
    event: MouseEvent | TouchEvent,
    cb: (event: MouseEvent | TouchEvent) => void
  ): void {
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
  onChildMouseDown(event: MouseEvent | TouchEvent): any {
    this.onChildClick(event, (e) => {
      const nativeEvent = e as unknown as EuiEvent;

      this.capturedDownIds = nativeEvent.euiGeneratedBy;
      this.named?.onMouseDown?.(e);
      this.named?.onTouchStart?.(e);
    });
  }

  @action
  onChildMouseUp(event: TouchEvent | MouseEvent): any {
    this.onChildClick(event, (e) => {
      this.named?.onMouseUp?.(e);
      this.named?.onTouchEnd?.(e);
    });
  }
}
