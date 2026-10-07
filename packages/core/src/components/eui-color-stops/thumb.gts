import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { hash } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { inject as service } from '@ember/service';

import {
  getChromaColor,
  getPositionFromStop,
  getStopFromMouseLocation,
  isColorInvalid,
  isStopInvalid
} from '../../-private/color.ts';
import cssStyle from '../../-private/css-style.ts';
import EuiButtonIcon from '../eui-button-icon.gts';
import EuiColorPicker from '../eui-color-picker.gts';
import EuiFieldNumber from '../eui-field-number.gts';
import EuiFlexGroup from '../eui-flex-group.gts';
import EuiFlexItem from '../eui-flex-item.gts';
import EuiFormRow from '../eui-form-row.gts';
import EuiPopover from '../eui-popover.gts';
import EuiRangeThumb from '../eui-range-thumb.gts';
import EuiScreenReaderOnly from '../eui-screen-reader-only.gts';
import EuiSpacer from '../eui-spacer.gts';

import type EuiI18n from '../../services/eui-i18n';
import type { ColorStop } from '../../-private/color.ts';

interface ThumbSignature {
  Element: HTMLButtonElement;
  Args: {
    stop: number;
    color: string;
    index: number;
    count: number;
    onChange: (colorStop: ColorStop) => void;
    onFocus: () => void;
    onRemove?: () => void;
    globalMin: number;
    globalMax: number;
    localMin: number;
    localMax: number;
    min?: number;
    max?: number;
    isRangeMin: boolean;
    isRangeMax: boolean;
    trackWidth: number;
    parent?: HTMLElement;
    mode?: 'default' | 'swatch' | 'picker';
    showAlpha?: boolean;
    swatches?: string[];
    disabled?: boolean;
    readOnly?: boolean;
    isPopoverOpen: boolean;
    openPopover: () => void;
    closePopover: () => void;
  };
}

/** @private One stop of EuiColorStops: a thumb opening an edit popover. */
export default class EuiColorStopThumb extends Component<ThumbSignature> {
  @service declare euiI18n: EuiI18n;

  @tracked hasFocus = false;

  get background(): string | undefined {
    return getChromaColor(this.args.color, this.args.showAlpha)?.css();
  }

  get position(): string {
    const { stop, trackWidth, globalMin, globalMax } = this.args;

    return `${getPositionFromStop(stop, trackWidth, globalMin, globalMax)}%`;
  }

  get stopIsInvalid(): boolean {
    return isStopInvalid(this.args.stop);
  }

  get colorIsInvalid(): boolean {
    return isColorInvalid(this.args.color, this.args.showAlpha);
  }

  get classes(): string {
    return this.hasFocus || this.args.isPopoverOpen
      ? 'euiColorStopPopover euiColorStopPopover-hasFocus'
      : 'euiColorStopPopover';
  }

  t = (token: string, text: string): string => this.euiI18n.lookupToken(`euiColorStopThumb.${token}`, text);

  get valueText(): string {
    return `Stop: ${this.args.stop}, Color: ${this.args.color} (${this.args.index + 1} of ${this.args.count})`;
  }

  /** Clamped to the neighbouring stops. */
  changeStop(value: number): void {
    const { localMin, localMax } = this.args;

    this.args.onChange({ stop: Math.min(Math.max(value, localMin), localMax), color: this.args.color });
  }

  @action
  onStopInput(event: Event): void {
    let value = parseFloat((event.target as HTMLInputElement).value);
    const { globalMin, globalMax, min, max } = this.args;

    if (value > globalMax && max !== undefined) value = globalMax;
    if (value < globalMin && min !== undefined) value = globalMin;

    this.args.onChange({ stop: value, color: this.args.color });
  }

  @action
  onColorChange(color: string): void {
    this.args.onChange({ stop: this.args.stop, color });
  }

  @action
  onMouseDown(event: MouseEvent): void {
    this.args.openPopover();

    if (this.args.readOnly) return;

    const parent = this.args.parent;
    const move = (e: MouseEvent) => {
      if (!parent) return;
      this.changeStop(
        getStopFromMouseLocation(
          { x: e.clientX, y: e.clientY },
          parent,
          this.args.globalMin,
          this.args.globalMax
        )
      );
    };
    const up = () => {
      document.removeEventListener('mousemove', move);
      document.removeEventListener('mouseup', up);
    };

    event.preventDefault();
    document.addEventListener('mousemove', move);
    document.addEventListener('mouseup', up);
  }

  @action
  onKeyDown(event: KeyboardEvent): void {
    switch (event.key) {
      case 'Enter':
        event.preventDefault();
        this.args.openPopover();
        break;
      case 'ArrowLeft':
        event.preventDefault();
        if (!this.args.readOnly) this.changeStop(this.args.stop - 1);
        break;
      case 'ArrowRight':
        event.preventDefault();
        if (!this.args.readOnly) this.changeStop(this.args.stop + 1);
        break;
    }
  }

