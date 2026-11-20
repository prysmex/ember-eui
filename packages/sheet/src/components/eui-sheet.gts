/**
 * EuiSheet: an Airtable-like data-entry grid on EuiDataGrid's public API
 * (PACKAGE-DESIGN.md 7). Controlled: `@records` in, `@onChange(changeSet)`
 * out. Capture listeners on a wrapper own the keys and clipboard events the
 * sheet handles; arrow navigation stays with the grid; the editor is a
 * sibling of the grid inside the wrapper.
 */
import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { guidFor } from '@ember/object/internals';
import { cancel } from '@ember/runloop';
import { service } from '@ember/service';
import { modifier } from 'ember-modifier';

import EuiDataGrid from '@ember-eui/core/components/eui-data-grid';
import EuiIcon from '@ember-eui/core/components/eui-icon';
import EuiProgress from '@ember-eui/core/components/eui-progress';
import {
  euiClass,
  getEuiThemeContext,
  useEuiBorealisStyles
} from '@ember-eui/core/theming';

import { createMessages } from '../core/index.ts';
import { builtInSheetFieldTypes } from '../field-types.ts';
import FieldEditor from '../-private/field-editor.gts';
import FillHandle from '../-private/fill-handle.gts';
import ImeCatcher from '../-private/ime-catcher.gts';
import EditorFrame from '../-private/editor-frame.gts';
import { RecordFlyout, RecordModal } from '../-private/record-shells.gts';
import RangeOutline from '../-private/range-outline.gts';
import DropLine from '../-private/drop-line.gts';
import RowMenu from '../-private/row-menu.gts';
import ShortcutList from '../-private/shortcut-list.gts';
import {
  RowNumberCell,
  RowNumberHeader
} from '../-private/row-number-cell.gts';
import SheetCell from '../-private/sheet-cell.gts';
import SheetFooterCell, {
  SheetControlFooterCell
} from '../-private/footer-cell.gts';
import { ensureStyles } from '../-private/styles.ts';
import { sheetThemeVars } from '../-private/theme.ts';
import { afterRender } from '../-private/sheet/util.ts';
import SheetFields from '../-private/sheet/fields.ts';
import SheetGridColumns from '../-private/sheet/grid-columns.ts';
import SheetHeaderMenu from '../-private/sheet/header-menu.ts';
import SheetFrozen from '../-private/sheet/frozen.ts';
import SheetGridOptions from '../-private/sheet/grid-options.ts';
import SheetDom from '../-private/sheet/dom.ts';
import SheetRows from '../-private/sheet/rows.ts';
import SheetGroupHeaders from '../-private/sheet/group-headers.ts';
import SheetChecked from '../-private/sheet/checked.ts';
import SheetCells from '../-private/sheet/cells.ts';
import SheetSelection from '../-private/sheet/selection.ts';
import SheetOutline from '../-private/sheet/outline.ts';
import SheetScroll from '../-private/sheet/scroll.ts';
import SheetIme from '../-private/sheet/ime.ts';
import SheetFocus from '../-private/sheet/focus.ts';
import SheetChanges from '../-private/sheet/changes.ts';
import SheetValidate from '../-private/sheet/validate.ts';
import SheetResolve from '../-private/sheet/resolve.ts';
import SheetUploads from '../-private/sheet/uploads.ts';
import SheetHistory from '../-private/sheet/history.ts';
import SheetRecords from '../-private/sheet/records.ts';
import SheetEdit from '../-private/sheet/edit.ts';
import SheetExpanded from '../-private/sheet/expanded.ts';
import SheetFieldEditor from '../-private/sheet/field-editor.ts';
import SheetRowMenu from '../-private/sheet/row-menu.ts';
import SheetFollow from '../-private/sheet/follow.ts';
import SheetDrag from '../-private/sheet/drag.ts';
import SheetTouch from '../-private/sheet/touch.ts';
import SheetClicks from '../-private/sheet/clicks.ts';
import SheetFilling from '../-private/sheet/filling.ts';
import SheetKeys from '../-private/sheet/keys.ts';
import SheetClipboard from '../-private/sheet/clipboard.ts';
import SheetApiModule from '../-private/sheet/api.ts';
import SheetRowDrag from '../-private/sheet/row-drag.ts';
import SheetRowColors from '../-private/sheet/row-colors.ts';

import type { SheetContext, SheetMessages } from '../core/index.ts';
import type { EuiSheetFieldType, EuiSheetSignature } from '../types.ts';
import type EuiI18n from '@ember-eui/core/services/eui-i18n';
import type { EuiDataGridRefProps } from '@ember-eui/core/utils/data-grid/types';
import type Owner from '@ember/owner';
import type { CellView } from '../-private/sheet/types.ts';

