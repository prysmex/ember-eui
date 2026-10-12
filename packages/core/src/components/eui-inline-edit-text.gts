import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import {
  euiInlineEditTextStyles,
  euiTextTruncate
} from '../utils/eui/styles.generated.ts';
import { useEuiBorealisStyles } from '../utils/eui/styles.ts';
import EuiInlineEditForm, {
  MEDIUM_SIZE_FORM,
  SMALL_SIZE_FORM
} from './eui-inline-edit/eui-inline-edit-form.gts';
import EuiText from './eui-text.gts';

import type { EuiInlineEditCommonArgs } from './eui-inline-edit/eui-inline-edit-form';

/** `eui-textTruncate` utility (no global utility classes are injected). */
const TRUNCATE = euiTextTruncate();

export interface EuiInlineEditTextSignature {
  Element: HTMLDivElement;
  Args: EuiInlineEditCommonArgs & {
    /** Text size: `'xs'`, `'s'` or `'m'`. Defaults to `'m'`. */
    size?: 'xs' | 's' | 'm';
  };
}

/**
 * Text that turns into a text field when clicked (upstream
 * `EuiInlineEditText`): read mode is a button showing the text, edit mode
 * an `EuiFieldText` with save and cancel buttons. Enter saves, Escape
 * cancels.
 */
export default class EuiInlineEditText extends Component<EuiInlineEditTextSignature> {
  get size() {
    return this.args.size ?? 'm';
  }
  get sizes() {
    return this.size === 'xs' || this.size === 's'
      ? SMALL_SIZE_FORM
      : MEDIUM_SIZE_FORM;
  }
  get readModeRole() {
    return this.args.isReadOnly ? 'paragraph' : undefined;
  }

  @cached
  get rootCss() {
    const styles = useEuiBorealisStyles(
      getEuiThemeContext(this),
      euiInlineEditTextStyles
    );
    return [styles.euiInlineEditText, styles.fontSize[this.size]];
  }

  truncate = TRUNCATE;

  <template>
    <EuiInlineEditForm
      @className="euiInlineEditText"
      @rootCss={{this.rootCss}}
      @sizes={{this.sizes}}
      @readModeRole={{this.readModeRole}}
      @placeholder={{@placeholder}}
      @onSave={{@onSave}}
      @inputAriaLabel={{@inputAriaLabel}}
      @startWithEditOpen={{@startWithEditOpen}}
      @defaultValue={{@defaultValue}}
      @value={{@value}}
      @onChange={{@onChange}}
      @onCancel={{@onCancel}}
      @isLoading={{@isLoading}}
      @isInvalid={{@isInvalid}}
      @isReadOnly={{@isReadOnly}}
      @readModeProps={{@readModeProps}}
      @editModeProps={{@editModeProps}}
      @css={{@css}}
      ...attributes
      as |value|
    >
      <EuiText
        @size={{this.size}}
        @css={{this.truncate}}
        class="eui-textTruncate"
      >{{value}}</EuiText>
    </EuiInlineEditForm>
  </template>
}
