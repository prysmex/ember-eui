import { eq } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import EuiIcon from './eui-icon.gts';
import EuiLoadingSpinner from './eui-loading-spinner.gts';

import type { EuiIconSignature } from './eui-icon';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiButtonContentSignature {
  Element: HTMLSpanElement;
  Args: {
    /** `'right'` puts the icon after the text. Defaults to the left side. */
    iconSide?: 'right';
    /** Replaces the icon with a loading spinner. */
    isLoading?: boolean;
    /** Icon before (or after) the text; anything `EuiIcon`'s `@type` accepts. */
    iconType?: EuiIconSignature['Args']['type'];
    /** Size of the icon (and spinner). Defaults to `'m'`. */
    iconSize?: EuiIconSignature['Args']['size'];
    /** Extra classes for the icon. */
    iconClasses?: string;
    /** @deprecated Has no effect, see `EuiIcon`. */
    useSvg?: boolean;
    /** @deprecated Not needed: a component passed as `@iconType` is rendered. */
    useComponent?: boolean;
    /** Classes for the element wrapping the text. */
    textClasses?: string;
  };
  Blocks: {
    /** The button's text. */
    default: [];
  };
}

const EuiButtonContent: TemplateOnlyComponent<EuiButtonContentSignature> =
  <template>
    <span
      class={{classNames
        "euiButtonContent"
        (if (eq @iconSide "right") "euiButtonContent--iconRight")
      }}
      ...attributes
    >
      {{#if @isLoading}}
        <EuiLoadingSpinner
          class="euiButtonContent__spinner"
          {{!@glint-expect-error}}
          @size={{argOrDefault @iconSize "m"}}
        />
      {{else if @iconType}}
        <EuiIcon
          @iconClasses="euiButtonContent__icon {{@iconClasses}}"
          @type={{@iconType}}
          @size={{argOrDefault @iconSize "m"}}
          @useSvg={{@useSvg}}
          @useComponent={{@useComponent}}
          @color="inherit"
        />
      {{/if}}
      <span class={{@textClasses}}>
        {{yield}}
      </span>
    </span>
  </template>;

export default EuiButtonContent;
