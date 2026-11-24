/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License
 * 2.0 and the Server Side Public License, v 1; you may not use this file except
 * in compliance with, at your election, the Elastic License 2.0 or the Server
 * Side Public License, v 1.
 */

/**
 * Pieces of the EUI 123.1.0 date picker family that cannot be extracted by
 * `scripts/generate-eui-styles.mjs`, ported by hand and checked against the
 * upstream sources in `scripts/eui-upstream-parity.test.mjs`:
 *
 * - `react_date_picker.styles.js` (`euiDatePickerVariables`,
 *   `euiReactDatePickerStyles`): upstream builds it with vanilla
 *   `@emotion/css`, which registers classes in Emotion's global cache. This
 *   port serializes the same styles instead, for `euiClass`. It styles the
 *   calendar markup (`react-datepicker__*` class names) the Absolute tab
 *   renders.
 * - The module-level styles of `quick_select.js` (React component module).
 *
 * Everything else comes from `styles.generated.ts`.
 */
import { euiShadowSmall } from '@elastic/eui-theme-common';
import { serializeStyles } from '@emotion/serialize';

import {
  euiButtonColor as _euiButtonColor,
  euiButtonEmptyColor as _euiButtonEmptyColor,
  euiButtonFillColor as _euiButtonFillColor,
  euiCanAnimate as _euiCanAnimate,
  euiFocusRing as _euiFocusRing,
  euiFontSize as _euiFontSize,
  euiFormControlDefaultShadow as _euiFormControlDefaultShadow,
  euiFormControlStyles as _euiFormControlStyles,
  euiFormControlText as _euiFormControlText,
  euiFormVariables as _euiFormVariables,
  euiMaxBreakpoint as _euiMaxBreakpoint,
  euiYScroll as _euiYScroll,
  highContrastModeStyles as _highContrastModeStyles,
  logicalCSS as _logicalCSS,
  logicalSizeCSS as _logicalSizeCSS,
  mathWithUnits as _mathWithUnits
} from './styles.generated.ts';

import type { EuiBorealisContext } from './theme.ts';
import type { SerializedStyles } from '@emotion/serialize';

type Ctx = EuiBorealisContext;

type Vars = any;

// The generated module is untyped (`@ts-nocheck`); this port is upstream's
// JavaScript, checked by the parity suite rather than the type checker.
// (Named imports, not a namespace: a namespace import would bundle every
// generated module.)
const {
  euiButtonColor,
  euiButtonEmptyColor,
  euiButtonFillColor,
  euiCanAnimate,
  euiFocusRing,
  euiFontSize,
  euiFormControlDefaultShadow,
  euiFormControlStyles,
  euiFormControlText,
  euiFormVariables,
  euiMaxBreakpoint,
  euiYScroll,
  highContrastModeStyles,
  logicalCSS,
  logicalSizeCSS,
  mathWithUnits
} = {
  euiButtonColor: _euiButtonColor,
  euiButtonEmptyColor: _euiButtonEmptyColor,
  euiButtonFillColor: _euiButtonFillColor,
  euiCanAnimate: _euiCanAnimate,
  euiFocusRing: _euiFocusRing,
  euiFontSize: _euiFontSize,
  euiFormControlDefaultShadow: _euiFormControlDefaultShadow,
  euiFormControlStyles: _euiFormControlStyles,
  euiFormControlText: _euiFormControlText,
  euiFormVariables: _euiFormVariables,
  euiMaxBreakpoint: _euiMaxBreakpoint,
  euiYScroll: _euiYScroll,
  highContrastModeStyles: _highContrastModeStyles,
  logicalCSS: _logicalCSS,
  logicalSizeCSS: _logicalSizeCSS,
  mathWithUnits: _mathWithUnits
} as any;

const css = (...args: unknown[]): SerializedStyles =>
  serializeStyles(args as Parameters<typeof serializeStyles>[0]);
/**
 * Upstream's nested `css` calls return registered class names, which the
 * outer call interpolates as their raw styles (no trailing `;`): the nested
 * helpers return the serialized string to match that byte for byte.
 */
