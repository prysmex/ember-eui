import { on } from '@ember/modifier';

import { element } from 'ember-element-helper';

import EuiIcon from './eui-icon.gts';

import type { EuiIconSignature } from './eui-icon';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

const TINTS = [
  'tint0',
  'tint1',
  'tint2',
  'tint3',
  'tint4',
  'tint5',
  'tint6',
  'tint7',
  'tint8',
  'tint9',
  'tint10'
];

export interface EuiSuggestItemType {
  /** Icon of the suggestion's type, e.g. `'kqlField'` or `'search'`. */
  iconType: EuiIconSignature['Args']['type'];
  /** `'tint0'` to `'tint10'`, the color behind the icon. */
  color?: string;
}

/**
 * One suggestion of an `EuiSuggest`: a colored type icon, a label and an
 * optional description. With `@onClick` it is a button.
 */
export interface EuiSuggestItemSignature {
  Element: HTMLButtonElement | HTMLDivElement;
  Args: {
    /** The suggestion's type: its icon and color. */
    type: EuiSuggestItemType;
    /** The suggestion. */
    label: string;
    /** More about it, after the label. */
    description?: string;
    /**
     * `'fixed'` keeps the label at `@labelWidth`; `'expand'` lets it take
     * the space it needs. Defaults to `'fixed'` (`'expand'` without a
     * description).
     */
    labelDisplay?: 'fixed' | 'expand';
    /** Width of the label in percent, `'20'` to `'90'` by tens. Defaults to `'50'`. */
    labelWidth?: '20' | '30' | '40' | '50' | '60' | '70' | '80' | '90';
    /** `'truncate'` or `'wrap'` a long description. Defaults to `'truncate'`. */
    descriptionDisplay?: 'truncate' | 'wrap';
    /** Makes it a button. */
    onClick?: (event: MouseEvent) => void;
  };
}

function typeClass(type: EuiSuggestItemType): string {
  return type.color && TINTS.includes(type.color)
    ? `euiSuggestItem__type euiSuggestItem__type--${type.color}`
    : 'euiSuggestItem__type';
}

function labelClass(labelDisplay = 'fixed', labelWidth = '50', description?: string): string {
  const display = description ? labelDisplay : 'expand';

  return [
    'euiSuggestItem__label',
    `euiSuggestItem__labelDisplay--${display}`,
    labelDisplay === 'fixed' && `euiSuggestItem__label--width${labelWidth}`
  ]
    .filter(Boolean)
    .join(' ');
}

function noop(): void {}

const EuiSuggestItem: TemplateOnlyComponent<EuiSuggestItemSignature> = <template>
  {{#let (element (if @onClick "button" "div")) as |Tag|}}
    <Tag
      class="euiSuggestItem {{if @onClick 'euiSuggestItem-isClickable'}}"
      type={{if @onClick "button"}}
      {{on "click" (if @onClick @onClick noop)}}
      ...attributes
    >
      <span class={{typeClass @type}}>
        <EuiIcon @type={{@type.iconType}} @color="inherit" />
      </span>
      <span class={{labelClass @labelDisplay @labelWidth @description}}>{{@label}}</span>
      {{#if @description}}
        <span
          class="euiSuggestItem__description euiSuggestItem__description--{{if
            @descriptionDisplay
            @descriptionDisplay
            'truncate'
          }}"
        >{{@description}}</span>
      {{/if}}
    </Tag>
  {{/let}}
</template>;

export default EuiSuggestItem;
