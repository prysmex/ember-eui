import { get,hash } from '@ember/helper';

import { and, eq,not, or } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import inlineStyles from '../helpers/inline-styles.ts';
import { toInitials } from '../helpers/to-initials.ts';
import simpleStyle from '../modifiers/simple-style.ts';
import EuiIcon from './eui-icon.gts';

import type { sizeMapping, typeMapping } from '../utils/css-mappings/eui-avatar.ts';
import type { EuiIconSignature } from './eui-icon';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiAvatarSignature {
  Element: HTMLDivElement;
  Args: {
    /**
     * Full name of the user or space. Used as the accessible label and the
     * hover title, for the initials and to pick a background color.
     */
    name?: string;
    /**
     * Background color as a hex value (`'#DA8B45'`), or `'plain'` for the
     * page's background color. Defaults to one of EUI's visualization colors,
     * picked from `@name`; the text color is chosen for contrast.
     */
    color?: EuiIconSignature['Args']['color'];
    /**
     * Color of the `@iconType` icon, any `EuiIcon` color. Defaults to the
     * text color picked for the background; `null` keeps the icon's own
     * colors (for multi-color logos).
     */
    iconColor?: string;
    /**
     * Size of the `@iconType` icon. Defaults to `@size`.
     */
    iconSize?: EuiIconSignature['Args']['size'];
    /**
     * Shows an icon instead of initials, e.g. `'logoElastic'` for a space.
     * Anything `EuiIcon`'s `@type` accepts.
     */
    iconType?: EuiIconSignature['Args']['type'];
    /**
     * Image shown as the avatar (as a background image), instead of initials.
     */
    imageUrl?: string;
    /**
     * Custom initials (max 2 characters) instead of the ones computed from
     * `@name`. Only shown when `@name` is set.
     */
    initials?: string;
    /**
     * Greys the avatar out and hides it from assistive technology.
     */
    isDisabled?: boolean;
    /**
     * `'s'`, `'m'`, `'l'` or `'xl'`. Defaults to `'m'`.
     */
    size?: keyof typeof sizeMapping;
    /**
     * `'user'` renders a circle, `'space'` a rounded square.
     * Defaults to `'user'`.
     */
    type?: keyof typeof typeMapping;
    /**
     * Number of initials to compute from `@name`, `1` or `2`. Defaults to
     * the number of words in the name, up to 2.
     */
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