const nestedCss = (...args: unknown[]): string => css(...args).styles;

export const euiDatePickerVariables = function euiDatePickerVariables(
  euiThemeContext: Ctx
) {
  const euiTheme: Vars = euiThemeContext.euiTheme,
    highContrastMode = euiThemeContext.highContrastMode;
  const unsetHighContrastBorder = function unsetHighContrastBorder(
    styles: Record<string, unknown>
  ) {
    return { ...styles, border: undefined };
  };
  return {
    gapSize: euiTheme.size.xs,
    get paddingSize() {
      return mathWithUnits(this.gapSize, function (x: number) {
        return x * 2;
      });
    },
    headerButtonSize: euiTheme.size.xl,
    get headerOffset() {
      return mathWithUnits(
        [this.headerButtonSize, this.gapSize],
        function (x: number, y: number) {
          return x + y;
        }
      );
    },
    colors: {
      day: {
        inMonth: euiTheme.colors.textHeading,
        outsideMonth: euiTheme.colors.textSubdued,
        header: euiTheme.colors.textSubdued,
        today: euiTheme.colors.primary
      },
      hover: unsetHighContrastBorder(
        euiButtonColor(euiThemeContext, 'primary')
      ),
      disabled: unsetHighContrastBorder(
        euiButtonColor(euiThemeContext, 'disabled')
      ),
      get inRange() {
        return this.hover;
      },
      inRangeAndDisabled: {
        backgroundColor: euiButtonEmptyColor(euiThemeContext, 'primary')
          .backgroundColor
      },
      selected:
        highContrastMode !== 'forced'
          ? euiButtonFillColor(euiThemeContext, 'primary')
          : {
              color: euiTheme.colors.emptyShade,
              backgroundColor: euiTheme.colors.fullShade,
              forcedColorAdjust: 'none'
            },
      selectedAndDisabled:
        highContrastMode !== 'forced'
          ? euiButtonColor(euiThemeContext, 'danger')
          : {
              color: euiTheme.colors.textDanger,
              backgroundColor: euiTheme.colors.emptyShade,
              border: ''
                .concat(euiTheme.border.width.thin, ' solid ')
                .concat(euiTheme.colors.textDanger, ';')
            },
      highlighted: euiButtonColor(euiThemeContext, 'success')
    },
    animationSpeed: euiTheme.animation.fast
  };
};
export const euiReactDatePickerStyles = function euiReactDatePickerStyles(
  euiThemeContext: Ctx
) {
  const euiTheme: Vars = euiThemeContext.euiTheme;
  const datePickerVars = euiDatePickerVariables(euiThemeContext);
  const gapSize = datePickerVars.gapSize,
    paddingSize = datePickerVars.paddingSize,
    headerOffset = datePickerVars.headerOffset;
  return {
    euiReactDatePicker: css(
      'display:flex;justify-content:center;padding:',
      paddingSize,
      ';font-size:',
      euiFontSize(euiThemeContext, 'xs').fontSize,
      ';color:',
      euiTheme.colors.textParagraph,
      ';&.react-datepicker--non-interactive{pointer-events:none;}.react-datepicker__focusTrap{display:flex;justify-content:center;gap:',
      paddingSize,
      ';}',
      euiMaxBreakpoint(euiThemeContext, 's'),
      '{&,.react-datepicker__focusTrap{flex-direction:column;}}.react-datepicker__header__dropdown{position:absolute;',
      logicalCSS('top', 0),
      ' ',
      logicalCSS('horizontal', headerOffset),
      ' padding:',
      paddingSize,
      ';display:flex;justify-content:center;gap:',
      gapSize,
      ';}.react-datepicker__navigation{z-index:1;position:absolute;',
      logicalCSS('top', paddingSize),
      '&:hover,&:focus{transform:none;}}.react-datepicker__navigation--previous{',
      logicalCSS('left', paddingSize),
      ';}.react-datepicker__navigation--next{',
      logicalCSS('right', paddingSize),
      ';}.react-datepicker__month-container{flex-grow:1;',
      logicalCSS('margin-top', headerOffset),
      ';}.react-datepicker__time-container{flex-grow:1;',
      logicalCSS(
        'margin-top',
        // The time select gets a little extra offset
        mathWithUnits([headerOffset, gapSize], function (x: number, y: number) {
          return x + y;
        })
      ),
      ' ',
      logicalCSS('margin-left', paddingSize),
      euiMaxBreakpoint(euiThemeContext, 's'),
      '{',
      logicalCSS('margin-top', gapSize),
      ' ',
      logicalCSS('margin-left', 0),
      ';}}',
      _monthYearDropdowns(euiThemeContext, datePickerVars),
      ' ',
      _dayCalendarStyles(euiThemeContext, datePickerVars),
      ' ',
      _timeSelectStyles(euiThemeContext, datePickerVars),
      ';;label:euiReactDatePicker;'
    )
  };
};
const _monthYearDropdowns = function _monthYearDropdowns(
  euiThemeContext: Ctx,
  _ref: Vars
) {
  const colors = _ref.colors;
  const euiTheme: Vars = euiThemeContext.euiTheme;
  const formStyles = euiFormControlStyles(euiThemeContext);
  return nestedCss(
    '.react-datepicker__year-read-view,.react-datepicker__month-read-view,.react-datepicker__month-year-read-view{display:flex;justify-content:space-between;align-items:center;',
    formStyles.compressed,
    ' ',
    euiFormControlText(euiThemeContext),
    ' font-weight:',
    euiTheme.font.weight.medium,
    ';',
    euiFormControlDefaultShadow(euiThemeContext),
    ' &:hover{cursor:pointer;text-decoration:underline;}}.react-datepicker__year-dropdown-container{position:relative;flex-grow:1;}.react-datepicker__month-dropdown-container{position:relative;flex-grow:2;}.react-datepicker__year-dropdown,.react-datepicker__month-dropdown{z-index:1;position:absolute;',
    euiYScroll(euiThemeContext, {
      height: 'auto'
    }),
    ' ',
    logicalCSS('max-height', '250px'),
    ' ',
    logicalCSS('width', '100%'),
    ' padding:',
    euiTheme.size.xs,
    ';background-color:',
    euiTheme.colors.emptyShade,
    ';border-radius:',
    euiTheme.border.radius.panel,
    ';',
    euiShadowSmall(euiThemeContext, {
      borderAllInHighContrastMode: true
    }),
    ';}.react-datepicker__year-dropdown{',
    logicalCSS('min-width', '100px'),
    ';}.react-datepicker__month-dropdown{',
    logicalCSS('min-width', '140px'),
    ';}.react-datepicker__year-option,.react-datepicker__month-option,.react-datepicker__month-year-option{display:flex;align-items:center;',
    logicalCSS('height', euiTheme.size.l),
    ' ',
    logicalCSS('margin-vertical', euiTheme.size.xs),
    ' ',
    logicalCSS('padding-horizontal', euiTheme.size.s),
    ' font-size:',
    euiFontSize(euiThemeContext, 's').fontSize,
    ';border-radius:',
    euiTheme.border.radius.control,
    ';cursor:pointer;&:hover{text-decoration:underline;}&--preselected{',
    colors.hover,
    ';}&--selected_year,&--selected_month{',
    colors.selected,
    ';}&--selected{display:none;}}'
  );
};
const _dayCalendarStyles = function _dayCalendarStyles(
  euiThemeContext: Ctx,
  _ref2: Vars
) {
  const gapSize = _ref2.gapSize,
    colors = _ref2.colors,
    animationSpeed = _ref2.animationSpeed;
  const euiTheme: Vars = euiThemeContext.euiTheme;
  const daySize = euiTheme.size.xl;
  const dayMargin = mathWithUnits(gapSize, function (x: number) {
    return x / 2;
  });
  const rangeMarginOffset = mathWithUnits(dayMargin, function (x: number) {
    return x * 1.5;
  });
  return nestedCss(
    '.react-datepicker__day-names,.react-datepicker__week{display:flex;justify-content:space-between;flex-grow:1;color:',
    colors.day.header,
    ';}.react-datepicker__day-name,.react-datepicker__day{display:inline-flex;justify-content:center;align-items:center;',
    logicalSizeCSS(daySize),
    ' margin:',
    dayMargin,
    ';font-weight:',
    euiTheme.font.weight.medium,
    ';}.react-datepicker__day{color:',
    colors.day.inMonth,
    ';border-radius:',
    euiTheme.border.radius.control,
    ';',
    euiCanAnimate,
    '{transition:transform ',
    animationSpeed,
    ' ease-in-out,background-color ',
    animationSpeed,
    ' ease-in;}&:hover{',
    colors.hover,
    ' text-decoration:underline;cursor:pointer;',
    euiCanAnimate,
    '{transform:scale(1.1);}}&--today{color:',
    colors.day.today,
    ';font-weight:',
    euiTheme.font.weight.bold,
    ';}&--outside-month{color:',
    colors.day.outsideMonth,
    ';}&--highlighted,&--highlighted:hover{',
    colors.highlighted,
    ';}&--in-range,&--in-range:hover{',
    colors.inRange,
    ';}',
    highContrastModeStyles(euiThemeContext, {
      // Ranges use 2 side box-shadows that are the same as the button
      // background to fill the gap between margins
      none: '\n          &--in-range:not(&--selected):not(:hover):not(&--disabled) {\n            box-shadow: -'
        .concat(rangeMarginOffset, ' 0 ')
        .concat(colors.inRange.backgroundColor, ',\n              ')
        .concat(rangeMarginOffset, ' 0 ')
        .concat(
          colors.inRange.backgroundColor,
          ';\n            border-radius: 0;\n\n            &:first-child {\n              box-shadow: '
        )
        .concat(rangeMarginOffset, ' 0 ')
        .concat(
          colors.inRange.backgroundColor,
          ';\n            }\n\n            &:last-child {\n              box-shadow: -'
        )
        .concat(rangeMarginOffset, ' 0 ')
        .concat(
          colors.inRange.backgroundColor,
          ';\n            }\n          }\n          /* Animate smoothly on hover */\n          &--in-range:not(&--selected) {\n            '
        )
        .concat(euiCanAnimate, ' {\n              transition: transform ')
        .concat(animationSpeed, ' ease-in-out,\n                box-shadow ')
        .concat(animationSpeed, ' ease-in-out,\n                border-radius ')
        .concat(
          animationSpeed,
          ' ease-in-out,\n                background-color '
        )
        .concat(
          animationSpeed,
          ' ease-in;\n            }\n          }\n        '
        ),
      // In Windows high contrast mode, use borders and pseudo elements instead of background colors
      forced:
        "\n          &--in-range:not(&--selected) {\n            position: relative;\n            transform: none;\n\n            &::before {\n              content: '';\n              position: absolute;\n              inset-inline: -"
          .concat(dayMargin, ';\n              inset-block: ')
          .concat(dayMargin, ';\n              border-block: ')
          .concat(
            euiTheme.border.thin,
            ';\n              pointer-events: none;\n            }\n          }\n          &--range-start:not(&--selected)::before {\n            border-inline-start: '
          )
          .concat(
            euiTheme.border.thin,
            ';\n          }\n          &--range-end:not(&--selected)::before {\n            border-inline-end: '
          )
          .concat(euiTheme.border.thin, ';\n          }\n        ')
    }),
    ' &--selected,&--selected:hover,&--in-selecting-range,&--in-selecting-range:hover{',
    colors.selected,
    ';}&--disabled,&--disabled:hover{',
    colors.disabled,
    ' ',
    highContrastModeStyles(euiThemeContext, {
      forced: 'opacity: 0.5;'
    }),
    ' cursor:not-allowed;text-decoration:none;transform:none;}&--disabled.react-datepicker__day--in-range:not(&--selected){&,&:hover{',
    colors.inRangeAndDisabled,
    ';}}&--in-selecting-range:not(&--in-range),&--disabled.react-datepicker__day--selected,&--disabled.react-datepicker__day--selected:hover{',
    colors.selectedAndDisabled,
    ' ',
    highContrastModeStyles(euiThemeContext, {
      forced: 'opacity: 1;'
    }),
    ';}}'
  );
};
const _timeSelectStyles = function _timeSelectStyles(
  euiThemeContext: Ctx,
  _ref3: Vars
) {
  const gapSize = _ref3.gapSize,
    colors = _ref3.colors,
    animationSpeed = _ref3.animationSpeed;
  const euiTheme: Vars = euiThemeContext.euiTheme;
  return nestedCss(
    '.react-datepicker__time-container{display:flex;',
    logicalCSS('width', 'auto'),
    ' background-color:',
    euiTheme.colors.backgroundBaseSubdued,
    ';border-radius:',
    euiTheme.border.radius.control,
    ';&--focus{.react-datepicker__time-list-item--preselected{text-decoration:underline;}}}.react-datepicker__time,.react-datepicker__time-box{display:flex;flex-direction:column;flex-grow:1;}.react-datepicker__time-list{',
    euiYScroll(euiThemeContext, {
      height: '100px'
    }),
    ' display:flex;flex-direction:column;flex-grow:1;align-items:center;gap:',
    gapSize,
    ';',
    logicalCSS('padding-vertical', euiTheme.size.xs),
    ' ',
    logicalCSS('padding-horizontal', euiTheme.size.m),
    ' &:focus-visible{outline-style:auto;}}.react-datepicker__time-list-item{display:flex;justify-content:align-center;align-items:center;',
    logicalCSS('min-height', euiTheme.size.l),
    ' ',
    logicalCSS('margin-horizontal', 'auto'),
    ' ',
    logicalCSS('padding-horizontal', euiTheme.size.s),
    ' font-size:',
    euiFontSize(euiThemeContext, 'xs').fontSize,
    ';font-weight:',
    euiTheme.font.weight.medium,
    ';white-space:nowrap;border-radius:',
    euiTheme.border.radius.control,
    ';&:not(:disabled):hover{text-decoration:underline;cursor:pointer;}&--disabled{cursor:not-allowed;color:',
    colors.disabled.color,
    ';}&--injected{',
    colors.highlighted,
    ';}&--selected{',
    colors.selected,
    ';}&--preselected{',
    colors.hover,
    ' ',
    highContrastModeStyles(euiThemeContext, {
      // Use negative margins to offset the added border width
      forced: '\n            border: '
        .concat(euiTheme.border.thin, ';\n            margin-inline: -')
        .concat(euiTheme.border.width.thin, ';\n          ')
    }),
    ';}',
    euiCanAnimate,
    '{transition:background-color ',
    animationSpeed,
    ' ease-in;}}&.react-datepicker--time-only{padding:0;.react-datepicker__time-container{background-color:transparent;margin:0;}.react-datepicker__time-list{',
    logicalCSS('height', '204px'),
    ';}.react-datepicker__time-list-item{',
    logicalCSS('min-width', '112px'),
    ' font-size:',
    euiFontSize(euiThemeContext, 's').fontSize,
    ';text-align:start;}}'
  );
};

