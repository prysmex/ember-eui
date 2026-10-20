import { action } from '@ember/object';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import didUpdate from '@ember/render-modifiers/modifiers/did-update';
import EuiFormRow from '@ember-eui/core/components/eui-form-row';
import { argOrDefault } from '@ember-eui/core/helpers';

import { not } from 'ember-truth-helpers';

import { LazyComponent } from '../../-private/lazy-component.ts';
import randomId from '../../-private/random-id.ts';
import ValidatedFormFieldBase from './field-base.gts';

import type { FieldBaseSignature } from './field-base.gts';
import type { EuiFormRowSignature } from '@ember-eui/core/components/eui-form-row';
import type EuiMarkdownEditor from '@ember-eui/core/components/eui-markdown-editor';
import type { EuiMarkdownEditorSignature } from '@ember-eui/core/components/eui-markdown-editor';
import type { ComponentLike } from '@glint/template';

/**
 * A validated markdown editor in an EuiFormRow. Takes FieldBase's, EuiFormRow's and
 * the control's args.
 */
export interface FieldMarkdownEditorSignature {
  Element: EuiMarkdownEditorSignature['Element'];
  Args: FieldBaseSignature['Args'] &
    EuiFormRowSignature['Args'] &
    EuiMarkdownEditorSignature['Args'] & {
      /** Classes for the EuiFormRow. */
      rowClasses?: string;
      /** Classes for the control. */
      fieldClasses?: string;
      /** @private Set by ValidatedForm. */
      formId?: string;
      /** Accessible label of the control. */
      ariaLabel?: string;
      /** Focuses the control on render. */
      autofocus?: boolean;
      /** Called with the markdown text. */
      onChange?: (value: string) => void;
      /** Placeholder text. */
      placeholder?: string;
      /**
       * Renders this editor instead of EuiMarkdownEditor (which is then
       * never loaded), with the same args.
       */
      editorComponent?: ComponentLike;
    };
  Blocks: {
    label: [...EuiFormRowSignature['Blocks']['label']];
    helpText: [...EuiFormRowSignature['Blocks']['helpText']];
  };
}

type MarkdownEditorLike = ComponentLike<{
  Element: FieldMarkdownEditorSignature['Element'];
  Args: Record<string, any>;
}>;

// imported on first render without `@editorComponent` (see LazyComponent)
const euiMarkdownEditor = new LazyComponent<typeof EuiMarkdownEditor>(
  () => import('@ember-eui/core/components/eui-markdown-editor')
);

export default class ValidatedFormFieldMarkdownEditor extends ValidatedFormFieldBase<FieldMarkdownEditorSignature> {
  @action
  //@ts-expect-error
  handleChange(str: string) {
    this.args.onChange(str);
    this.notifyValidityChange();
  }

  // `@editorComponent` takes any component: it gets the editor's args and
  // attributes, unchecked
  get MarkdownEditor(): MarkdownEditorLike | undefined {
    return (this.args.editorComponent ?? euiMarkdownEditor.component) as
      | MarkdownEditorLike
      | undefined;
  }

  <template>
    {{#let this.MarkdownEditor as |MarkdownEditor|}}
      {{#if MarkdownEditor}}
        {{#let (argOrDefault @id (randomId)) as |theId|}}
          <EuiFormRow
            class={{this.rowClasses}}
            @labelType={{@labelType}}
            @display={{@display}}
            @hasEmptyLabelSpace={{@hasEmptyLabelSpace}}
            @fullWidth={{@fullWidth}}
            @hasChildLabel={{@hasChildLabel}}
            @label={{this.label}}
            @labelAppend={{@labelAppend}}
            @id={{theId}}
            @isInvalid={{this.isInvalidAndTouched}}
            @error={{this.validationErrorMessages}}
            @helpText={{@helpText}}
            @errorClasses={{@errorClasses}}
            @isFakeLabelBlock={{not (has-block "label")}}
            @isFakeHelpTextBlock={{not (has-block "helpText")}}
            {{didInsert this.setValidationMessages}}
            {{didUpdate this.didUpdateValue @validations}}
            {{didUpdate this.didUpdateValue @value}}
          >
            <:label as |label|>
              {{yield label to="label"}}
            </:label>
            <:field>
              <MarkdownEditor
                class={{@fieldClasses}}
                form={{@formId}}
                aria-label={{@ariaLabel}}
                @value={{@value}}
                @isInvalid={{this.isInvalidAndTouched}}
                @disabled={{@disabled}}
                @editorId={{theId}}
                @onChange={{this.handleChange}}
                @ariaDescribedBy={{@ariaDescribedBy}}
                @ariaLabel={{@ariaLabel}}
                @ariaLabelledBy={{@ariaLabelledBy}}
                autofocus={{@autofocus}}
                placeholder={{@placeholder}}
                @onParse={{@onParse}}
                @parsingPluginList={{@parsingPluginList}}
                @uiPlugins={{@uiPlugins}}
                @height={{@height}}
                @maxHeight={{@maxHeight}}
                @autoExpandPreview={{@autoExpandPreview}}
                @initialViewMode={{@initialViewMode}}
                ...attributes
              />
            </:field>
            <:helpText as |helpText|>
              {{yield helpText to="helpText"}}
            </:helpText>
          </EuiFormRow>
        {{/let}}
      {{/if}}
    {{/let}}
  </template>
}
