import { and, or } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';
import EuiFormControlLayoutIcons from './eui-form-control-layout-icons.gts';

import type { EuiFormControlLayoutIconsSignature } from './eui-form-control-layout-icons';
import type { TemplateOnlyComponent } from '@ember/component/template-only';
import type Component from '@glimmer/component';

type StringOrComponent = string | Component;
type PrependAppendType = StringOrComponent | StringOrComponent[];

export interface EuiFormControlLayoutSignature {
  Element: HTMLDivElement;
  Args: {
    fullWidth?: boolean;
    /**
     * Creates an input group with element(s) coming before children.
     * */
    compressed?: boolean;
    readOnly?: boolean;
    useGroup?: boolean;
    disabled?: boolean;
    isDisabled?: boolean;
    icon?: EuiFormControlLayoutIconsSignature['Args']['icon'];
    iconSide?: EuiFormControlLayoutIconsSignature['Args']['iconSide'];
    clear?: EuiFormControlLayoutIconsSignature['Args']['clear'];
    isLoading?: boolean;
    inputId?: string;
  };
  Blocks: {
    prepend: [classes: 'euiFormControlLayout__prepend'];
    field: [];
    default: [];
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