/**
 * Not a port: what the `EuiDatePicker` calendar adds to the styles above
 * (DESIGN 7.1, 7.4). Only `components/eui-date-picker/calendar.gts` applies
 * it, after `euiReactDatePickerStyles`; the Absolute tab's calendar does not
 * change, and the port above stays byte for byte upstream's.
 *
 * - The month is a `table` (the ARIA grid) laid out as upstream's flex
 *   rows: the classes carry the layout, the table parts only lose theirs.
 * - Each day cell holds a `button` that fills it and inherits its look.
 * - The focused day gets EUI's focus ring, outset so it shows on the
 *   selected (filled) day too; upstream has no rule for it.
 * - Today also gets a dot under the number, so it does not rely on colour
 *   alone and stays visible when selected or disabled.
 * - A disabled calendar dims its days (upstream keeps their colour; only the
 *   frame changes); the selected day keeps its fill and its readable text
 *   (the disabled frame's inherited `-webkit-text-fill-color` would paint
 *   it in the disabled colour on the fill).
 * - The month and year selects are form controls with their own
 *   `.euiFormControlLayout`: the inline frame's styles (upstream's
 *   `.euiFormControlLayout` rules for shadow, invalid, disabled and
 *   read-only, written for the outer layout) must not reach them, or each
 *   select gets the frame's shadow and the invalid outline.
 * - The time list: a hovered time gets the days' hover tint (upstream only
 *   underlines it, which is hard to see on a short label); a disabled time
 *   is neither underlined nor a pointer on hover (upstream's
 *   `:not(:disabled)` never matches a list item); the list's focus is
 *   EUI's focus ring instead of the browser's `outline-style: auto`, and
 *   the active time of a focused list (`data-active`) gets a ring of its
 *   own, so the keyboard position shows also on the selected (filled)
 *   time.
 */
