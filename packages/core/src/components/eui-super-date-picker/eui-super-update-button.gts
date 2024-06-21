import { on } from '@ember/modifier';

import style from 'ember-style-modifier/modifiers/style';
import { or } from 'ember-truth-helpers';

import classNames from '../../helpers/class-names.ts';
import EuiButton from '../eui-button.gts';
import EuiButtonIcon from '../eui-button-icon.gts';

import type { EuiButtonSignature } from '../eui-button';
import type { EuiButtonIconSignature } from '../eui-button-icon';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiSuperUpdateButtonSignature {
  Element: EuiButtonIconSignature['Element'] | EuiButtonSignature['Element'];
  Args: {
    className?: string;
    fill?: boolean;
    iconOnly?: boolean;
    isDisabled?: boolean;
    isLoading?: boolean;
    needsUpdate?: boolean;
    onClick: (e: MouseEvent) => void;
    size?: EuiButtonIconSignature['Args']['size'];
    textClasses?: string;
  };
}

const EuiSuperUpdateButton: TemplateOnlyComponent<EuiSuperUpdateButtonSignature> =
  <template>
    {{#if @iconOnly}}
      <EuiButtonIcon
        class={{classNames "euiSuperUpdateButton" @className}}
        @display={{if @fill "fill"}}
        @color={{if (or @needsUpdate @isLoading) "success" "primary"}}
        @iconType={{if (or @needsUpdate @isLoading) "kqlFunction" "refresh"}}
        @isDisabled={{@isDisabled}}
        @size={{@size}}
        {{style minWidth="0px"}}
        {{on "click" @onClick}}
        ...attributes
      />
    {{else}}
      <EuiButton
        class={{classNames "euiSuperUpdateButton" @className}}
        @fill={{@fill}}
        @textClasses={{@textClasses}}
        @color={{if (or @needsUpdate @isLoading) "success" "primary"}}
        @iconType={{if (or @needsUpdate @isLoading) "kqlFunction" "refresh"}}
        @isDisabled={{@isDisabled}}
        @isLoading={{@isLoading}}
        @size={{@size}}
        {{on "click" @onClick}}
        ...attributes
      >
        {{#if (or @needsUpdate @isLoading)}}
          {{#if @isLoading}}
            Updating
          {{else}}
            Update
          {{/if}}
        {{else}}
          Refresh
        {{/if}}
      </EuiButton>
    {{/if}}
  </template>;

export default EuiSuperUpdateButton;
