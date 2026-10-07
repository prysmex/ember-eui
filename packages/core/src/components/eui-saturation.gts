import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { hash } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { schedule } from '@ember/runloop';
import { inject as service } from '@ember/service';

import { modifier } from 'ember-modifier';

import { getEventPosition } from '../-private/color.ts';
import cssStyle from '../-private/css-style.ts';

import type EuiI18n from '../services/eui-i18n';
import type { HSV } from '../-private/color.ts';

/**
 * The saturation / value square of `EuiColorPicker`: drag (or use the
 * arrow keys) to pick how vivid and how light the color is. Rendered for
 * you by the color picker.
 */
export interface EuiSaturationSignature {
  Element: HTMLDivElement;
  Args: {
    /** The color as HSV: `[hue, saturation, value]`. Defaults to `[1, 0, 0]`. */
    color?: HSV;
    /** The current color as hex, for screen readers. */
    hex?: string;
    /** Prefix of the ids inside. */
    id?: string;
    /** Called with the new `[hue, saturation, value]`. */
    onChange: (color: HSV) => void;
  };
}

export default class EuiSaturation extends Component<EuiSaturationSignature> {
  @service declare euiI18n: EuiI18n;

  // the indicator follows the pointer; otherwise it shows @color
  @tracked dragged?: { left: number; top: number; forColor: string };
  @tracked boxSize = { width: 0, height: 0 };

  box?: HTMLElement;

  get color(): HSV {
    return this.args.color ?? [1, 0, 0];
  }

  get indicator(): { left: number; top: number } {
    if (this.dragged && this.dragged.forColor === this.color.join()) return this.dragged;

    const [, s, v] = this.color;

    return { left: s * this.boxSize.width, top: (1 - v) * this.boxSize.height };
  }

  get roleDescription(): string {
    return this.euiI18n.lookupToken(
      'euiSaturation.ariaLabel',
      'HSV color mode saturation and value 2-axis slider'
    );
  }

  get instructions(): string {
    return this.euiI18n.lookupToken(
      'euiSaturation.screenReaderInstructions',
      "Arrow keys to navigate the square color gradient. Coordinates will be used to calculate HSV color mode 'saturation' and 'value' numbers, in the range of 0 to 1. Left and right to change the saturation. Up and down change the value."
    );
  }

  update({ left, top, width, height }: { left: number; top: number; width: number; height: number }): void {
    const color: HSV = [this.color[0], left / width, 1 - top / height];

    this.dragged = { left, top, forColor: color.join() };
    this.args.onChange(color);
  }

  moveTo(event: { clientX: number; clientY: number }): void {
    if (!this.box) return;

    this.update(getEventPosition({ x: event.clientX, y: event.clientY }, this.box));
  }

  @action
  onMouseDown(event: MouseEvent): void {
    this.moveTo(event);

    const move = (e: MouseEvent) => this.moveTo(e);
    const up = () => {
      document.removeEventListener('mousemove', move);
      document.removeEventListener('mouseup', up);
    };

    document.addEventListener('mousemove', move);
    document.addEventListener('mouseup', up);
  }

  @action
  onTouch(event: TouchEvent): void {
    const touch = event.touches[0];

    if (touch) this.moveTo(touch);
  }

  @action
  onKeyDown(event: KeyboardEvent): void {
    if (!this.box) return;

    const { width, height } = this.box.getBoundingClientRect();
    let { left, top } = this.indicator;

    switch (event.key) {
      case 'ArrowDown':
        top = Math.min(top + height / 100, height);
        break;
      case 'ArrowUp':
        top = Math.max(top - height / 100, 0);
        break;
      case 'ArrowLeft':
        left = Math.max(left - width / 100, 0);
        break;
      case 'ArrowRight':
        left = Math.min(left + width / 100, width);
        break;
      default:
        return;
    }

    event.preventDefault();
    this.update({ left, top, width, height });
  }

  registerBox = modifier((element: HTMLElement) => {
    this.box = element;

    const measure = () => {
      const { width, height } = element.getBoundingClientRect();

      if (width !== this.boxSize.width || height !== this.boxSize.height) {
        this.boxSize = { width, height };
      }
    };

    // measured after rendering, once laid out
    schedule('afterRender', measure);
  });

  <template>
    {{! template-lint-disable no-invalid-interactive }}
    <div
      class="euiSaturation"
      data-test-subj="euiSaturation"
      tabindex="-1"
      style={{cssStyle (hash background=(hueBackground this.color))}}
      {{on "mousedown" this.onMouseDown}}
      {{on "touchstart" this.onTouch}}
      {{on "touchmove" this.onTouch}}
      {{on "keydown" this.onKeyDown}}
      ...attributes
    >
      <div class="euiSaturation__lightness" {{this.registerBox}}>
        <div class="euiSaturation__saturation"></div>
      </div>
      <button
        type="button"
        id="{{@id}}-saturationIndicator"
        class="euiSaturation__indicator"
        style={{cssStyle (hash left=this.indicator.left top=this.indicator.top)}}
        aria-roledescription={{this.roleDescription}}
        aria-label={{@hex}}
        aria-describedby="{{@id}}-instructions"
      ></button>
      <span hidden aria-live="assertive">{{@hex}}</span>
      <span hidden id="{{@id}}-instructions">{{this.instructions}}</span>
    </div>
  </template>
}

function hueBackground(color: HSV): string {
  return `hsl(${color[0]}, 100%, 50%)`;
}
