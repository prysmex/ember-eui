/**
 * One row of the import screen's columns table (v0.4 10, "The screen"):
 * the file column's header and three sample texts, its type (the guess,
 * or how much of it the target field reads), its target (a field, "New
 * field...", "Skip"), its transform, the built-in options that apply, and
 * its status. Under it, when opened, the new field's form or the value
 * map. The screen holds the state; the row calls its actions.
 */
import Component from '@glimmer/component';
import { on } from '@ember/modifier';
import { guidFor } from '@ember/object/internals';
import { schedule } from '@ember/runloop';

import EuiBadge from '@ember-eui/core/components/eui-badge';
import EuiButtonEmpty from '@ember-eui/core/components/eui-button-empty';
import EuiLink from '@ember-eui/core/components/eui-link';
import EuiSelect from '@ember-eui/core/components/eui-select';
import EuiSwitch from '@ember-eui/core/components/eui-switch';

import { countText } from './model.ts';
import ImportNewFieldForm from './new-field-form.gts';
import ImportValueMap from './value-map.gts';

import type EuiSheetImport from '../../components/eui-sheet-import.gts';
import type { ImportColumnView } from '../../components/eui-sheet-import.gts';
import type {
  SheetFieldDraft,
  SheetImportTransform,
  SheetMessages
} from '../../core/index.ts';

interface ImportColumnRowSignature {
  Args: {
    view: ImportColumnView;
    screen: EuiSheetImport;
    transforms: SheetImportTransform[];
    messages: SheetMessages;
  };
}

export default class ImportColumnRow extends Component<ImportColumnRowSignature> {
  id = guidFor(this);

  get view(): ImportColumnView {
    return this.args.view;
  }

  get messages(): SheetMessages {
    return this.args.messages;
  }

  get valuesText(): string {
    const n = this.args.view.valueMap?.mapped ?? 0;
    const { importValuesOne, importValues } = this.messages;
    return countText(n, importValuesOne, importValues, n);
  }

  get cantReadText(): string {
    const n = this.args.view.status?.errors ?? 0;
    const { importCantReadOne, importCantRead } = this.messages;
    return countText(n, importCantReadOne, importCantRead, n);
  }

  get readText(): string {
    const { read = 0, total = 0 } = this.args.view.status ?? {};
    const { importReadOne, importRead } = this.messages;
    return countText(total, importReadOne, importRead, read, total);
  }

  get busy(): boolean {
    return this.args.screen.busy;
  }

  get colspan(): number {
    return this.args.transforms.length ? 6 : 5;
  }

  get transformOptions(): Array<{ value: string; text: string }> {
    return [
      { value: '', text: this.messages.importNoTransform() },
      ...this.args.transforms.map((t) => ({ value: t.id, text: t.label }))
    ];
  }

  get transformTitle(): string | undefined {
    const id = this.view.transformValue;
    return this.args.transforms.find((t) => t.id === id)?.description;
  }

  get dateOrderOptions(): Array<{ value: string; text: string }> {
    return [
      { value: 'dmy', text: this.messages.dateOrderDmy() },
      { value: 'mdy', text: this.messages.dateOrderMdy() }
    ];
  }

  get decimalOptions(): Array<{ value: string; text: string }> {
    return [
      { value: '.', text: this.messages.importDecimalPoint() },
      { value: ',', text: this.messages.importDecimalComma() }
    ];
  }

  get trim(): boolean {
    return this.view.column.trim !== false;
  }

  get emptyIsNull(): boolean {
    return this.view.column.emptyIsNull !== false;
  }

  get filtered(): boolean {
    return this.args.screen.filterColumn === this.view.index;
  }

  /** Focuses one of this row's controls after the next render (a closed form gives focus back). */
  focusLater(selector: string): void {
    schedule('afterRender', () => {
      document.querySelector<HTMLElement>(selector)?.focus();
    });
  }

  onTarget = (event: Event): void => {
    this.args.screen.setTarget(
      this.view.index,
      (event.target as HTMLSelectElement).value
    );
  };