export const euiDatePickerCalendarStyles = function euiDatePickerCalendarStyles(
  euiThemeContext: Ctx
) {
  const euiTheme: Vars = euiThemeContext.euiTheme;
  const colors = euiDatePickerVariables(euiThemeContext).colors;
  return css(
    '.react-datepicker__month{display:block;margin:0;border-collapse:collapse;border-spacing:0;}',
    '.react-datepicker__month>thead,.react-datepicker__month>tbody{display:block;}',
    '.react-datepicker__day-name,.react-datepicker__day{padding:0;text-align:center;}',
    '.react-datepicker__day--empty{visibility:hidden;}',
    '.react-datepicker__day-button{display:flex;justify-content:center;align-items:center;',
    'inline-size:100%;block-size:100%;margin:0;padding:0;border:0;background:none;',
    'color:inherit;font:inherit;text-decoration:inherit;border-radius:inherit;cursor:inherit;',
    '&:focus{',
    euiFocusRing(euiThemeContext, 'outset'),
    '}}',
    '.react-datepicker__day--today{position:relative;&::after{content:"";position:absolute;',
    logicalCSS('bottom', '3px'),
    ' ',
    logicalCSS('left', '50%'),
    ' ',
    logicalSizeCSS('4px'),
    ' ',
    logicalCSS('margin-left', '-2px'),
    ' border-radius:50%;background-color:currentColor;pointer-events:none;}}',
    '&.euiDatePickerCalendar--disabled .react-datepicker__day:not(.react-datepicker__day--selected){color:',
    euiTheme.colors.textDisabled,
    ';}',
    '.react-datepicker__day{-webkit-text-fill-color:currentColor;}',
    '.react-datepicker__header .euiFormControlLayout{background-color:transparent;background-image:none;box-shadow:none;outline:none;border:none;--euiFormControlStateColor:initial;}',
    '.react-datepicker__time-list .react-datepicker__time-list-item:not(.react-datepicker__time-list-item--disabled):not(.react-datepicker__time-list-item--selected):hover{',
    colors.hover,
    '}',
    '.react-datepicker__time-list .react-datepicker__time-list-item--disabled{cursor:not-allowed;&:hover{text-decoration:none;cursor:not-allowed;}}',
    '.react-datepicker__time-list:focus-visible{',
    euiFocusRing(euiThemeContext, 'inset'),
    '}',
    '.react-datepicker__time-list:focus-visible .react-datepicker__time-list-item[data-active]{outline:',
    euiTheme.border.width.thick,
    ' solid ',
    euiTheme.colors.primary,
    ';outline-offset:',
    euiTheme.border.width.thick,
    ';}',
    ';label:euiDatePickerCalendar;'
  );
};

