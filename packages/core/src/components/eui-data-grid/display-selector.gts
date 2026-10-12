import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { service } from '@ember/service';

import { modifier } from 'ember-modifier';

import { afterRender } from '../../utils/data-grid/scheduling.ts';
import { getEuiThemeContext } from '../../utils/emotion/consume.ts';
import {
  euiDataGridDisplayPopoverWidth,
  euiDataGridRowHeightControlStyles
} from '../../utils/eui/data-grid.ts';
import { euiClass } from '../../utils/eui/styles.ts';
import EuiButtonEmpty from '../eui-button-empty.gts';
import EuiButtonGroup from '../eui-button-group.gts';
import EuiButtonIcon from '../eui-button-icon.gts';
import EuiFieldNumber from '../eui-field-number.gts';
import EuiFlexGroup from '../eui-flex-group.gts';
import EuiFormRow from '../eui-form-row.gts';
import EuiPopover from '../eui-popover.gts';
import EuiPopoverFooter from '../eui-popover-footer.gts';
import EuiToolTip from '../eui-tool-tip.gts';
import { getNestedObjectOptions } from '../../utils/data-grid/toolbar.ts';

import type EuiI18n from '../../services/eui-i18n.ts';
import type EuiDataGrid from '../eui-data-grid.gts';
import type {
  EuiDataGridRowHeightsOptions,
  EuiDataGridStyle,
  EuiDataGridToolBarVisibilityDisplaySelectorOptions
} from '../../utils/data-grid/types.ts';

const densityStyles: Record<string, Partial<EuiDataGridStyle>> = {
  expanded: { fontSize: 'l', cellPadding: 'l' },
  normal: { fontSize: 'm', cellPadding: 'm' },
  compact: { fontSize: 's', cellPadding: 's' }
};

function convertGridStylesToSelection(gridStyles: EuiDataGridStyle): string {
  if (gridStyles.fontSize === 's' && gridStyles.cellPadding === 's') return 'compact';
  if (gridStyles.fontSize === 'm' && gridStyles.cellPadding === 'm') return 'normal';
  if (gridStyles.fontSize === 'l' && gridStyles.cellPadding === 'l') return 'expanded';
  return '';
}

function convertRowHeightsOptionsToSelection(options: EuiDataGridRowHeightsOptions): string {
  const { defaultHeight } = options;
  // Custom pixel row height values don't have a corresponding UI element
  if (
    typeof defaultHeight === 'number' ||
    (typeof defaultHeight === 'object' && defaultHeight.height)
  ) {
    return '';
  }
  if (defaultHeight === 'auto') return 'auto';
  return 'static';
}

function isEqual(a: unknown, b: unknown): boolean {
  return JSON.stringify(a) === JSON.stringify(b);
}

export interface EuiDataGridDisplaySelectorSignature {
  Args: { grid: EuiDataGrid };
}

/** Toolbar display options popover: density and lines per row. */
export default class EuiDataGridDisplaySelector extends Component<EuiDataGridDisplaySelectorSignature> {
  @service declare euiI18n: EuiI18n;

  @tracked isOpen = false;
  @tracked lineCountInput = 1;

  t = (token: string, fallback: string): string => this.euiI18n.lookupToken(token, fallback);

  get options(): boolean | EuiDataGridToolBarVisibilityDisplaySelectorOptions | undefined {
    const visibility = this.args.grid.args.toolbarVisibility;
    if (visibility === undefined || typeof visibility === 'boolean') return visibility ?? true;
    return visibility.showDisplaySelector;
  }

  get showDensity(): boolean {
    return getNestedObjectOptions(this.options, 'allowDensity');
  }

  get showRowHeight(): boolean {
    return getNestedObjectOptions(this.options, 'allowRowHeight');
  }

  get show(): boolean {
    return this.showDensity || this.showRowHeight;
  }

  /* density -------------------------------------------------------------- */

  get densityOptions() {
    return [
      { id: 'compact', label: this.t('euiDisplaySelector.labelCompact', 'Compact'), 'data-test-subj': 'compact' },
      { id: 'normal', label: this.t('euiDisplaySelector.labelNormal', 'Normal'), 'data-test-subj': 'normal' },
      { id: 'expanded', label: this.t('euiDisplaySelector.labelExpanded', 'Expanded'), 'data-test-subj': 'expanded' }
    ];
  }

  get density(): string {
    return convertGridStylesToSelection(this.args.grid.gridStyles);
  }

  @action
  setDensity(density: string): void {
    const styles = densityStyles[density];
    if (styles) this.args.grid.onUserGridStyleChange(styles);
  }

  /* row height ------------------------------------------------------------ */

  get rowHeightsOptions(): EuiDataGridRowHeightsOptions {
    return this.args.grid.rowHeightsOptions;
  }

  get rowHeightSelection(): string {
    return convertRowHeightsOptionsToSelection(this.rowHeightsOptions);
  }

  get rowHeightButtonOptions() {
    return [
      { id: 'auto', label: this.t('euiDisplaySelector.labelAuto', 'Auto'), 'data-test-subj': 'auto' },
      {
        id: 'static',
        label: this.rowHeightsOptions.autoBelowLineCount
          ? this.t('euiDisplaySelector.labelMax', 'Max')
          : this.t('euiDisplaySelector.labelStatic', 'Static'),
        'data-test-subj': 'static'
      }
    ];
  }

  /** Reflect consumer `lineCount` changes (and resets) in the number input. */
  syncLineCount = modifier((_element: HTMLElement, [defaultHeight]: [unknown]) => {
    const passed =
      typeof defaultHeight === 'object' && defaultHeight
        ? (defaultHeight as { lineCount?: number }).lineCount
        : undefined;
    const next = passed ? passed : defaultHeight === undefined ? 1 : undefined;
    if (next !== undefined && next !== this.lineCountInput) {
      // applied after render: the input already consumed the value
      afterRender(this, () => {
        this.lineCountInput = next;
      });
    }
  });

