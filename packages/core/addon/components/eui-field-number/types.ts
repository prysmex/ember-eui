import { CommonArgs } from '../common';
import { EuiFormControlLayoutArgs } from '../eui-form-control-layout/types';

import { IconType } from '../eui-icon';

export type EuiFieldNumberArgs = Omit<HTMLInputElement, 'min' | 'max' | 'readOnly' | 'step'> &
  CommonArgs & {
    icon?: IconType;
    isInvalid?: boolean;
    fullWidth?: boolean;
    isLoading?: boolean;
    readOnly?: boolean;
    min?: number;
    max?: number;
    /**
     * Specifies the granularity that the value must adhere to.
     * Accepts a `number` or the string `'any'` for no stepping to allow for any value.
     * Defaults to `1`
     */
    step?: number | 'any';
    inputRef?: HTMLInputElement;

    /**
     * Creates an input group with element(s) coming before input.
     * `string` | `ReactElement` or an array of these
     */
    prepend?: EuiFormControlLayoutArgs['prepend'];

    /**
     * Creates an input group with element(s) coming after input.
     * `string` | `ReactElement` or an array of these
     */
    append?: EuiFormControlLayoutArgs['append'];

    /**
     * Completely removes form control layout wrapper and ignores
     * icon, prepend, and append. Best used inside EuiFormControlLayoutDelimited.
     */
    controlOnly?: boolean;

    /**
     * when `true` creates a shorter height input
     */
    compressed?: boolean;
  };
