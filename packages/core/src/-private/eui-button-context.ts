/*
 * Ported from @elastic/eui 123.1.0 `components/button/button_context.tsx` and
 * `components/button/use_button_common_props.ts`.
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under
 * one or more contributor license agreements. Licensed under the Elastic
 * License 2.0 or the Server Side Public License, v 1; see vendor/eui-latest.
 */

export interface EuiButtonSelectionProps {
  isSelected: boolean;
  fill: boolean;
  display?: 'fill' | 'base';
  onSelect: () => void;
}

/**
 * Button props cascaded from a parent (upstream `EuiButtonContext`). An
 * `EuiButtonGroup` with a block yields `EuiButton`, `EuiButtonEmpty` and
 * `EuiButtonIcon` curried with this as their private `@buttonContext`.
 *
 * Context values take precedence over the same argument passed directly,
 * except `isDisabled`/`hasAriaDisabled`, which are only ever `true` (never
 * `false`), so a group never enables a manually disabled child.
 */
export interface EuiButtonContext {
  readonly color?: string;
  readonly size?: 's' | 'm';
  readonly isDisabled?: true;
  readonly hasAriaDisabled?: true;
  readonly fullWidth?: boolean;
  readonly display?: 'base' | 'fill' | 'empty';
  readonly fill?: boolean;
  /** Set by `@variant="selection"` groups to resolve each button's selected state. */
  readonly getSelectionProps?: (
    id: string,
    isDisabled?: boolean
  ) => EuiButtonSelectionProps;
  /**
   * @private Ember only: wrap the button in an `.euiButtonGroup__item`
   * element (upstream's group wraps its children itself).
   */
  readonly wrapInItem?: boolean;
}

interface CommonPropsInput {
  context: EuiButtonContext | undefined;
  size?: string;
  color?: string;
  isDisabled?: boolean;
  disabled?: boolean;
  isLoading?: boolean;
  hasAriaDisabled?: boolean;
  fullWidth?: boolean;
  fill?: boolean;
  display?: string;
  id?: string;
  isSelected?: boolean;
}

export interface EuiButtonCommonProps {
  size: string | undefined;
  color: string | undefined;
  isDisabled: boolean;
  hasAriaDisabled: boolean;
  fullWidth: boolean | undefined;
  fill: boolean | undefined;
  display: string | undefined;
  isSelected: boolean | undefined;
  /** The group's selection callback, run on click before the button's own handlers. */
  onSelect: (() => void) | undefined;
}

/**
 * Upstream `useEuiButtonCommonProps`: resolves inherited props from the
 * button context and computes the disabled state (`isDisabled`, `disabled`
 * or `isLoading`; Ember EUI does not validate `@href`).
 */
export function resolveButtonCommonProps(
  input: CommonPropsInput
): EuiButtonCommonProps {
  const context = input.context ?? {};
  const isDisabled = Boolean(
    input.isLoading ||
      (context.isDisabled ?? input.isDisabled) ||
      input.disabled
  );
  const selection =
    input.id != null
      ? context.getSelectionProps?.(input.id, isDisabled)
      : undefined;

  return {
    size: context.size ?? input.size,
    color: context.color ?? input.color,
    isDisabled,
    hasAriaDisabled: Boolean(context.hasAriaDisabled ?? input.hasAriaDisabled),
    fullWidth: context.fullWidth ?? input.fullWidth,
    display: context.display ?? selection?.display ?? input.display,
    fill:
      selection?.fill !== undefined
        ? selection.fill
        : context.fill !== undefined
          ? context.fill
          : input.fill,
    isSelected: selection?.isSelected ?? input.isSelected,
    onSelect: selection?.onSelect
  };
}
