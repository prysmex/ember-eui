import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import {
  euiInlineEditTitleStyles,
  euiTextTruncate,
  euiTitleStyles
} from '../utils/eui/styles.generated.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import EuiInlineEditForm, {
  MEDIUM_SIZE_FORM,
  SMALL_SIZE_FORM
} from './eui-inline-edit/eui-inline-edit-form.gts';

import type { EuiInlineEditCommonArgs } from './eui-inline-edit/eui-inline-edit-form';

export type EuiInlineEditTitleHeading =
  | 'h1'
  | 'h2'
  | 'h3'
  | 'h4'
  | 'h5'
  | 'h6'
  | 'span';

export interface EuiInlineEditTitleSignature {
  Element: HTMLDivElement;
  Args: EuiInlineEditCommonArgs & {
    /** Title size, as `EuiTitle`'s `@size`. Defaults to `'m'`. */
    size?: 'xxxs' | 'xxs' | 'xs' | 's' | 'm' | 'l';
    /**
     * Heading level of the title. Use `'span'` for text that should only
     * look like a title.
     */
    heading: EuiInlineEditTitleHeading;
  };
}

/**
 * A title that turns into a text field when clicked (upstream
 * `EuiInlineEditTitle`): read mode is a button showing the title in an
 * `@heading` element, edit mode an `EuiFieldText` with save and cancel
 * buttons. Enter saves, Escape cancels.
 */
export default class EuiInlineEditTitle extends Component<EuiInlineEditTitleSignature> {
  get size() {
    return this.args.size ?? 'm';
  }
  get heading(): EuiInlineEditTitleHeading {
    return this.args.heading ?? 'span';
  }
  get sizes() {
    return ['xxxs', 'xxs', 'xs', 's'].includes(this.size)
      ? SMALL_SIZE_FORM
      : MEDIUM_SIZE_FORM;
  }
  get headingLevel() {
    return Number(this.heading.substring(1)) || undefined;
  }
  /** Read-only: the button reads as the heading (or as a paragraph). */
  get readModeRole() {
    if (!this.args.isReadOnly) return undefined;
    return this.headingLevel ? 'heading' : 'paragraph';
  }
  get readModeAriaLevel() {
    return this.args.isReadOnly ? this.headingLevel : undefined;
  }

  @cached
  get rootCss() {
    const styles = useEuiBorealisStyles(
      getEuiThemeContext(this),
      euiInlineEditTitleStyles
    );
    return [styles.euiInlineEditTitle, styles.fontSize[this.size]];
  }

  /**
   * Upstream `EuiTitle` classes cloned onto the heading element (plus the
   * `eui-textTruncate` utility). EuiTitle renders its own element and has no
   * `span`, so its styles are composed here in the same order.
   */
  @cached
  get titleClass() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiTitleStyles);
    return `euiTitle eui-textTruncate ${euiClass(
      context,
      {
        boxSizing: 'border-box',
        margin: 0,
        padding: 0,
        fontFamily: context.upstream.euiTheme.font.family
      },
      styles.euiTitle,
      styles[this.size],
      euiTextTruncate()
    )}`;
  }

  <template>
    <EuiInlineEditForm
      @className="euiInlineEditTitle"
      @rootCss={{this.rootCss}}
      @sizes={{this.sizes}}
      @readModeRole={{this.readModeRole}}
      @readModeAriaLevel={{this.readModeAriaLevel}}
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
      {{#let (element this.heading) as |Heading|}}
        <Heading
          class={{this.titleClass}}
          role={{if @isReadOnly "presentation"}}
        >{{value}}</Heading>
      {{/let}}
    </EuiInlineEditForm>
  </template>
}