/**
 * Not a port: `EuiDatePicker`'s input while it shows typed text that was
 * refused (DESIGN 5.3). EUI's invalid border yields to the focus border
 * (`:not(:focus)`), but this error is made while the input has focus (Enter):
 * without this, only the small warning icon would show it. The input keeps
 * the invalid border while focused; other invalid inputs are unchanged.
 */
export const euiDatePickerInputErrorStyles =
  function euiDatePickerInputErrorStyles(euiThemeContext: Ctx) {
    return css(
      '&&:focus{',
      euiFormControlStyles(euiThemeContext).invalid,
      '};label:euiDatePickerInputError;'
    );
  };

/**
 * Not a port: `EuiDatePicker`'s native input (DESIGN 6.1), an
 * `EuiFieldText` of `type="date"`, `datetime-local` or `time`.
 *
 * - `color-scheme` follows EUI's colour mode, so the browser's own parts
 *   (the segments, the OS picker where the engine draws it) match the theme,
 *   as upstream's `EuiFieldNumber` does.
 * - The browser's picker indicator is hidden while EUI's icon opens the
 *   picker (`data-picker-icon`); without the icon (`@showIcon={{false}}`,
 *   `@controlOnly`) it stays, the only pointer way in on a desktop.
 * - WebKit (iOS) centres the value and gives an empty input no line box:
 *   the value starts at the inline start and keeps a line's height.
 * - The segments' own padding is dropped, so the text sits where
 *   `EuiFieldText`'s does.
 * - An empty input (`data-empty`, set by the picker: CSS cannot tell) shows
 *   its segments (`mm/dd/yyyy`) in EUI's placeholder colour, not as a value.
 * - A disabled input's segments take EUI's disabled text colour (Chromium
 *   paints them with its own).
 */
