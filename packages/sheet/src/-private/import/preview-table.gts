/**
 * The import screen's preview (v0.4 10): a read-only table of the first
 * lines (`previewImport`) with the target fields as columns. Each cell is
 * the value as its type formats it, or its state: an error (the type's
 * or the transform's message), "linked on import", "new option".
 */
import Component from '@glimmer/component';

import EuiBadge from '@ember-eui/core/components/eui-badge';

import { importFieldId } from '../../core/index.ts';

import type {
  SheetImportCell,
  SheetImportPreview,
  SheetMessages
} from '../../core/index.ts';

interface ImportPreviewTableSignature {
  Args: {
    preview: SheetImportPreview;
    caption: string;
    messages: SheetMessages;
  };
}

interface CellView {
  kind: SheetImportCell['state'];
  text: string;
  message?: string;
}

export default class ImportPreviewTable extends Component<ImportPreviewTableSignature> {
  get headers(): Array<{ label: string; isNew: boolean }> {
    const { fields, columns } = this.args.preview;
    return fields.map((field, k) => ({
      label: field.label ?? field.id,
      isNew: field.id === importFieldId(columns[k]!)
    }));
  }

  get rows(): Array<{ line: number; cells: CellView[] }> {
    const { lines, cells } = this.args.preview;
    return lines.map((line, i) => ({
      // the file's line number, the header line being 1
      line: line + 1,
      cells: cells[i]!.map((cell): CellView => {
        if (cell.state === 'error') {
          return { kind: 'error', text: cell.text, message: cell.message };
        }
        if (cell.state === 'linked') return { kind: 'linked', text: cell.text };
        return { kind: cell.state, text: cell.display };
      })
    }));
  }

  isState = (cell: CellView, state: string): boolean => cell.kind === state;

  <template>
    <div class="euiSheetImport__scroll">
      <table
        class="euiSheetImport__table euiSheetImport__preview"
        data-test-subj="euiSheetImportPreviewTable"
      >
        <caption>{{@caption}}</caption>
        <thead>
          <tr>
            <th scope="col" class="euiSheetImport__line">
              {{@messages.importLine}}
            </th>
            {{#each this.headers as |header|}}
              <th scope="col" data-test-subj="euiSheetImportPreviewHeader">
                {{header.label}}
                {{#if header.isNew}}
                  <EuiBadge
                    @color="primary"
                    class="euiSheetImport__cellBadge"
                  >{{@messages.importNew}}</EuiBadge>
                {{/if}}
              </th>
            {{/each}}
          </tr>
        </thead>
        <tbody>
          {{#each this.rows as |row|}}
            <tr data-test-subj="euiSheetImportPreviewRow">
              <td class="euiSheetImport__line">{{row.line}}</td>
              {{#each row.cells as |cell|}}
                {{#if (this.isState cell "error")}}
                  <td
                    class="euiSheetImport__cell--error"
                    title={{cell.message}}
                    data-test-subj="euiSheetImportPreviewCell"
                    data-state="error"
                  >
                    {{cell.text}}
                    <span class="euiSheetImport__cellMessage">
                      {{cell.message}}
                    </span>
                  </td>
                {{else}}
                  <td
                    title={{cell.text}}
                    data-test-subj="euiSheetImportPreviewCell"
                    data-state={{cell.kind}}
                  >
                    {{cell.text}}
                    {{#if (this.isState cell "linked")}}
                      <EuiBadge
                        @color="hollow"
                        class="euiSheetImport__cellBadge"
                      >{{@messages.importLinkedOnImport}}</EuiBadge>
                    {{else if (this.isState cell "newOption")}}
                      <EuiBadge
                        @color="accent"
                        class="euiSheetImport__cellBadge"
                      >{{@messages.importNewOption}}</EuiBadge>
                    {{/if}}
                  </td>
                {{/if}}
              {{/each}}
            </tr>
          {{/each}}
        </tbody>
      </table>
    </div>
  </template>
}
