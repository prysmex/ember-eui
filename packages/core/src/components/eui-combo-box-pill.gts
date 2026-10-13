import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { hash } from '@ember/helper';
import { fn } from '@ember/helper';
import { service } from '@ember/service';

import optional from '@nullvoxpopuli/ember-composable-helpers/helpers/optional';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import {
  euiComboBoxPillStyles,
  euiTextTruncate,
  euiFontSize,
  euiFormVariables
} from '../utils/eui/styles.generated.ts';
import {
  comboBoxAppendPrependStyles,
  comboBoxOptionLabel
} from '../utils/eui/combo-box.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import EuiBadge from './eui-badge.gts';
import EuiComboBoxNode from './eui-combo-box/node.gts';

import type EuiI18n from '../services/eui-i18n';
import type { TOC } from '@ember/component/template-only';
import type { EuiCss } from '../utils/eui/styles.ts';
import type { EuiBadgeSignature } from './eui-badge';

/** Upstream `.eui-textTruncate` around the pill text. */
const TEXT_TRUNCATE = euiTextTruncate();

/** Plain text with a prepend/append: lay them out on the text's line. */
const PLAIN_TEXT_SIDES = { display: 'flex', alignItems: 'center' };

const optionNode = (option: unknown, key: 'prepend' | 'append') =>
  option && typeof option === 'object'
    ? (option as Record<string, unknown>)[key]
    : undefined;

const hasSides = (option: unknown) =>
  Boolean(optionNode(option, 'prepend') || optionNode(option, 'append'));

/**
 * Upstream `EuiComboBoxOptionAppendPrepend`: the option's `prepend` and
 * `append` around the text.
 */
