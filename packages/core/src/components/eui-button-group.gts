import { get } from '@ember/helper';

import { and, eq } from 'ember-truth-helpers';
import { notEq } from 'ember-truth-helpers';

import randomId from '../-private/random-id.ts';
import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import screenReaderOnly from '../modifiers/screen-reader-only.ts';
import EuiButtonGroupButton from './eui-button-group-button.gts';

import type { EuiButtonGroupButtonSignature } from './eui-button-group-button';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface Option {
  /** Disables this option. Defaults to the group's `@isDisabled`. */
  isDisabled?: boolean;
  /** Icon of the option; required for `@isIconOnly` groups. */
  iconType?: EuiButtonGroupButtonSignature['Args']['iconType'];
  /** Value passed to `@onChange` (single selection only). */
  value?: EuiButtonGroupButtonSignature['Args']['value'];
  /**
   * Text of the option. Always set it: with `@isIconOnly` it is hidden but
   * read by screen readers.
   */
  label?: EuiButtonGroupButtonSignature['Args']['label'];
  /** Unique id of the option, used by `@idSelected` / `@idToSelectedMap`. */
  id: EuiButtonGroupButtonSignature['Args']['id'];
  /** Shows a spinner instead of the icon. */
  isLoading?: EuiButtonGroupButtonSignature['Args']['isLoading'];
  /** `'right'` puts the icon after the text. */
  iconSide?: EuiButtonGroupButtonSignature['Args']['iconSide'];
  /** Size of the icon. */
  iconSize?: EuiButtonGroupButtonSignature['Args']['iconSize'];
  /** Classes for the element wrapping the text. */
  textClasses?: EuiButtonGroupButtonSignature['Args']['textClasses'];
  /** Classes for the element wrapping the icon and text. */
  contentClasses?: EuiButtonGroupButtonSignature['Args']['contentClasses'];
  /** Extra classes for the icon. */
  iconClasses?: EuiButtonGroupButtonSignature['Args']['iconClasses'];
  /** `type` of the button (multi selection only). */
  type?: EuiButtonGroupButtonSignature['Args']['type'];
  /** Class for the option's button. */
  className?: string;
  /** Accessible label of the option's button. */
  'aria-label'?: string;
}

export interface EuiButtonGroupSignature {
  Element: HTMLFieldSetElement;
  Args: {
    /**
     * `'s'`, `'m'`, or `'compressed'` (for forms, e.g. inside an
     * `EuiFormRow` with `@display="rowCompressed"`). Defaults to `'s'`.
     */
    buttonSize?: 's' | 'm' | 'compressed';
    /**
     * Color of the selected buttons: `'primary'`, `'text'`, `'ghost'`,
     * `'success'`, `'warning'` or `'danger'`. Defaults to `'text'`.
     */
    color?: 'primary' | 'text' | 'ghost' | 'success' | 'warning' | 'danger';
    /** Stretches the group, and its buttons evenly, to its container's width. */
    isFullWidth?: boolean;
    /** Disables every option. */
    isDisabled?: boolean;
    /**
     * `'single'`: one option selected at a time, set with `@idSelected`
     * (radio buttons). `'multi'`: each option toggles, set with
     * `@idToSelectedMap`. Defaults to `'single'`.
     */
    type?: 'single' | 'multi';
    /**
     * Describes the group for screen readers (visually hidden legend).
     * Required for accessibility.
     */
    legend?: string;
    /** `name` of the radio inputs (single selection). Defaults to a random id. */
    name?: string;
    /** Extra class(es) for the fieldset. */
    className?: string;
    /** Shows only the options' icons; their labels stay for screen readers. */
    isIconOnly?: EuiButtonGroupButtonSignature['Args']['isIconOnly'];
    /**
     * Called with the clicked option's `id` (and its `value` for `'single'`).
     * Update `@idSelected` / `@idToSelectedMap` here.
     */
    onChange: EuiButtonGroupButtonSignature['Args']['onChange'];
    /** Id of the selected option (`@type="single"`). */
    idSelected?: Option['id'];
    /**
     * Selected state by option id, e.g. `{ bold: true, italic: false }`
     * (`@type="multi"`).
     */
    idToSelectedMap?: {
      [key: string]: EuiButtonGroupButtonSignature['Args']['isSelected'];
    };
    /** The buttons: `[{ id: 'left', label: 'Left', iconType: 'editorAlignLeft' }]`. */
    options?: Array<Option>;
  };
}

export const EuiButtonGroup: TemplateOnlyComponent<EuiButtonGroupSignature> =
  <template>
    {{#let
      (argOrDefault @buttonSize "s")
      (argOrDefault @color "text")
      (argOrDefault @isFullWidth false)
      (argOrDefault @isDisabled false)
      (argOrDefault @type "single")
      as |buttonSize color isFullWidth isDisabled type|
    }}
      {{#let
        (if (and (eq buttonSize "compressed") (eq color "ghost")) "text" color)
        (eq type "single")
        as |resolvedColor typeIsSingle|
      }}

        <fieldset
          class={{classNames
            "euiButtonGroup"
            (if isFullWidth "euiButtonGroup--fullWidth")
            (if isDisabled "euiButtonGroup--isDisabled")
            @className
            componentName="EuiButtonGroup"
            size=(argOrDefault buttonSize "s")
            color=resolvedColor
          }}
          disabled={{isDisabled}}
          ...attributes
        >
          <legend {{screenReaderOnly}}>{{@legend}}</legend>
          <div class="euiButtonGroup__buttons">
            {{#let (argOrDefault @name (randomId)) as |name|}}
              {{#each @options as |option|}}
                <EuiButtonGroupButton
                  @name={{name}}
                  @isDisabled={{if
                    (notEq option.isDisabled undefined)
                    option.isDisabled
                    isDisabled
                  }}
                  @element={{if typeIsSingle "label" "button"}}
                  @isSelected={{if
                    typeIsSingle
                    (eq option.id @idSelected)
                    (get @idToSelectedMap option.id)
                  }}
                  @color={{resolvedColor}}
                  @size={{buttonSize}}
                  @isIconOnly={{@isIconOnly}}
                  @onChange={{@onChange}}
                  @iconType={{option.iconType}}
                  @value={{option.value}}
                  @label={{option.label}}
                  @id={{option.id}}
                  @isLoading={{option.isLoading}}
                  @iconSide={{option.iconSide}}
                  @iconSize={{option.iconSize}}
                  @textClasses={{option.textClasses}}
                  @contentClasses={{option.contentClasses}}
                  @iconClasses={{option.iconClasses}}
                  @type={{option.type}}
                  class={{option.className}}
                  aria-label={{option.aria-label}}
                />
              {{/each}}
            {{/let}}
          </div>
        </fieldset>
      {{/let}}
    {{/let}}
  </template>;

export default EuiButtonGroup;
