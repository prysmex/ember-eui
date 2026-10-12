import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { schedule } from '@ember/runloop';
import { service } from '@ember/service';

import { modifier } from 'ember-modifier';

import { randomId } from '../../-private/random-id.ts';
import { getEuiThemeContext } from '../../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../../utils/eui/styles.ts';
import { euiResizableButtonStyles } from '../../utils/eui/styles.generated.ts';

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
    /** Disables resizing at this button (a disabled button is hidden, as upstream). */
    disabled?: boolean;
    /**
     * The resize indicator: `'handle'` (two short grab lines that grow into
     * one line on hover and focus) or `'border'` (a full-length 1px line).
     * Defaults to `'handle'`.
     */
    indicator?: 'handle' | 'border';
    /**
     * Where the `'handle'` indicator sits along the button: `'center'`,
     * `'start'` or `'end'`. Defaults to `'center'`.
     */
    alignIndicator?: 'center' | 'start' | 'end';
    /**
     * The button overlaps its neighbours by half its size on both sides by
     * default, so it takes no room. When a panel shows a scrollbar next to
     * it, `'before'`, `'after'` or `'both'` keep it from covering it.
     */
    accountForScrollbars?: 'before' | 'after' | 'both';
    /** @private The container, set by `EuiResizableContainer`. */
    container: EuiResizableContainer;
  };
}

/**
 * React's global reset, scoped: the native button face, border, padding and
 * margin would otherwise show (upstream's margins come after it).
 */
const BUTTON_RESET = {
  boxSizing: 'border-box',
  appearance: 'none',
  margin: 0,
  padding: 0,
  border: 'none',
  borderRadius: 0,
  background: 'none',
  color: 'inherit',
  font: 'inherit'
} as const;

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

  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiResizableButtonStyles);
    const direction = this.container.isHorizontal ? 'horizontal' : 'vertical';
    const indicator = this.args.indicator ?? 'handle';

    return `euiResizableButton ${euiClass(
      context,
      BUTTON_RESET,
      styles.euiResizableButton,
      styles[indicator],
      styles[`${indicator}Direction`][direction],
      styles[direction],
      indicator === 'handle' && styles.alignIndicator[this.args.alignIndicator ?? 'center'],
      styles.accountForScrollbars[direction][this.args.accountForScrollbars ?? 'none']
    )}`;
  }

  get label(): string {
    return this.container.isHorizontal
      ? this.euiI18n.lookupToken(
          'euiResizableButton.horizontalResizerAriaLabel',
          'Press the left or right arrow keys to adjust panels size'
        )
      : this.euiI18n.lookupToken(
          'euiResizableButton.verticalResizerAriaLabel',
          'Press the up or down arrow keys to adjust panels size'
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
      {{on "keyup" this.container.onResizerKeyUp}}
      ...attributes
    ></button>
  </template>
}
