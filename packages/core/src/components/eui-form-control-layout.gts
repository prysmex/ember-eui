import { and, or } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import EuiFormControlLayoutIcons from './eui-form-control-layout-icons.gts';

import type { EuiFormControlLayoutIconsSignature } from './eui-form-control-layout-icons';
import type { TemplateOnlyComponent } from '@ember/component/template-only';


/**
 * The wrapper EUI's inputs use for icons, the clear button, the loading
 * spinner and prepend/append content. Use it around your own controls to
 * match them.
 */
export interface EuiFormControlLayoutSignature {
  Element: HTMLDivElement;
  Args: {
    /** Stretches the control to its container's width. */
    fullWidth?: boolean;
    /** Shorter control, for dense forms. */
    compressed?: boolean;
    /** Read-only styling. */
    readOnly?: boolean;
    /**
     * Styles the control as a group with its `<:prepend>` / `<:append>`
     * content. Defaults to `true`.
     */
    useGroup?: boolean;
    /** Disabled styling. */
    disabled?: boolean;
    /** Same as `@disabled`. */
    isDisabled?: boolean;
    /** Icon inside the control, anything `EuiIcon`'s `@type` accepts. */
    icon?: EuiFormControlLayoutIconsSignature['Args']['icon'];
    /** Side of `@icon`: `'left'` or `'right'`. Defaults to `'left'`. */
    iconSide?: EuiFormControlLayoutIconsSignature['Args']['iconSide'];
    /** Shows a clear ("x") button calling this function. */
    clear?: EuiFormControlLayoutIconsSignature['Args']['clear'];
    /** Shows a spinner. */
    isLoading?: boolean;
    /** @deprecated Has no effect. */
    inputId?: string;
  };
  Blocks: {
    /** Content before the control; yields the class to put on it. */
    prepend: [classes: 'euiFormControlLayout__prepend'];
    /** The control (e.g. an `<input>`); same as the default block. */
    field: [];
    /** The control. */
    default: [];
    /** Content after the control; yields the class to put on it. */
    append: [classes: 'euiFormControlLayout__append'];
  };
}

const EuiFormControlLayout: TemplateOnlyComponent<EuiFormControlLayoutSignature> =
  <template>
    <div
      class={{classNames
        (if @fullWidth "euiFormControlLayout--fullWidth")
        (if @compressed "euiFormControlLayout--compressed")
        (if @readOnly "euiFormControlLayout--readOnly")
        (if
          (and
            (argOrDefault @useGroup true)
            (or (has-block "append") (has-block "prepend"))
          )
          "euiFormControlLayout--group"
        )
        (if (or @disabled @isDisabled) "euiFormControlLayout--isDisabled")
        "euiFormControlLayout"
      }}
      ...attributes
    >
      {{#if (has-block "prepend")}}
        {{yield "euiFormControlLayout__prepend" to="prepend"}}
      {{/if}}
      <div class="euiFormControlLayout__childrenWrapper">
        {{#if (has-block "field")}}
          {{yield to="field"}}
        {{else}}
          {{yield}}
        {{/if}}
        <EuiFormControlLayoutIcons
          @icon={{@icon}}
          @iconSide={{@iconSide}}
          @clear={{@clear}}
          @compressed={{@compressed}}
          @isLoading={{@isLoading}}
        />
      </div>
      {{#if (has-block "append")}}
        {{yield "euiFormControlLayout__append" to="append"}}
      {{/if}}
    </div>
  </template>;

export default EuiFormControlLayout;