  onTransform = (event: Event): void => {
    this.args.screen.setTransform(
      this.view.index,
      (event.target as HTMLSelectElement).value
    );
  };

  onDateOrder = (event: Event): void => {
    this.args.screen.setDateOrder(
      this.view.index,
      (event.target as HTMLSelectElement).value as 'dmy' | 'mdy'
    );
  };

  onDecimal = (event: Event): void => {
    this.args.screen.setDecimalSeparator(
      this.view.index,
      (event.target as HTMLSelectElement).value as '.' | ','
    );
  };

  toggleTrim = (): void => this.args.screen.toggleTrim(this.view.index);

  toggleEmptyIsNull = (): void =>
    this.args.screen.toggleEmptyIsNull(this.view.index);

  toggleForm = (): void => this.args.screen.toggleForm(this.view.index);

  toggleValues = (): void => this.args.screen.toggleValues(this.view.index);

  showErrors = (): void => this.args.screen.showErrors(this.view.index);

  saveDraft = (draft: SheetFieldDraft): void => {
    this.args.screen.saveDraft(this.view.index, draft);
    this.focusLater(`#${this.id}-edit`);
  };

  closeForm = (): void => {
    this.args.screen.toggleForm(this.view.index);
    this.focusLater(`#${this.id}-edit`);
  };

  setValue = (text: string, mapped: unknown): void =>
    this.args.screen.setValue(this.view.index, text, mapped);

