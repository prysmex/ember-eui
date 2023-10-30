import classNames from '../helpers/class-names';

import { CommonArgs } from './common';

export type EuiRangeSliderArgs = HTMLInputElement &
  CommonArgs & {
    id?: string;
    name?: string;
    min: number;
    max: number;
    step?: number;
    compressed?: boolean;
    hasFocus?: boolean;
    showRange?: boolean;
    showTicks?: boolean;
    disabled?: boolean;
    tabIndex?: number;
    onChange?: InputEvent;
  };

<template>
  {{! @glint-nocheck: not typesafe yet }}
  <input
    type="range"
    id={{@id}}
    name={{@name}}
    class={{classNames
      "euiRangeSlider"
      (if @showTicks "euiRangeSlider--hasTicks")
      (if @hasFocus "euiRangeSlider--hasFocus")
      (if @showRange "euiRangeSlider--hasRange")
      (if @compressed "euiRangeSlider--compressed")
    }}
    min={{@min}}
    max={{@max}}
    step={{@step}}
    value={{@value}}
    disabled={{@disabled}}
    ...attributes
  />
</template>
