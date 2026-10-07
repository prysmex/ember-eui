import Component from '@glimmer/component';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { schedule } from '@ember/runloop';
import { inject as service } from '@ember/service';

import { modifier } from 'ember-modifier';

import { randomId } from '../../-private/random-id.ts';

import type EuiI18n from '../../services/eui-i18n';
import type EuiResizableContainer from '../eui-resizable-container.gts';

/**
 * The draggable separator between two panels of an
 * `EuiResizableContainer` (yielded as `Button`). Drag it, or focus it and
 * use the arrow keys.
 */
export interface EuiResizableButtonSignature {
  Element: HTMLButtonElement;
  Args: {
    /** Id of the button. Defaults to a random id. */
    id?: string;
    /** Disables resizing at this button. */
    disabled?: boolean;
    /** @private The container, set by `EuiResizableContainer`. */
    container: EuiResizableContainer;
  };
}

export default class EuiResizableButton extends Component<EuiResizableButtonSignature> {
  @service declare euiI18n: EuiI18n;

  ownId = `resizable-button_${randomId()}`;

  get id(): string {
    return this.args.id ?? this.ownId;
  }

  get container(): EuiResizableContainer {
    return this.args.container;
  }

  get isDisabled(): boolean {
    return Boolean(this.args.disabled || this.container.resizers[this.id]?.isDisabled);
  }

  get classes(): string {
    return [
      'euiResizableButton',
      this.container.isHorizontal ? 'euiResizableButton--horizontal' : 'euiResizableButton--vertical',
      this.isDisabled && 'euiResizableButton--disabled'
    ]
      .filter(Boolean)
      .join(' ');
  }

  get label(): string {
    return this.container.isHorizontal
      ? this.euiI18n.lookupToken(
          'euiResizableButton.horizontalResizerAriaLabel',
          'Press left or right to adjust panels size'
        )
      : this.euiI18n.lookupToken(
          'euiResizableButton.verticalResizerAriaLabel',
          'Press up or down to adjust panels size'
        );
  }

  @action
  focusSelf(event: MouseEvent): void {
    (event.currentTarget as HTMLElement).focus();
  }

  @action
  onFocus(): void {
    this.container.onResizerFocus(this.id);
  }

  register = modifier(() => {
    const id = this.id;

    // after rendering: registering updates the container's state
    schedule('afterRender', () =>
      this.container.registerResizer({ id, isFocused: false, isDisabled: this.args.disabled ?? false })
    );

    return () => schedule('afterRender', () => this.container.deregisterResizer(id));
  });

  <template>
    <button
      id={{this.id}}
      type="button"
      class={{this.classes}}
      aria-label={{this.label}}
      data-test-subj="euiResizableButton"
      disabled={{this.isDisabled}}
      {{this.register}}
      {{on "click" this.focusSelf}}
      {{on "focus" this.onFocus}}
      {{on "blur" this.container.onResizerBlur}}
      {{on "mousedown" this.container.onResizerMouseDown}}
      {{on "touchstart" this.container.onResizerMouseDown}}
      {{on "keydown" this.container.onResizerKeyDown}}
      ...attributes
    ></button>
  </template>
}