const PillContent: TOC<{
  Args: {
    option?: unknown;
    prefix: string;
    prependClass: string;
    appendClass: string;
    textClass?: string;
  };
  Blocks: { default: [] };
}> = <template>{{#let
    (optionNode @option "prepend") (optionNode @option "append")
    as |prepend append|
  }}{{#if prepend}}<span class="{{@prefix}}__prepend {{@prependClass}}"><EuiComboBoxNode
          @node={{prepend}}
          @option={{@option}}
        /></span>{{/if}}{{#if @textClass}}<span
        class="eui-textTruncate {{@textClass}}"
      >{{yield}}</span>{{else}}{{yield}}{{/if}}{{#if append}}<span
        class="{{@prefix}}__append {{@appendClass}}"
      ><EuiComboBoxNode @node={{append}} @option={{@option}} /></span>{{/if}}{{/let}}</template>;

/** A selected option in EuiComboBox's input, as a badge or plain text. */
export interface EuiComboBoxPill {
  Element: EuiBadgeSignature['Element'];
  Args: {
    /** Renders the selection as plain text instead of a badge. */
    asPlainText?: boolean;

    /** Shows an "x" button calling this with `@option`, to remove it. */
    onClose?: (option: unknown) => void;

    /** Badge color, see `EuiBadge`. Defaults to `'hollow'` (upstream). */
    color?: EuiBadgeSignature['Args']['color'];

    /** `data-selected-index` of the remove button, for keyboard navigation. */
    dataSelectedIconIndex?: number;

    /**
     * Accessible label of the remove button. Defaults to "Remove {label}
     * from selection in this group" when the option has a text (a string,
     * or its `@searchField` / `label`).
     */
    iconOnClickAriaLabel?: string;

    /** The selected option this pill shows. */
    option?: unknown;

    /** Key of object options holding their text (EuiComboBox's `@searchField`). */
    searchField?: string;
  };
  Blocks: {
    /** The option's text. */
    default: [];
  };
}

export default class EuiComboBoxPillComponent extends Component<EuiComboBoxPill> {
  @service declare euiI18n: EuiI18n;

  get color(): EuiBadgeSignature['Args']['color'] {
    return this.args.color ?? 'hollow';
  }

  get removeLabel(): string | undefined {
    if (this.args.iconOnClickAriaLabel) return this.args.iconOnClickAriaLabel;

    const label = comboBoxOptionLabel(this.args.option, this.args.searchField);

    if (!label) return undefined;

    return this.euiI18n.lookupToken(
      'euiComboBoxPill.removeSelection',
      'Remove {children} from selection in this group',
      { children: label }
    );
  }

  /**
   * Upstream `euiComboBoxPill`, the `css` EuiComboBoxPill passes to EuiBadge:
   * pill height, line height and a max width that leaves room for the input.
   */
  @cached
  get pillCss(): EuiCss {
    return useEuiBorealisStyles(getEuiThemeContext(this), euiComboBoxPillStyles)
      .euiComboBoxPill;
  }

  /**
   * Plain text single selection: upstream shows it as the input's text, so
   * it uses the form control text (size, color) and truncates.
   */
  @cached
  get plainTextClass(): string {
    const context = getEuiThemeContext(this);
    const form = useEuiBorealisStyles(context, euiFormVariables);

    return euiClass(context, {
      display: 'block',
      minInlineSize: 0,
      maxInlineSize: '100%',
      fontFamily: context.upstream.euiTheme.font.family,
      fontSize: euiFontSize(context.upstream, 's', undefined).fontSize,
      lineHeight: context.upstream.euiTheme.size.l,
      color: form.textColor,
      overflow: 'hidden',
      textOverflow: 'ellipsis',
      whiteSpace: 'nowrap'
    });
  }

  /** Pill prepend/append spacing (upstream `xs`). */
  @cached
  get sideClasses(): { prepend: string; append: string } {
    const context = getEuiThemeContext(this);
    const styles = comboBoxAppendPrependStyles(
      String(context.upstream.euiTheme.size.xs)
    );

    return {
      prepend: euiClass(context, styles.prepend),
      append: euiClass(context, styles.append)
    };
  }

  @cached
  get textClass(): string {
    return euiClass(getEuiThemeContext(this), TEXT_TRUNCATE);
  }

  /** Plain text selection: upstream's `xxs` spacing around the input. */
  @cached
  get plainTextSideClasses(): {
    prepend: string;
    append: string;
    root: string;
  } {
    const context = getEuiThemeContext(this);
    const styles = comboBoxAppendPrependStyles(
      String(context.upstream.euiTheme.size.xxs)
    );

    return {
      prepend: euiClass(context, styles.prepend),
      append: euiClass(context, styles.append),
      root: euiClass(context, PLAIN_TEXT_SIDES)
    };
  }

  <template>
    {{#if @onClose}}
      <EuiBadge
        class="euiComboBoxPill"
        @css={{this.pillCss}}
        data-test-subj="euiComboBoxPill"
        @closeButtonProps={{hash
          tabIndex=-1
          dataSelectedIconIndex=@dataSelectedIconIndex
        }}
        @color={{this.color}}
        @iconOnClick={{fn (optional @onClose) @option}}
        @iconOnClickAriaLabel={{this.removeLabel}}
        @iconSide="right"
        @iconType="cross"
        ...attributes
      >
        <PillContent
          @option={{@option}}
          @prefix="euiComboBoxPill"
          @prependClass={{this.sideClasses.prepend}}
          @appendClass={{this.sideClasses.append}}
          @textClass={{this.textClass}}
        >{{yield}}</PillContent>
      </EuiBadge>
    {{else if @asPlainText}}
      <span
        class="euiComboBoxPill euiComboBoxPill--plainText {{this.plainTextClass}}
          {{if (hasSides @option) this.plainTextSideClasses.root}}"
      >
        <PillContent
          @option={{@option}}
          @prefix="euiComboBoxPlainTextSelection"
          @prependClass={{this.plainTextSideClasses.prepend}}
          @appendClass={{this.plainTextSideClasses.append}}
          @textClass={{if (hasSides @option) this.textClass}}
        >{{yield}}</PillContent>
      </span>
    {{else}}
      <EuiBadge
        class="euiComboBoxPill"
        @css={{this.pillCss}}
        data-test-subj="euiComboBoxPill"
        @color={{this.color}}
        @closeButtonProps={{hash dataSelectedIconIndex=@dataSelectedIconIndex}}
        ...attributes
      >
        <PillContent
          @option={{@option}}
          @prefix="euiComboBoxPill"
          @prependClass={{this.sideClasses.prepend}}
          @appendClass={{this.sideClasses.append}}
          @textClass={{this.textClass}}
        >{{yield}}</PillContent>
      </EuiBadge>
    {{/if}}
  </template>
}
