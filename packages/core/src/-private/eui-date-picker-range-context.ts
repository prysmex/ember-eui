import { getContext } from 'ember-provide-consume-context';

/**
 * What an `EuiDatePickerRange` gives the `EuiDatePicker` in its `<:start>`
 * or `<:end>` block (DESIGN 4.5): upstream clones its start and end
 * controls with these props (`date_picker_range.js:60-106`). The picker
 * takes them as defaults; its own `@disabled` and `@isInvalid` add to the
 * range's (OR), as upstream. Other inputs in the blocks ignore it.
 */
export interface EuiDatePickerRangeContext {
  /** The block the picker is in: the end opens its popover `downRight`. */
  readonly side: 'start' | 'end';
  /** Always true: the range draws the frame (upstream `controlOnly`). */
  readonly controlOnly: true;
  /** Always false: the range draws the icon (upstream `showIcon`). */
  readonly showIcon: false;
  readonly inline: boolean;
  /** Already false when the range is inline, as upstream. */
  readonly compressed: boolean;
  /** Already false when the range is inline, as upstream. */
  readonly fullWidth: boolean;
  readonly readOnly: boolean;
  readonly disabled: boolean;
  readonly isInvalid: boolean;
  /**
   * A picker tells the range whether it shows a time list, so an inline
   * range stacks its calendars below the wider width (upstream reads
   * `showTimeSelect` from its controls). `false` when it goes.
   */
  reportTimeSelect(picker: object, showTimeSelect: boolean): void;
}

export const EUI_DATE_PICKER_RANGE_CONTEXT =
  '@ember-eui/core/date-picker-range' as const;

declare module 'ember-provide-consume-context/context-registry' {
  export default interface ContextRegistry {
    [EUI_DATE_PICKER_RANGE_CONTEXT]: EuiDatePickerRangeContext;
  }
}

/** The range around a picker, or null outside one (and with `@isCustom`). Read in a getter so changes stay tracked. */
export function datePickerRangeContext(
  component: object
): EuiDatePickerRangeContext | null {
  return getContext(component, EUI_DATE_PICKER_RANGE_CONTEXT) ?? null;
}
