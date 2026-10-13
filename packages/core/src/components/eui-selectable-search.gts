import Component from '@glimmer/component';
import { on } from '@ember/modifier';
import { action } from '@ember/object';

import { eq, not } from 'ember-truth-helpers';
import { modifier } from 'ember-modifier';

import { getMatchingOptions } from '../-private/selectable-options.ts';
import EuiFieldSearch from './eui-field-search.gts';
import EuiFormAppend from './eui-form-append.gts';
import EuiFormPrepend from './eui-form-prepend.gts';
import EuiScreenReaderOnly from './eui-screen-reader-only.gts';

import type { TOC as TemplateOnlyComponent } from '@ember/component/template-only';
import type { ComponentLike } from '@glint/template';
import type {
  EuiSelectableOption,
  EuiSelectableOptionMatcher
} from '../-private/selectable-options.ts';

/**
 * The search field of an `EuiSelectable`: filters the options as you type.
 * Usually rendered for you by `EuiSelectable` with `@searchable={{true}}`.
 */
export interface EuiSelectableSearchSignature {
  Element: HTMLInputElement;
  Args: {
    /** The options to filter. */
    options: EuiSelectableOption[];
    /** Called with the matching options and the search. */
    onChange: (matchingOptions: EuiSelectableOption[], searchValue: string) => void;
    /** Placeholder of the field. */
    placeholder?: string;
    /**
     * The search (controlled, upstream: managed by the parent
     * `EuiSelectable`). Changing it updates the field.
     */
    value?: string;
    /** Initial search, when `@value` is not given. */
    defaultValue?: string;
    /** Every option matches (they were already filtered, e.g. by a server). */
    isPreFiltered?: unknown;
    /** Decides which options match the search. */
    optionMatcher?: EuiSelectableOptionMatcher;
    /** `id` of the list, to link the field to it for screen readers. */
    listId?: string;
    /** Smaller field. Defaults to `true` (upstream). */
    compressed?: boolean;
    /** Shows a spinner. */
    isLoading?: boolean;
    /** Shows the clear button when there is text. Defaults to `true`. */
    isClearable?: boolean;
    /** Called with the `<input>` once rendered (upstream `inputRef`). */
    inputRef?: (input: HTMLInputElement) => void;
    /** Called on `keydown` in the field (before EuiSelectable handles it). */
    onKeyDown?: (event: KeyboardEvent) => void;
    /** Called on `click` in the field. */
    onClick?: (event: MouseEvent) => void;
    /** Called when the field gets focus. */
    onFocus?: (event: FocusEvent) => void;
    /** Called when the field loses focus. */
    onBlur?: (event: FocusEvent) => void;
    /** `data-test-subj` of the field. */
    dataTestSubj?: string;
    /** Extra class name(s) of the field (upstream `className`). */
    className?: string;
    /**
     * Content before the field (upstream `prepend`): a string is shown as
     * a label, a component is rendered as is.
     */
    prepend?: string | ComponentLike;
    /**
     * Content after the field (upstream `append`): a string is shown as a
     * label, a component is rendered as is.
     */
    append?: string | ComponentLike;
    /** Called on `keyup` in the field, in the capture phase. */
    onKeyUpCapture?: (event: KeyboardEvent) => void;
    /** Called on `input` in the field, before the search is updated. */
    onInput?: (event: Event) => void;
    /** @private `aria-label` of the field (the placeholder by default). */
    ariaLabel?: string;
    /** @private `aria-activedescendant`: the current option's id. */
    activeDescendant?: string;
    /** @private Id of the screen reader instructions (`aria-describedby`). */
    ariaDescribedby?: string;
    /** @private Screen reader instructions, rendered after the field. */
    instructions?: string;
  };
}

const callWithElement = modifier(
  (element: HTMLInputElement, [callback]: [((input: HTMLInputElement) => void) | undefined]) => {
    callback?.(element);
  }
);

/** `{{on}}` that skips a missing handler. */
const onIf = modifier(
  (element: HTMLElement, [event, handler]: [string, ((event: never) => void) | undefined]) => {
    if (!handler) return;
    const listener = handler as unknown as EventListener;
    element.addEventListener(event, listener);
    return () => element.removeEventListener(event, listener);
  }
);

