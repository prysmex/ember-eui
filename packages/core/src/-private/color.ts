import chroma from 'chroma-js';

import { euiPaletteColorBlind } from '../utils/color/eui_palettes.ts';

import type { Color } from 'chroma-js';

export type HSV = [number, number, number];
export type RGBA = [number, number, number, number];

export interface ColorStop {
  /** Position of the stop, in the palette's units (e.g. 0 to 100). */
  stop: number;
  /** Its color. */
  color: string;
}

export const HEX_FALLBACK = '';
export const HSV_FALLBACK: HSV = [0, 0, 0];
export const RGB_FALLBACK: RGBA = [NaN, NaN, NaN, 1];
export const RGB_JOIN = ', ';

/** EUI's color-blind safe palette, the default swatches of EuiColorPicker. */
export const VISUALIZATION_COLORS: string[] = euiPaletteColorBlind();

/**
 * Where a pointer is inside an element, clamped to its box:
 * `{ left, top, width, height }` in px.
 */
export function getEventPosition(
  location: { x: number; y: number },
  container: HTMLElement
): { left: number; top: number; width: number; height: number } {
  const { width, height, left, top } = container.getBoundingClientRect();

  return {
    left: Math.min(Math.max(location.x - left, 0), width),
    top: Math.min(Math.max(location.y - top, 0), height),
    width,
    height
  };
}

/** A hex string, or `r, g, b(, a)` numbers from a comma separated string. */
export function parseColor(input?: string | null): string | number[] | null {
  if (!input) return null;

  if (input.indexOf(',') > 0) {
    if (!/^[\s,.0-9]*$/.test(input)) return null;

    const rgb = input
      .trim()
      .split(',')
      .filter((n) => n !== '')
      .map(Number);

    return rgb.length > 2 && rgb.length < 5 ? rgb : HEX_FALLBACK;
  }

  return input;
}

/** Whether the color is a valid hex, `r, g, b` or `r, g, b, a` color. */
export function chromaValid(color: string | number[]): boolean {
  const parsed = typeof color === 'string' ? parseColor(color) : color;

  if (!parsed) return false;
  if (typeof parsed === 'object') {
    return chroma.valid(parsed, 'rgb') || chroma.valid(parsed, 'rgba');
  }

  return chroma.valid(parsed, 'hex');
}

/**
 * A chroma-js color from a hex or `r, g, b(, a)` string, or `null` when
 * invalid (or transparent while `allowOpacity` is false).
 */
export function getChromaColor(input?: string | null, allowOpacity = false): Color | null {
  const parsed = parseColor(input);

  if (!parsed || !chromaValid(parsed)) return null;

  const color =
    typeof parsed === 'object'
      ? chroma(parsed as [number, number, number])
      : chroma(parsed);

  if (typeof parsed === 'object' && parsed.length === 4) color.alpha(parsed[3]!);

  return !allowOpacity && color.alpha() < 1 ? null : color;
}

function hasStops(palette: (string | ColorStop)[]): palette is ColorStop[] {
  return palette.some((item) => typeof item === 'object');
}

/** A CSS `linear-gradient` through the colors (evenly) or color stops. */
export function getLinearGradient(palette: (string | ColorStop)[]): string {
  const last = palette.length - 1;

  if (hasStops(palette)) {
    const scale = 100 / palette[last]!.stop;
    const middle = palette
      .slice(1, last)
      .map(({ color, stop }) => ` ${color} ${Math.floor(stop * scale)}%,`)
      .join('');

    return `linear-gradient(to right, ${palette[0]!.color} 0%,${middle} ${palette[last]!.color} 100%)`;
  }

  const colors = palette as string[];
  const middle = colors
    .slice(1, last)
    .map((color, i) => ` ${color} ${Math.floor((100 * (i + 1)) / last)}%,`)
    .join('');

  return `linear-gradient(to right, ${colors[0]} 0%,${middle} ${colors[last]} 100%)`;
}

/** Blocks of solid color: `{ color, width }` for each color or stop. */
export function getFixedLinearGradient(
  palette: (string | ColorStop)[]
): { color: string; width: string }[] {
  if (hasStops(palette)) {
    const scale = 100 / palette[palette.length - 1]!.stop;

    return palette.map(({ color, stop }, index) => {
      const previous = index === 0 ? 0 : Math.floor(palette[index - 1]!.stop * scale);

      return { color, width: `${Math.floor(stop * scale) - previous}%` };
    });
  }

  return (palette as string[]).map((color) => ({ color, width: `${100 / palette.length}%` }));
}

/** The default color of new color stops (EUI's second visualization color). */
export const DEFAULT_VISUALIZATION_COLOR: string = VISUALIZATION_COLORS[1]!;

/** Width of a range thumb in px. */
export const EUI_THUMB_SIZE = 16;

/** `steps` colors evenly spread over the color stops. */
export function getSteppedGradient(colors: ColorStop[], steps: number): string[] {
  const offset = colors[0]!.stop;
  const range = colors[colors.length - 1]!.stop - offset;

  return chroma
    .scale(colors.map((item) => item.color))
    .domain(colors.map((item) => (item.stop - offset) / range))
    .colors(steps);
}

/* color stops ------------------------------------------------------------ */

export function removeStop(colorStops: ColorStop[], index: number): ColorStop[] {
  if (colorStops.length === 1) return colorStops;

  return [...colorStops.slice(0, index), ...colorStops.slice(index + 1)];
}

export function addDefinedStop(
  colorStops: ColorStop[],
  stop: number,
  color = DEFAULT_VISUALIZATION_COLOR
): ColorStop[] {
  return [...colorStops, { stop, color }].sort((a, b) => a.stop - b.stop);
}

/** A stop after the last one, at the same distance as the last two. */
export function addStop(
  colorStops: ColorStop[],
  color = DEFAULT_VISUALIZATION_COLOR,
  max: number
): ColorStop[] {
  const index = colorStops.length ? colorStops.length - 1 : 0;
  const stops = colorStops.map((el) => el.stop);
  const currentStop = stops[index] ?? max;
  const delta = index !== 0 ? currentStop - stops[index - 1]! : 1;
  let stop = Math.min(currentStop + delta, max);

  // at the max: go back to the first free value
  while (stops.includes(stop)) stop--;

  return [...colorStops.slice(0, index + 1), { stop, color }, ...colorStops.slice(index + 1)];
}

export function isColorInvalid(color: string, showAlpha = false): boolean {
  return getChromaColor(color, showAlpha) === null || color === '';
}

export function isStopInvalid(stop: number | null | undefined): boolean {
  return stop === null || stop === undefined || isNaN(stop);
}

export function isStopsInvalid(colorStops: ColorStop[], showAlpha = false): boolean {
  return colorStops.some(
    (colorStop) => isColorInvalid(colorStop.color, showAlpha) || isStopInvalid(colorStop.stop)
  );
}

function calculateScale(trackWidth: number): number {
  return (1 - EUI_THUMB_SIZE / trackWidth) * 100;
}

export function getStopFromMouseLocation(
  location: { x: number; y: number },
  element: HTMLElement,
  min: number,
  max: number
): number {
  const box = getEventPosition(location, element);

  return Math.round((box.left / box.width) * (max - min) + min);
}

/** The stop's position in percent of the track (keeping the thumb inside). */
export function getPositionFromStop(stop: number, trackWidth: number, min: number, max: number): number {
  return parseFloat(
    (((stop - min) / (max - min)) * calculateScale(trackWidth > 0 ? trackWidth : 100)).toFixed(1)
  );
}
