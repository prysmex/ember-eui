import Component from '@glimmer/component';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { service } from '@ember/service';

import EuiFieldSearch from '../eui-field-search.gts';
import EuiInputPopover from '../eui-input-popover.gts';

import type EuiI18n from '../../services/eui-i18n';
import type { EuiPopoverArgs } from '../eui-popover';

/** Options of the search field (upstream's `box` prop). */
export interface EuiSearchBoxOptions {
  /** Placeholder. Defaults to "Search...". */
  placeholder?: string;
  /** Searches as you type instead of on Enter. */
  incremental?: boolean;
  /** Shows the clear button while there is text. Defaults to `true`. */
  isClearable?: boolean;
  /** Shows a spinner in the field. */
  isLoading?: boolean;
  /** Disables the field. */
  disabled?: boolean;
  /** Makes the field read-only. */
  readOnly?: boolean;
  /** Stretches the field. Defaults to `true` (upstream). */
  fullWidth?: boolean;
  /** Shorter field. */
  compressed?: boolean;
  /** Id of the `<input>`. */
  id?: string;
  /** Name of the `<input>`. */
  name?: string;
  /** Overrides the default instructions read by screen readers. */
  'aria-label'?: string;
  /** Ids of elements describing the field. */
  'aria-describedby'?: string;
  /** `data-test-subj` of the `<input>`. */
  'data-test-subj'?: string;
  /**
   * The query schema (`{ strict, fields, flags, recognizedFields }`).
   * `EuiInMemoryTable` also accepts `true` to derive it from its columns.
   */
  schema?: unknown;
}

/** Popover options of the search bar's hint (upstream `hint.popoverProps`). */
export type EuiSearchBoxHintPopoverProps = Partial<
  Pick<
    EuiPopoverArgs,
    | 'isOpen'
    | 'closePopover'
    | 'panelClassName'
    | 'panelPaddingSize'
    | 'panelStyle'
    | 'popoverScreenReaderText'
    | 'repositionOnScroll'
  > & { fullWidth?: boolean; disableFocusTrap?: boolean }
>;

/** @private Upstream `hint` of EuiSearchBox (wired by EuiSearchBar). */
export interface EuiSearchBoxHint {
  id: string;
  isVisible: boolean;
  setIsVisible: (isVisible: boolean) => void;
  popoverProps?: EuiSearchBoxHintPopoverProps;
}

/**
 * @private The search field of `EuiSearchBar` and the plain-text search of
 * `EuiInMemoryTable` (upstream `EuiSearchBox`): an `EuiFieldSearch` showing
 * `@query`, optionally with a hint popover below it.
 */
export interface EuiSearchBoxSignature {
  Element: HTMLInputElement;
  Args: {
    /** The text shown; the field is reset to it whenever it changes. */
    query: string;
    /** Called with the text on Enter (or as you type when incremental). */
    onSearch: (queryText: string) => void;
    /** The field options. */
    box?: EuiSearchBoxOptions;
    /** Shorter field (overridden by `@box.compressed`). */
    compressed?: boolean;
    /** Shows the invalid state. */
    isInvalid?: boolean;
    /** Ids describing the field (overrides `@box['aria-describedby']`). */
    ariaDescribedBy?: string;
    /** Hint shown below the field while it has focus. */
    hint?: EuiSearchBoxHint;
  };
  Blocks: {
    /** The hint's content. */
    hint: [];
  };
}

export default class EuiSearchBox extends Component<EuiSearchBoxSignature> {
  @service declare euiI18n: EuiI18n;

  get box(): EuiSearchBoxOptions {
    return this.args.box ?? {};
  }

  get placeholder(): string {
    return (
      this.box.placeholder ??
      this.euiI18n.lookupToken('euiSearchBox.placeholder', 'Search...')
    );
  }

  get ariaLabel(): string {
    if (this.box['aria-label']) return this.box['aria-label'];
    return this.box.incremental
      ? this.euiI18n.lookupToken(
          'euiSearchBox.incrementalAriaLabel',
          'This is a search bar. As you type, the results lower in the page will automatically filter.'
        )
      : this.euiI18n.lookupToken(
          'euiSearchBox.ariaLabel',
          'This is a search bar. After typing your query, hit enter to filter the results lower in the page.'
        );
  }

  get compressed(): boolean | undefined {
    return this.box.compressed ?? this.args.compressed;
  }

  get testSubj(): string | undefined {
    return this.box['data-test-subj'];
  }

  get describedBy(): string | undefined {
    return this.args.ariaDescribedBy ?? this.box['aria-describedby'];
  }

  @action
  onFocus(): void {
    this.args.hint?.setIsVisible(true);
  }

  @action
  closeHint(): void {
    const { hint } = this.args;
    if (!hint) return;
    if (hint.popoverProps?.closePopover) hint.popoverProps.closePopover();
    else hint.setIsVisible(false);
  }

  <template>
    {{#if @hint}}
      <EuiInputPopover
        @isOpen={{@hint.isVisible}}
        @closePopover={{this.closeHint}}
        @fullWidth={{if (isFalse @hint.popoverProps.fullWidth) false true}}
        @disableFocusTrap={{if
          (isFalse @hint.popoverProps.disableFocusTrap)
          false
          true
        }}
        @panelPaddingSize={{@hint.popoverProps.panelPaddingSize}}
        @panelClassName={{@hint.popoverProps.panelClassName}}
        @panelStyle={{@hint.popoverProps.panelStyle}}
        @popoverScreenReaderText={{@hint.popoverProps.popoverScreenReaderText}}
        @repositionOnScroll={{@hint.popoverProps.repositionOnScroll}}
      >
        <:input>
          <EuiFieldSearch
            @value={{@query}}
            @onSearch={{@onSearch}}
            @incremental={{this.box.incremental}}
            @placeholder={{this.placeholder}}
            @fullWidth={{if (isFalse this.box.fullWidth) false true}}
            @compressed={{this.compressed}}
            @isInvalid={{@isInvalid}}
            @isClearable={{this.box.isClearable}}
            @isLoading={{this.box.isLoading}}
            @disabled={{this.box.disabled}}
            @readOnly={{this.box.readOnly}}
            @id={{this.box.id}}
            name={{this.box.name}}
            aria-label={{this.ariaLabel}}
            aria-describedby={{this.describedBy}}
            data-test-subj={{this.testSubj}}
            {{on "focus" this.onFocus}}
            ...attributes
          />
        </:input>
        <:content>
          <div id={{@hint.id}} tabindex="-1">{{yield to="hint"}}</div>
        </:content>
      </EuiInputPopover>
    {{else}}
      <EuiFieldSearch
        @value={{@query}}
        @onSearch={{@onSearch}}
        @incremental={{this.box.incremental}}
        @placeholder={{this.placeholder}}
        @fullWidth={{if (isFalse this.box.fullWidth) false true}}
        @compressed={{this.compressed}}
        @isInvalid={{@isInvalid}}
        @isClearable={{this.box.isClearable}}
        @isLoading={{this.box.isLoading}}
        @disabled={{this.box.disabled}}
        @readOnly={{this.box.readOnly}}
        @id={{this.box.id}}
        name={{this.box.name}}
        aria-label={{this.ariaLabel}}
        aria-describedby={{this.describedBy}}
        data-test-subj={{this.testSubj}}
        ...attributes
      />
    {{/if}}
  </template>
}

function isFalse(value: unknown): boolean {
  return value === false;
}
