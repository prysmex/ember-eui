import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { hash } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { service } from '@ember/service';

import {
  getChromaColor,
  getPositionFromStop,
  getStopFromMouseLocation,
  isColorInvalid,
  isStopInvalid
} from '../../-private/color.ts';
import { deprecateRemovedUpstream } from '../../-private/removed-upstream.ts';
import cssStyle from '../../-private/css-style.ts';
import { getEuiThemeContext } from '../../utils/emotion/consume.ts';
import {
  buttonReset,
  euiColorStopStyles,
  euiColorStopThumbPopoverStyles,
  euiColorStopThumbStyles
} from '../../utils/eui/color-picker.ts';
import { euiRangeThumbStyles } from '../../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../../utils/eui/styles.ts';
import EuiButtonIcon from '../eui-button-icon.gts';
import EuiColorPicker from '../eui-color-picker.gts';
import EuiFieldNumber from '../eui-field-number.gts';
import EuiFlexGroup from '../eui-flex-group.gts';
import EuiFlexItem from '../eui-flex-item.gts';
import EuiFormRow from '../eui-form-row.gts';
import EuiPopover from '../eui-popover.gts';
import EuiScreenReaderOnly from '../eui-screen-reader-only.gts';
import EuiSpacer from '../eui-spacer.gts';

import type EuiI18n from '../../services/eui-i18n';
import type { ColorStop } from '../../-private/color.ts';
import type { CSSInterpolation } from '@emotion/css/create-instance';
import type Owner from '@ember/owner';

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
const noop = (): void => {};

export default class EuiColorStopThumb extends Component<ThumbSignature> {
  constructor(owner: Owner, args: ThumbSignature['Args']) {
    super(owner, args);
    deprecateRemovedUpstream(
      'eui-color-stops-thumb',
      'EuiColorStopThumb',
      'There is no direct upstream replacement; for predefined gradients use EuiColorPalettePicker.'
    );
  }

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

  get hasFocusStyle(): boolean {
    return this.hasFocus || this.args.isPopoverOpen;
  }

  /** The popover root: EUI 88.5.4 `euiColorStopThumbPopoverStyles`. */
  @cached
  get popoverCss(): CSSInterpolation {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiColorStopThumbPopoverStyles);

    return [styles.euiColorStopThumbPopover, this.hasFocusStyle && styles.hasFocus];
  }

  /** Upstream EuiRangeThumb styles with the color stop thumb styles last. */
  @cached
  get thumbClasses(): string {
    const context = getEuiThemeContext(this);
    const range = useEuiBorealisStyles(context, euiRangeThumbStyles);
    const styles = useEuiBorealisStyles(context, euiColorStopThumbStyles);

    return `euiRangeThumb euiColorStopThumb ${euiClass(
      context,
      buttonReset,
      range.euiRangeThumb,
      styles.euiColorStopThumb,
      this.args.isPopoverOpen && styles.isPopoverOpen
    )}`;
  }

  @cached
  get formClasses(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiColorStopStyles);

    return `euiColorStop ${euiClass(context, styles.euiColorStop)}`;
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
    const up = () => this.stopDrag();

    event.preventDefault();
    this.stopDrag();
    document.addEventListener('mousemove', move);
    document.addEventListener('mouseup', up);
    window.addEventListener('blur', up);
    this.stopDrag = () => {
      document.removeEventListener('mousemove', move);
      document.removeEventListener('mouseup', up);
      window.removeEventListener('blur', up);
      this.stopDrag = noop;
    };
  }

  /** Removes the document drag listeners (also on teardown mid-drag). */
  stopDrag: () => void = noop;

  willDestroy(): void {
    super.willDestroy();
    this.stopDrag();
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
      class="euiColorStopPopover"
      style={{cssStyle (hash left=this.position)}}
      @rootCss={{this.popoverCss}}
      @anchorClassName="euiColorStopThumbPopover__anchor"
      @panelPaddingSize="s"
      @isOpen={{@isPopoverOpen}}
      @closePopover={{@closePopover}}
      @ownFocus={{false}}
    >
      <:button>
        {{! upstream EuiRangeThumb: a button with the slider role }}
        <button
          type="button"
          role="slider"
          class={{this.thumbClasses}}
          data-test-subj="euiColorStopThumb"
          data-index="euiColorStop_{{@index}}"
          aria-valuemin={{@localMin}}
          aria-valuemax={{@localMax}}
          aria-valuenow={{@stop}}
          aria-disabled={{if @disabled "true" "false"}}
          aria-valuetext={{this.valueText}}
          aria-label={{this.t
            "buttonAriaLabel"
            "Press the Enter key to modify this stop. Press Escape to focus the group"
          }}
          title={{this.t "buttonTitle" "Click to edit, drag to reposition"}}
          tabindex="-1"
          disabled={{@disabled}}
          style={{cssStyle (hash background=this.background)}}
          {{on "focus" this.onFocus}}
          {{on "blur" (fnSet this.setFocus false)}}
          {{on "mouseover" (fnSet this.setFocus true)}}
          {{on "mouseout" (fnSet this.setFocus false)}}
          {{on "keydown" this.onKeyDown}}
          {{on "mousedown" this.onMouseDown}}
        ></button>
      </:button>
      <:content>
        <div class={{this.formClasses}} data-test-subj="euiColorStopPopover">
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