  @action
  remove(): void {
    if (!this.args.onRemove) return;

    this.args.closePopover();
    this.args.onRemove();
  }

  @action
  onFocus(): void {
    this.hasFocus = true;
    this.args.onFocus();
  }

  @action
  setFocus(value: boolean): void {
    this.hasFocus = value;
  }

  <template>
    <EuiPopover
      class={{this.classes}}
      style={{cssStyle (hash left=this.position)}}
      @anchorClassName="euiColorStopPopover__anchor"
      @panelPaddingSize="s"
      @isOpen={{@isPopoverOpen}}
      @closePopover={{@closePopover}}
      @ownFocus={{false}}
    >
      <:button>
        <EuiRangeThumb
          class="euiColorStopThumb"
          data-test-subj="euiColorStopThumb"
          data-index="euiColorStop_{{@index}}"
          aria-valuetext={{this.valueText}}
          aria-label={{this.t
            "buttonAriaLabel"
            "Press the Enter key to modify this stop. Press Escape to focus the group"
          }}
          title={{this.t "buttonTitle" "Click to edit, drag to reposition"}}
          style={{cssStyle (hash background=this.background)}}
          @min={{@localMin}}
          @max={{@localMax}}
          @value={{@stop}}
          @tabIndex={{-1}}
          @disabled={{@disabled}}
          {{on "focus" this.onFocus}}
          {{on "blur" (fnSet this.setFocus false)}}
          {{on "mouseover" (fnSet this.setFocus true)}}
          {{on "mouseout" (fnSet this.setFocus false)}}
          {{on "keydown" this.onKeyDown}}
          {{on "mousedown" this.onMouseDown}}
        />
      </:button>
      <:content>
        <div class="euiColorStop" data-test-subj="euiColorStopPopover">
          <EuiScreenReaderOnly>
            <p aria-live="polite">{{this.t
                "screenReaderAnnouncement"
                "A popup with a color stop edit form opened. Tab forward to cycle through form controls or press escape to close this popup."
              }}</p>
          </EuiScreenReaderOnly>
          <EuiFlexGroup @gutterSize="s" @responsive={{false}}>
            <EuiFlexItem>
              <EuiFormRow
                @label={{this.t "stopLabel" "Stop value"}}
                @display="rowCompressed"
                @isInvalid={{this.stopIsInvalid}}
                @error={{if this.stopIsInvalid (this.t "stopErrorMessage" "Value is out of range")}}
              >
                <EuiFieldNumber
                  @compressed={{true}}
                  @readOnly={{@readOnly}}
                  @isInvalid={{this.stopIsInvalid}}
                  @value={{unless this.stopIsInvalid @stop}}
                  @min={{unless (or2 @isRangeMin (isUndefined @min)) @localMin}}
                  @max={{unless (or2 @isRangeMax (isUndefined @max)) @localMax}}
                  {{on "input" this.onStopInput}}
                />
              </EuiFormRow>
            </EuiFlexItem>
            {{#unless @readOnly}}
              <EuiFlexItem @grow={{false}}>
                <EuiFormRow @display="rowCompressed" @hasEmptyLabelSpace={{true}}>
                  <EuiButtonIcon
                    @iconType="trash"
                    @color="danger"
                    @isDisabled={{isUndefined @onRemove}}
                    aria-label={{this.t "removeLabel" "Remove this stop"}}
                    title={{this.t "removeLabel" "Remove this stop"}}
                    {{on "click" this.remove}}
                  />
                </EuiFormRow>
              </EuiFlexItem>
            {{/unless}}
          </EuiFlexGroup>
          {{#unless @readOnly}}
            <EuiSpacer @size="s" />
          {{/unless}}
          <EuiColorPicker
            @color={{@color}}
            @onChange={{this.onColorChange}}
            @readOnly={{@readOnly}}
            @mode={{if @readOnly "secondaryInput" @mode}}
            @swatches={{@swatches}}
            @display="inline"
            @showAlpha={{@showAlpha}}
            @isInvalid={{this.colorIsInvalid}}
            @secondaryInputDisplay={{if (isSwatch @mode) "none" "bottom"}}
          />
        </div>
      </:content>
    </EuiPopover>
  </template>
}

function fnSet(setter: (value: boolean) => void, value: boolean): () => void {
  return () => setter(value);
}

function or2(a: unknown, b: unknown): boolean {
  return Boolean(a || b);
}

function isUndefined(value: unknown): boolean {
  return value === undefined;
}

function isSwatch(mode?: string): boolean {
  return mode === 'swatch';
}