export const euiDatePickerNativeStyles = function euiDatePickerNativeStyles(
  euiThemeContext: Ctx
) {
  const form: Vars = euiFormVariables(euiThemeContext);
  const dark = (euiThemeContext as { colorMode?: string }).colorMode === 'DARK';
  return css(
    'color-scheme:',
    dark ? 'dark' : 'light',
    ';',
    '&[data-picker-icon]::-webkit-calendar-picker-indicator{display:none;}',
    '&::-webkit-inner-spin-button{display:none;}',
    '&::-webkit-date-and-time-value{margin:0;text-align:start;min-block-size:1lh;}',
    '&::-webkit-datetime-edit{padding:0;}',
    '&[data-empty]::-webkit-datetime-edit{color:',
    form.controlPlaceholderText,
    ';-webkit-text-fill-color:',
    form.controlPlaceholderText,
    ';}',
    '&:disabled::-webkit-datetime-edit{color:',
    form.textColorDisabled,
    ';-webkit-text-fill-color:',
    form.textColorDisabled,
    ';}',
    ';label:euiDatePickerNative;'
  );
};

/**
 * `quick_select.js` module-level styles: the panel lets the previous/next
 * time window buttons overflow it, and they sit above the inputs, aligned
 * with the panel title.
 */
export const euiQuickSelectStyles = {
  panel: {
    name: '7yqi2-EuiQuickSelect',
    styles: '> div{position:relative;overflow:visible;};label:EuiQuickSelect;'
  },
  timeWindowButtons: {
    name: 'qbrd7j-EuiQuickSelect',
    styles:
      'position:absolute;right:0;bottom:100%;transform:translateY(-33%);label:EuiQuickSelect;'
  }
} as const;

/*
 * Scoped equivalents of the React global reset (`reset.js`), which Ember
 * does not inject per component: only what these surfaces rely on.
 */

/** `fieldset` reset (quick select panels, refresh interval). */
export const fieldsetReset = {
  margin: 0,
  padding: 0,
  border: 'none',
  minInlineSize: 'auto'
} as const;

/** `legend` reset (quick select panel titles). */
export const legendReset = {
  boxSizing: 'border-box',
  margin: 0,
  padding: 0,
  border: 'none'
} as const;

/** `ol, ul` reset (commonly / recently used lists). */
export const listReset = {
  margin: 0,
  padding: 0,
  listStyle: 'none'
} as const;