/** `keyup` in the capture phase (React's `onKeyUpCapture`). */
const onKeyUpCaptureIf = modifier(
  (element: HTMLElement, [handler]: [((event: KeyboardEvent) => void) | undefined]) => {
    if (!handler) return;
    const listener = handler as unknown as EventListener;
    element.addEventListener('keyup', listener, true);
    return () => element.removeEventListener('keyup', listener, true);
  }
);

/** A string `prepend` / `append` is a label (upstream), else a component. */
const SideContent = <template>
  {{#if (isString @content)}}
    {{#if (eq @side "prepend")}}
      <EuiFormPrepend @label={{asText @content}} @inputId={{@inputId}} />
    {{else}}
      <EuiFormAppend @label={{asText @content}} @inputId={{@inputId}} />
    {{/if}}
  {{else if @content}}
    {{#let (asComponent @content) as |Content|}}<Content />{{/let}}
  {{/if}}
</template> as TemplateOnlyComponent<{
  Args: { content?: string | ComponentLike; side: 'prepend' | 'append'; inputId?: string };
}>;

function isString(value: unknown): boolean {
  return typeof value === 'string';
}

function asText(value: unknown): string {
  return String(value);
}

function asComponent(value: unknown): ComponentLike {
  return value as ComponentLike;
}

export default class EuiSelectableSearch extends Component<EuiSelectableSearchSignature> {
  lastValue = this.args.value ?? this.args.defaultValue ?? '';

  /** The field's text without `@value`: the initial one. */
  initialValue = this.lastValue;

  /** A controlled `@value` is the field's `@value`; it follows its changes. */
  get fieldValue(): string {
    return this.args.value ?? this.initialValue;
  }

  /** The search as last reported, or as controlled by `@value`. */
  get currentValue(): string {
    return this.args.value ?? this.lastValue;
  }

  @action
  onSearch(value: string): void {
    if (value === this.currentValue) return;

    this.lastValue = value;
    this.args.onChange(
      getMatchingOptions(
        this.args.options,
        value,
        this.args.isPreFiltered,
        this.args.optionMatcher
      ),
      value
    );
  }

  /** Upstream filters on every change (paste, cut, IME), not only keyup. */
  @action
  onInput(event: Event): void {
    this.onSearch((event.target as HTMLInputElement).value);
  }

  <template>
    <EuiFieldSearch
      class="euiSelectableSearch {{@className}}"
      @isFakePrependBlock={{not @prepend}}
      @isFakeAppendBlock={{not @append}}
      @placeholder={{@placeholder}}
      @value={{this.fieldValue}}
      @incremental={{true}}
      @fullWidth={{true}}
      @compressed={{if (isFalse @compressed) false true}}
      @isLoading={{@isLoading}}
      @isClearable={{@isClearable}}
      @onSearch={{this.onSearch}}
      autocomplete="off"
      aria-haspopup="listbox"
      role={{if @listId "combobox"}}
      aria-autocomplete={{if @listId "list"}}
      aria-expanded={{if @listId "true"}}
      aria-controls={{@listId}}
      aria-owns={{@listId}}
      aria-describedby={{@ariaDescribedby}}
      aria-label={{@ariaLabel}}
      aria-activedescendant={{@activeDescendant}}
      data-test-subj={{@dataTestSubj}}
      ...attributes
      {{on "input" this.onInput}}
      {{onIf "keydown" @onKeyDown}}
      {{onIf "click" @onClick}}
      {{onIf "focus" @onFocus}}
      {{onIf "blur" @onBlur}}
      {{onIf "input" @onInput}}
      {{onKeyUpCaptureIf @onKeyUpCapture}}
      {{callWithElement @inputRef}}
    >
      <:prepend as |classes inputId|>
        <SideContent @content={{@prepend}} @side="prepend" @inputId={{inputId}} />
      </:prepend>
      <:append as |classes inputId|>
        <SideContent @content={{@append}} @side="append" @inputId={{inputId}} />
      </:append>
    </EuiFieldSearch>
    {{#if @instructions}}
      <EuiScreenReaderOnly>
        <p id={{@ariaDescribedby}}>{{@instructions}}</p>
      </EuiScreenReaderOnly>
    {{/if}}
  </template>
}

function isFalse(value: unknown): boolean {
  return value === false;
}