export type { EuiSheetSignature };
export type { CellView };

function isModal(shell: string): boolean {
  return shell === 'modal';
}

export default class EuiSheet<T extends object> extends Component<
  EuiSheetSignature<T>
> {
  @service('eui-i18n') declare euiI18n: EuiI18n;

  /* The feature modules (V03C-DESIGN.md 3.2): each owns its state. */
  readonly fields = new SheetFields<T>(this);
  readonly gridColumns = new SheetGridColumns<T>(this);
  readonly headerMenu = new SheetHeaderMenu<T>(this);
  readonly frozen = new SheetFrozen<T>(this);
  readonly gridOptions = new SheetGridOptions<T>(this);
  readonly dom = new SheetDom<T>(this);
  readonly rows = new SheetRows<T>(this);
  readonly groupHeaders = new SheetGroupHeaders<T>(this);
  readonly checked = new SheetChecked<T>(this);
  readonly cells = new SheetCells<T>(this);
  readonly selection = new SheetSelection<T>(this);
  readonly outline = new SheetOutline<T>(this);
  readonly scroll = new SheetScroll<T>(this);
  readonly ime = new SheetIme<T>(this);
  readonly focus = new SheetFocus<T>(this);
  readonly changes = new SheetChanges<T>(this);
  readonly validate = new SheetValidate<T>(this);
  readonly resolve = new SheetResolve<T>(this);
  readonly uploads = new SheetUploads<T>(this);
  readonly history = new SheetHistory<T>(this);
  readonly records = new SheetRecords<T>(this);
  readonly edit = new SheetEdit<T>(this);
  readonly expanded = new SheetExpanded<T>(this);
  readonly fieldEditor = new SheetFieldEditor<T>(this);
  readonly rowMenu = new SheetRowMenu<T>(this);
  readonly follow = new SheetFollow<T>(this);
  readonly drag = new SheetDrag<T>(this);
  readonly touch = new SheetTouch<T>(this);
  readonly clicks = new SheetClicks<T>(this);
  readonly filling = new SheetFilling<T>(this);
  readonly keys = new SheetKeys<T>(this);
  readonly clipboard = new SheetClipboard<T>(this);
  readonly api = new SheetApiModule<T>(this);
  readonly rowDrag = new SheetRowDrag<T>(this);
  readonly rowColors = new SheetRowColors<T>(this);

  /** The grid's API (not the sheet's: that is `sheetApi`). */
  gridApi: EuiDataGridRefProps | null = null;
  wrapper: HTMLElement | null = null;

  /** Stable object: the grid passes it to every cell renderer. */
  cellContext = { sheet: this as unknown as EuiSheet<object> };

  /** Messages through `eui-i18n` (each call looks its token up). */
  translatedMessages: SheetMessages = createMessages((token, def, values) =>
    this.euiI18n.lookupToken(token, def, values)
  );

  constructor(owner: Owner, args: EuiSheetSignature<T>['Args']) {
    super(owner, args);
    ensureStyles();
  }

  willDestroy(): void {
    super.willDestroy();
    if (this.outline.flashTimer) clearTimeout(this.outline.flashTimer);
    if (this.validate.validateTimer) cancel(this.validate.validateTimer);
    this.validate.validateController?.abort();
    this.validate.endValidateWaiter();
    this.drag.stopWatchingRelease();
    this.filling.stopFillDrag();
    this.drag.autoScroll.stop();
    this.rowDrag.end();
    this.touch.cancelLongPress();
    document.removeEventListener(
      'mousedown',
      this.rowMenu.onDocumentMouseDown,
      true
    );
    for (const token of [...this.resolve.pendingCalls.keys()])
      this.resolve.endCall(token);
  }

  /* -------------------------------------------------------------------- */
  /* Derived state                                                         */
  /* -------------------------------------------------------------------- */

  @cached
  get types(): Record<string, EuiSheetFieldType<any, any>> {
    return { ...builtInSheetFieldTypes, ...this.args.fieldTypes };
  }

  /** `@messages` over the `eui-i18n` translations over the English defaults. */
  @cached
  get messages(): SheetMessages {
    return { ...this.translatedMessages, ...this.args.messages };
  }

  get hasSummary(): boolean {
    return this.args.summary !== undefined;
  }

  @cached
  get context(): SheetContext<T> {
    return {
      records: this.args.records,
      fields: this.fields.visibleFields,
      getRecordId: this.args.getRecordId,
      types: this.types,
      messages: this.messages,
      readOnly: this.args.readOnly
    };
  }

  get ariaLabel(): string {
    return this.args.ariaLabel ?? 'Sheet';
  }

  get showRowNumbers(): boolean {
    return this.args.rowNumbers !== false;
  }

  get canInsert(): boolean {
    return this.args.canInsert ?? !this.args.readOnly;
  }

  get canDelete(): boolean {
    return this.args.canDelete ?? !this.args.readOnly;
  }

  /**
   * Leading control columns of the grid (V02-DESIGN.md 3.2): positions
   * (`anchor`, `head`, `Range`) use data columns, the grid's column index
   * is the data column plus this. One with row numbers.
   */
  get colOffset(): number {
    return this.showRowNumbers ? 1 : 0;
  }

  /** Identifies this sheet's own `<style>` rules. */
  sheetId = guidFor(this);

  /** The class that defines the `--euiSheet-*` colours from the EUI theme. */
  @cached
  get themeClass(): string {
    const context = getEuiThemeContext(this);
    return euiClass(context, useEuiBorealisStyles(context, sheetThemeVars));
  }

  /* -------------------------------------------------------------------- */
  /* Grid wiring                                                           */
  /* -------------------------------------------------------------------- */

  registerGridApi = (api: EuiDataGridRefProps): void => {
    this.gridApi = api;
  };

  /** Gives the owner the sheet's API, once, after the first render. */
  registerSheetApi = modifier(() => {
    afterRender(this, () => this.args.registerApi?.(this.api.sheetApi));
  });

  setupWrapper = modifier((element: HTMLElement) => {
    this.wrapper = element;
    document.addEventListener('mousedown', this.focus.onPagePress, true);
    document.addEventListener('pointerdown', this.focus.onPagePress, true);
    return () => {
      document.removeEventListener('mousedown', this.focus.onPagePress, true);
      document.removeEventListener('pointerdown', this.focus.onPagePress, true);
      this.wrapper = null;
    };
  });

  /* The empty state (V03 batch 1) */

  /** No records and not loading: a message under the grid (the add row stays the action). */
  get showEmpty(): boolean {
    return this.args.records.length === 0 && !this.args.isLoading;
  }

  <template>
    <div
      class="euiSheet
        {{this.themeClass}}
        {{if this.drag.dragging 'euiSheet--dragging'}}
        {{if this.rowDrag.active 'euiSheet--dragging euiSheet--rowDragging'}}
        {{if this.rowDrag.line.blocked 'euiSheet--rowDragBlocked'}}
        {{if this.filling.fillTarget 'euiSheet--dragging euiSheet--filling'}}
        {{if this.scroll.scrolledX 'euiSheet--scrolledX'}}
        {{if this.gridOptions.pinsAddRow 'euiSheet--pinAddRow'}}
        {{this.gridColumns.headerLinesClass}}
        {{if this.outline.rangeOutline 'euiSheet--ranged'}}
        {{if this.fieldEditor.addingField 'euiSheet--addingField'}}"
      data-test-subj="euiSheet"
      data-eui-sheet-id={{this.sheetId}}
      ...attributes
      {{this.setupWrapper}}
      {{this.follow.watchRecords @records @groups}}
      {{this.fieldEditor.watchFields @fields @hiddenFields}}
      {{this.registerSheetApi}}
      {{on "keydown" this.keys.onKeyDown capture=true}}
      {{on "copy" this.clipboard.onCopy capture=true}}
      {{on "cut" this.clipboard.onCut capture=true}}
      {{on "paste" this.clipboard.onPaste capture=true}}
      {{on "scroll" this.scroll.onScroll capture=true}}
      {{on "mousedown" this.drag.onMouseDown capture=true}}
      {{on "pointerdown" this.touch.onPointerDown capture=true}}
      {{on "pointermove" this.touch.onPointerMove}}
      {{on "pointerup" this.touch.onPointerEnd}}
      {{on "pointercancel" this.touch.onPointerEnd}}
      {{on "click" this.touch.onClickCapture capture=true}}
      {{on "focusin" this.focus.onFocusIn}}
      {{on "focusout" this.focus.onFocusOut}}
      {{on "mouseover" this.drag.onMouseOver}}
      {{on "click" this.clicks.onClick}}
      {{on "dblclick" this.clicks.onDoubleClick}}
      {{on "contextmenu" this.rowMenu.onContextMenu}}
      {{on "dragstart" this.edit.onDragStart capture=true}}
      {{on "dragover" this.uploads.onDragOver capture=true}}
      {{on "dragleave" this.uploads.onDragLeave}}
      {{on "drop" this.uploads.onDrop capture=true}}
    >
      <style data-eui-sheet-marks>
        {{this.selection.headerMarkCss}}
      </style>
      {{#if (has-block "toolbar")}}
        <div class="euiSheet__toolbar" data-test-subj="euiSheetToolbar">
          {{yield this.api.blockApi to="toolbar"}}
        </div>
      {{/if}}
      <div
        class="euiSheet__grid"
        style={{this.gridOptions.gridVars}}
        {{this.gridOptions.measureGroupWidth this.rows.isGrouped}}
      >
        {{#if @isLoading}}
          <EuiProgress
            @size="xs"
            @position="absolute"
            @color="primary"
            class="euiSheet__loading"
            data-test-subj="euiSheetLoading"
          />
        {{/if}}
        <EuiDataGrid
          aria-label={{this.ariaLabel}}
          @columns={{this.gridColumns.columns}}
          @columnVisibility={{this.fields.columnVisibility}}
          @leadingControlColumns={{this.gridColumns.leadingControlColumns}}
          @trailingControlColumns={{this.gridColumns.trailingControlColumns}}
          @gridStyle={{this.gridOptions.gridStyle}}
          @rowCount={{this.rows.rowCount}}
          @renderCellValue={{SheetCell}}
          @renderFooterCellValue={{if this.hasSummary SheetFooterCell}}
          @cellContext={{this.cellContext}}
          @registerApi={{this.registerGridApi}}
          @toolbarVisibility={{false}}
          @height={{@height}}
          @sorting={{this.gridColumns.sorting}}
          @rowHeightsOptions={{this.gridOptions.rowHeightsOptions}}
          @onColumnResize={{this.gridColumns.onColumnResize}}
          @virtualizationOptions={{this.gridOptions.virtualizationOptions}}
        >
          <:controlHeaderCell as |header|>
            {{#if (this.gridColumns.isAddFieldColumn header.columnId)}}
              {{! the "+" column (V03 6.3): a span, the header cell is the grid's focusable header }}
              <span
                class="euiSheet__addField"
                title={{(this.messages.addField)}}
                data-test-subj="euiSheetAddField"
              ><EuiIcon @type="plus" aria-hidden="true" /><span
                  class="euiSheet__srOnly"
                >{{this.messages.addField}}</span></span>
            {{else}}
              <RowNumberHeader @sheet={{this}} />
            {{/if}}
          </:controlHeaderCell>
          <:controlCell as |cell|>
            {{! the "+" column's body cells are empty and inert }}
            {{#unless (this.gridColumns.isAddFieldColumn cell.columnId)}}
              <RowNumberCell
                @sheet={{this}}
                @rowIndex={{cell.rowIndex}}
                @setCellProps={{cell.setCellProps}}
              />
            {{/unless}}
          </:controlCell>
          <:controlFooterCell as |cell|>
            {{#unless (this.gridColumns.isAddFieldColumn cell.columnId)}}
              <SheetControlFooterCell
                @sheet={{this}}
                @setCellProps={{cell.setCellProps}}
              />
            {{/unless}}
          </:controlFooterCell>
        </EuiDataGrid>
      </div>
      {{#if this.outline.copiedOutline}}
        <RangeOutline
          @sheet={{this}}
          @range={{this.outline.copiedOutline}}
          @tick={{this.scroll.layoutTick}}
          @records={{@records}}
          @columns={{this.gridColumns.columns}}
          @rowHeight={{this.gridOptions.rowHeight}}
          @kind="copied"
        />
      {{/if}}
      {{#if this.filling.fillTarget}}
        {{! the fill drag's target area, dashed (V03 batch 1) }}
        <RangeOutline
          @sheet={{this}}
          @range={{this.filling.fillTarget}}
          @tick={{this.scroll.layoutTick}}
          @records={{@records}}
          @columns={{this.gridColumns.columns}}
          @rowHeight={{this.gridOptions.rowHeight}}
          @kind="fill"
        />
      {{/if}}
      {{#if this.outline.flashOutline}}
        <RangeOutline
          @sheet={{this}}
          @range={{this.outline.flashOutline}}
          @tick={{this.scroll.layoutTick}}
          @records={{@records}}
          @columns={{this.gridColumns.columns}}
          @rowHeight={{this.gridOptions.rowHeight}}
          @kind="flash"
        />
      {{/if}}
      {{#if this.outline.rangeOutline}}
        {{! before the fill handle, which stays on top }}
        <RangeOutline
          @sheet={{this}}
          @range={{this.outline.rangeOutline}}
          @tick={{this.scroll.layoutTick}}
          @records={{@records}}
          @columns={{this.gridColumns.columns}}
          @rowHeight={{this.gridOptions.rowHeight}}
        />
      {{/if}}
      {{#if this.showEmpty}}
        <div class="euiSheet__empty" data-test-subj="euiSheetEmpty">
          {{#if (has-block "empty")}}
            {{yield this.api.blockApi to="empty"}}
          {{else}}
            {{! the add row above is the action when inserting is allowed }}
            <span role="status">{{this.messages.noRecords}}</span>
          {{/if}}
        </div>
      {{/if}}
      {{#if this.rowDrag.line}}
        <DropLine @line={{this.rowDrag.line}} />
      {{/if}}
      {{#if this.filling.fillHandleRange}}
        <FillHandle
          @sheet={{this}}
          @range={{this.filling.fillHandleRange}}
          @tick={{this.scroll.layoutTick}}
          @records={{@records}}
          @rowHeight={{this.gridOptions.rowHeight}}
          @onPress={{this.filling.onFillHandlePress}}
        />
      {{/if}}
      <ImeCatcher @sheet={{this}} />
      {{#if (has-block "footer")}}
        <div class="euiSheet__footer" data-test-subj="euiSheetFooter">
          {{yield this.api.blockApi to="footer"}}
        </div>
      {{/if}}
      {{#if this.keys.shortcutsOpen}}
        <ShortcutList @sheet={{this}} />
      {{/if}}
      {{#if this.rowMenu.menu}}
        <RowMenu
          @sheet={{this}}
          @anchor={{this.rowMenu.menuAnchor}}
          @items={{this.rowMenu.menuItems}}
          @onSelect={{this.rowMenu.onMenuSelect}}
        />
      {{/if}}
      {{#each this.fieldEditor.fieldEditorList key="@identity" as |state|}}
        <FieldEditor @sheet={{this}} @state={{state}} />
      {{/each}}
      {{#if this.expanded.expandedRecordValue}}
        {{#if (isModal this.expanded.expandedShell)}}
          <RecordModal
            @sheet={{this}}
            @record={{this.expanded.expandedRecordValue}}
          />
        {{else}}
          <RecordFlyout
            @sheet={{this}}
            @record={{this.expanded.expandedRecordValue}}
          />
        {{/if}}
      {{/if}}
      {{#each this.edit.editingList key="@identity" as |editing|}}
        <EditorFrame
          @sheet={{this}}
          @rect={{editing.rect}}
          @grow={{this.edit.growOf editing}}
          @layout={{editing.layout}}
          @onFocusOut={{this.edit.onEditorFocusOut}}
        >
          {{#if editing.type.editor}}
            <editing.type.editor
              @value={{this.edit.editorValue editing}}
              @field={{editing.field}}
              @record={{this.edit.editorRecord editing}}
              @draft={{editing.draft}}
              @initialKey={{editing.initialKey}}
              @onDraftChange={{this.edit.onDraftChange}}
              @onDraftValue={{this.edit.onDraftValue}}
              @onSave={{this.edit.onEditorSave}}
              @onUpload={{editing.onUpload}}
              @onCommit={{this.edit.onEditorCommit}}
              @onCancel={{this.edit.cancel}}
              @messages={{this.messages}}
              @themeClass={{this.themeClass}}
            />
          {{/if}}
        </EditorFrame>
      {{/each}}
      {{! always rendered, so a screen reader announces an error when it appears }}
      <div class="euiSheet__cellErrorRegion" role="status">
        {{#if this.focus.cellError}}
          <div
            class="euiSheet__cellError euiSheet__cellError--{{this.focus.cellError.placement}}
              {{if this.focus.cellError.notice 'euiSheet__cellError--notice'}}"
            data-test-subj="euiSheetCellError"
            style={{this.focus.cellError.style}}
          >
            {{#if this.focus.cellError.notice}}
              <div class="euiSheet__cellNotice"><EuiIcon
                  @type="lock"
                  @size="s"
                  aria-hidden="true"
                />{{this.messages.cellReadOnly}}</div>
            {{else}}
              {{#each this.focus.cellError.messages as |message|}}
                <div>{{message}}</div>
              {{/each}}
            {{/if}}
          </div>
        {{/if}}
      </div>
    </div>
  </template>
}