  @action
  setRowHeight(option: string): void {
    const options: EuiDataGridRowHeightsOptions = { rowHeights: {} };
    if (option === 'auto') {
      options.defaultHeight = 'auto';
    } else if (option === 'static') {
      const lineCount = Number(this.lineCountInput);
      // lineCount: 1 is the same as single/undefined
      options.defaultHeight = lineCount > 1 ? { lineCount } : undefined;
    }
    this.args.grid.onUserRowHeightChange(options);
  }

  @action
  setLineCountHeight(event: Event): void {
    const newLineCount = Number((event.target as HTMLInputElement).value);
    this.lineCountInput = newLineCount;
    this.args.grid.onUserRowHeightChange({
      rowHeights: {}, // Unset all row-specific line counts
      defaultHeight: newLineCount > 1 ? { lineCount: newLineCount } : undefined
    });
  }

  /* reset ------------------------------------------------------------------ */

  get showResetButton(): boolean {
    if (!getNestedObjectOptions(this.options, 'allowResetButton')) return false;
    const { grid } = this.args;
    const initialStyles = grid.initialGridStyles ?? {};
    const initialRowHeights = grid.initialRowHeightsOptions ?? {};
    return (
      !isEqual(this.rowHeightsOptions.defaultHeight, initialRowHeights.defaultHeight) ||
      grid.gridStyles.fontSize !== initialStyles.fontSize ||
      grid.gridStyles.cellPadding !== initialStyles.cellPadding
    );
  }

  /* popover ---------------------------------------------------------------- */

  @cached
  get panelStyle(): Record<string, string> {
    return { inlineSize: euiDataGridDisplayPopoverWidth(getEuiThemeContext(this).upstream) };
  }

  @cached
  get rowHeightGroupClass(): string {
    return euiClass(getEuiThemeContext(this), euiDataGridRowHeightControlStyles);
  }

  get buttonLabel(): string {
    return this.t('euiDisplaySelector.buttonText', 'Display options');
  }

  @action
  toggle(): void {
    this.isOpen = !this.isOpen;
  }

  @action
  close(): void {
    this.isOpen = false;
  }

  <template>
    {{#if this.show}}
      <EuiPopover
        data-test-subj="dataGridDisplaySelectorPopover"
        @isOpen={{this.isOpen}}
        @closePopover={{this.close}}
        @anchorPosition="downRight"
        @panelPaddingSize="s"
        @panelStyle={{this.panelStyle}}
        @panelClassName="euiDataGrid__displayPopoverPanel"
      >
        <:button>
          <EuiToolTip @content={{this.buttonLabel}} @disableScreenReaderOutput={{true}}>
            <EuiButtonIcon
              @size="xs"
              @iconType="controls"
              @color="text"
              data-test-subj="dataGridDisplaySelectorButton"
              aria-label={{this.buttonLabel}}
              {{on "click" this.toggle}}
            />
          </EuiToolTip>
        </:button>
        <:content>
          {{#if this.showDensity}}
            <EuiFormRow
              @label={{this.t "euiDisplaySelector.densityLabel" "Density"}}
              @display="columnCompressed"
            >
              <EuiButtonGroup
                @legend={{this.t "euiDisplaySelector.densityLabel" "Density"}}
                @buttonSize="s"
                @isFullWidth={{true}}
                @options={{this.densityOptions}}
                @idSelected={{this.density}}
                @onChange={{this.setDensity}}
                data-test-subj="densityButtonGroup"
              />
            </EuiFormRow>
          {{/if}}
          {{#if this.showRowHeight}}
            <EuiFormRow
              @label={{this.t "euiDisplaySelector.rowHeightLabel" "Lines per row"}}
              @display="columnCompressed"
            >
              <EuiFlexGroup
                @gutterSize="s"
                @responsive={{false}}
                {{this.syncLineCount this.rowHeightsOptions.defaultHeight}}
              >
                <div class={{this.rowHeightGroupClass}}>
                  <EuiButtonGroup
                    @legend={{this.t "euiDisplaySelector.rowHeightLabel" "Lines per row"}}
                    @buttonSize="s"
                    @isFullWidth={{true}}
                    @options={{this.rowHeightButtonOptions}}
                    @idSelected={{this.rowHeightSelection}}
                    @onChange={{this.setRowHeight}}
                    data-test-subj="rowHeightButtonGroup"
                  />
                </div>
                <EuiFieldNumber
                  aria-label={{this.t "euiDisplaySelector.rowHeightLabel" "Lines per row"}}
                  @compressed={{true}}
                  @min={{1}}
                  @max={{20}}
                  @disabled={{if (eqStatic this.rowHeightSelection) false true}}
                  @value={{this.lineCountInput}}
                  data-test-subj="lineCountNumber"
                  {{on "change" this.setLineCountHeight}}
                />
              </EuiFlexGroup>
            </EuiFormRow>
          {{/if}}
          {{#if this.showResetButton}}
            <EuiPopoverFooter>
              <EuiFlexGroup @justifyContent="flexEnd" @responsive={{false}}>
                <EuiButtonEmpty
                  @flush="both"
                  @size="xs"
                  data-test-subj="resetDisplaySelector"
                  {{on "click" @grid.resetDisplayOptions}}
                >{{this.t "euiDisplaySelector.resetButtonText" "Reset to default"}}</EuiButtonEmpty>
              </EuiFlexGroup>
            </EuiPopoverFooter>
          {{/if}}
        </:content>
      </EuiPopover>
    {{/if}}
  </template>
}

function eqStatic(selection: string): boolean {
  return selection === 'static';
}
