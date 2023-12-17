import { get,hash } from '@ember/helper';

import { and, eq,not, or } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';
import inlineStyles from '../helpers/inline-styles';
import { toInitials } from '../helpers/to-initials';
import simpleStyle from '../modifiers/simple-style';
import EuiIcon from './eui-icon.gts';

import type { sizeMapping, typeMapping } from '../utils/css-mappings/eui-avatar';
import type { EuiIconSignature } from './eui-icon';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiAvatarSignature {
  Element: HTMLDivElement;
  Args: {
    name?: string;
    color?: EuiIconSignature['Args']['color'];
    iconColor?: string;
    iconSize?: EuiIconSignature['Args']['size'];
    iconType?: EuiIconSignature['Args']['type'];
    imageUrl?: string;
    initials?: string;
    isDisabled?: boolean;
    size?: keyof typeof sizeMapping;
    type?: keyof typeof typeMapping;
    initialLength?: 1 | 2;
  };
}

const EuiAvatar: TemplateOnlyComponent<EuiAvatarSignature> = <template>
  {{#let
    (inlineStyles
      componentName="EuiAvatar"
      componentArgs=(hash
        name=@name
        color=@color
        iconColor=@iconColor
        iconSize=@iconSize
        iconType=@iconType
        imageUrl=@imageUrl
        initials=@initials
      )
    )
    as |inlineStyles|
  }}
    <div
      class={{classNames
        (if @isDisabled "euiAvatar-isDisabled")
        (if (eq @color "plain") "euiAvatar--plain")
        componentName="EuiAvatar"
        size=(argOrDefault @size "m")
        type=(argOrDefault @type "user")
      }}
      aria-label={{if @isDisabled undefined @name}}
      title={{@name}}
      role={{if @isDisabled "presentation" "img"}}
      ...attributes
      {{simpleStyle inlineStyles}}
    >
      {{#if (and (not @imageUrl) (not @iconType))}}
        <span aria-hidden="true">
          {{#if @name}}
            {{toInitials @name @initialLength @initials}}
          {{/if}}
        </span>
      {{else if @iconType}}
        <EuiIcon
          @iconClasses="euiAvatar__icon"
          @size={{or @iconSize @size}}
          @type={{@iconType}}
          aria-label={{@name}}
          role={{if @isDisabled "presentation" "img"}}
          @color={{or
            @iconColor
            (if (eq @iconColor null) @iconColor (get inlineStyles "color"))
          }}
        />
      {{/if}}
    </div>
  {{/let}}
</template>;

export default EuiAvatar;