  <template>
    <tr
      data-test-subj="euiSheetImportColumn"
      data-column={{@view.index}}
      data-target={{@view.targetValue}}
    >
      <th scope="row" class="euiSheetImport__colFile">
        <div
          class="euiSheetImport__header"
          data-test-subj="euiSheetImportHeader"
        >
          {{@view.name}}
        </div>
        {{#each @view.samples as |sample|}}
          <span
            class="euiSheetImport__sample"
            title={{sample}}
            data-test-subj="euiSheetImportSample"
          >{{sample}}</span>
        {{/each}}
      </th>
      <td>
        {{#if @view.badge}}
          <EuiBadge
            @color={{@view.badge.color}}
            title={{@view.badge.title}}
            data-test-subj="euiSheetImportGuess"
          >{{@view.badge.text}}</EuiBadge>
        {{/if}}
      </td>
      <td>
        <div class="euiSheetImport__stack">
          <EuiSelect
            @compressed={{true}}
            @options={{@view.targetOptions}}
            @value={{@view.targetValue}}
            @disabled={{this.busy}}
            aria-label={{this.messages.importTargetFor @view.name}}
            data-test-subj="euiSheetImportTarget"
            {{on "change" this.onTarget}}
          />
          {{#if @view.newFieldText}}
            <span
              class="euiSheetImport__note"
              data-test-subj="euiSheetImportNewFieldText"
            >{{@view.newFieldText}}</span>
            <EuiButtonEmpty
              @size="xs"
              @iconType="pencil"
              @flush="left"
              @isDisabled={{this.busy}}
              id="{{this.id}}-edit"
              aria-expanded={{if @view.formOpen "true" "false"}}
              aria-controls="{{this.id}}-form"
              data-test-subj="euiSheetImportEditNewField"
              {{on "click" this.toggleForm}}
            >{{this.messages.importEditNewField}}</EuiButtonEmpty>
          {{/if}}
          {{#if @view.takenNote}}
            <span
              class="euiSheetImport__note"
              data-test-subj="euiSheetImportTaken"
            >{{@view.takenNote}}</span>
          {{/if}}
        </div>
      </td>
      {{#if @transforms.length}}
        <td>
          {{#if @view.showTransform}}
            <EuiSelect
              @compressed={{true}}
              @options={{this.transformOptions}}
              @value={{@view.transformValue}}
              @disabled={{this.busy}}
              aria-label={{this.messages.importTransformFor @view.name}}
              title={{this.transformTitle}}
              data-test-subj="euiSheetImportTransform"
              {{on "change" this.onTransform}}
            />
          {{/if}}
        </td>
      {{/if}}
      <td>
        {{#unless @view.isSkip}}
          <div class="euiSheetImport__stack">
            <EuiSwitch
              @compressed={{true}}
              @label={{(this.messages.importTrim)}}
              @checked={{this.trim}}
              @disabled={{this.busy}}
              @onChange={{this.toggleTrim}}
              data-test-subj="euiSheetImportTrim"
            />
            <EuiSwitch
              @compressed={{true}}
              @label={{(this.messages.importEmptyIsNull)}}
              @checked={{this.emptyIsNull}}
              @disabled={{this.busy}}
              @onChange={{this.toggleEmptyIsNull}}
              data-test-subj="euiSheetImportEmptyIsNull"
            />
            {{#if @view.dateOrder}}
              <label for="{{this.id}}-date" class="euiSheetImport__note">
                {{this.messages.fieldDateOrder}}
              </label>
              <EuiSelect
                @compressed={{true}}
                @options={{this.dateOrderOptions}}
                @value={{@view.dateOrder}}
                @disabled={{this.busy}}
                id="{{this.id}}-date"
                data-test-subj="euiSheetImportDateOrder"
                {{on "change" this.onDateOrder}}
              />
            {{/if}}
            {{#if @view.decimalSeparator}}
              <label for="{{this.id}}-decimal" class="euiSheetImport__note">
                {{this.messages.importDecimalSeparator}}
              </label>
              <EuiSelect
                @compressed={{true}}
                @options={{this.decimalOptions}}
                @value={{@view.decimalSeparator}}
                @disabled={{this.busy}}
                id="{{this.id}}-decimal"
                data-test-subj="euiSheetImportDecimal"
                {{on "change" this.onDecimal}}
              />
            {{/if}}
            {{#if @view.valueMap}}
              <EuiButtonEmpty
                @size="xs"
                @iconType={{if @view.valuesOpen "arrowDown" "arrowRight"}}
                @flush="left"
                @isDisabled={{this.busy}}
                aria-expanded={{if @view.valuesOpen "true" "false"}}
                aria-controls="{{this.id}}-values"
                data-test-subj="euiSheetImportValuesToggle"
                {{on "click" this.toggleValues}}
              >{{this.valuesText}}</EuiButtonEmpty>
            {{/if}}
          </div>
        {{/unless}}
      </td>
      <td>
        {{#if @view.status}}
          {{#if @view.status.errors}}
            <EuiLink
              @color="danger"
              aria-pressed={{if this.filtered "true" "false"}}
              data-test-subj="euiSheetImportCantRead"
              {{on "click" this.showErrors}}
            >{{this.cantReadText}}</EuiLink>
          {{else}}
            <span data-test-subj="euiSheetImportRead">
              {{this.readText}}
            </span>
          {{/if}}
        {{/if}}
      </td>
    </tr>
    {{#if @view.formOpen}}
      {{#if @view.newField}}
        <tr class="euiSheetImport__detail" id="{{this.id}}-form">
          <td colspan={{this.colspan}}>
            <ImportNewFieldForm
              @draft={{@view.newField}}
              @types={{@screen.editorTypes}}
              @messages={{@messages}}
              @themeClass={{@screen.themeClass}}
              @onSave={{this.saveDraft}}
              @onCancel={{this.closeForm}}
            />
          </td>
        </tr>
      {{/if}}
    {{/if}}
    {{#if @view.valuesOpen}}
      {{#if @view.valueMap}}
        <tr class="euiSheetImport__detail" id="{{this.id}}-values">
          <td colspan={{this.colspan}}>
            <ImportValueMap
              @name={{@view.name}}
              @texts={{@view.valueMap.texts}}
              @choices={{@view.valueMap.choices}}
              @map={{@view.valueMap.map}}
              @disabled={{this.busy}}
              @messages={{@messages}}
              @onChange={{this.setValue}}
            />
          </td>
        </tr>
      {{/if}}
    {{/if}}
  </template>
}
