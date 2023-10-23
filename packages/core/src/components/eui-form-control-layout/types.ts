import Component from '@glimmer/component';
import { CommonArgs } from '../common';
import { EuiFormControlLayoutIconsArgs } from '../eui-form-control-layout-icons/types';

type StringOrComponent = string | Component;
type PrependAppendType = StringOrComponent | StringOrComponent[];

export type EuiFormControlLayoutArgs = CommonArgs &
  HTMLDivElement & {
    /**
     * Creates an input group with element(s) coming before children.
     * `string` | `Component` or an array of these
     */
    prepend?: PrependAppendType;
    /**
     * Creates an input group with element(s) coming after children.
     * `string` | `Component` or an array of these
     */
    append?: PrependAppendType;
    children?: Component;
    icon?: EuiFormControlLayoutIconsArgs['icon'];
    clear?: EuiFormControlLayoutIconsArgs['clear'];
    fullWidth?: boolean;
    isLoading?: boolean;
    isDisabled?: boolean;
    className?: string;
    compressed?: boolean;
    readOnly?: boolean;
    /**
     * Connects the prepend and append labels to the input
     */
    inputId?: string;
  };
