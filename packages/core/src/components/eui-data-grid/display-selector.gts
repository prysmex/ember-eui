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

import type { TOC } from '@ember/component/template-only';
import type { ComponentLike } from '@glint/template';
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

  /** Upstream `additionalDisplaySettings`: a component appended to the popover. */
  get additionalDisplaySettings(): ComponentLike | undefined {
    const options = this.options;
    return typeof options === 'object' ? options.additionalDisplaySettings : undefined;
  }

  /** Upstream `customRender`: lays out the popover's controls. */
  get customRender(): EuiDataGridToolBarVisibilityDisplaySelectorOptions['customRender'] {
    const options = this.options;
    return typeof options === 'object' ? options.customRender : undefined;
  }

  get show(): boolean {
    return this.showDensity || this.showRowHeight || !!this.additionalDisplaySettings;
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
          {{#if this.customRender}}
            {{#let this.customRender as |CustomRender|}}
              <CustomRender
                @densityControl={{if this.showDensity (component DensityControl selector=this)}}
                @rowHeightControl={{if this.showRowHeight (component RowHeightControl selector=this)}}
                @additionalDisplaySettings={{this.additionalDisplaySettings}}
                @resetButton={{if this.showResetButton (component ResetButton selector=this)}}
              />
            {{/let}}
          {{else}}
            {{#if this.showDensity}}<DensityControl @selector={{this}} />{{/if}}
            {{#if this.showRowHeight}}<RowHeightControl @selector={{this}} />{{/if}}
            {{#if this.additionalDisplaySettings}}
              {{#let this.additionalDisplaySettings as |AdditionalDisplaySettings|}}
                <AdditionalDisplaySettings />
              {{/let}}
            {{/if}}
            {{#if this.showResetButton}}<ResetButton @selector={{this}} />{{/if}}
          {{/if}}
        </:content>
      </EuiPopover>
    {{/if}}
  </template>
}

type PartSignature = TOC<{ Args: { selector: EuiDataGridDisplaySelector } }>;

/** Density button group (upstream `densityControl`). */
const DensityControl: PartSignature = <template>
  <EuiFormRow
    @label={{@selector.t "euiDisplaySelector.densityLabel" "Density"}}
    @display="columnCompressed"
  >
    <EuiButtonGroup
      @legend={{@selector.t "euiDisplaySelector.densityLabel" "Density"}}
      @buttonSize="s"
      @isFullWidth={{true}}
      @options={{@selector.densityOptions}}
      @idSelected={{@selector.density}}
      @onChange={{@selector.setDensity}}
      data-test-subj="densityButtonGroup"
    />
  </EuiFormRow>
</template>;

/** Lines per row control (upstream `rowHeightControl`). */
const RowHeightControl: PartSignature = <template>
  <EuiFormRow
    @label={{@selector.t "euiDisplaySelector.rowHeightLabel" "Lines per row"}}
    @display="columnCompressed"
  >
    <EuiFlexGroup
      @gutterSize="s"
      @responsive={{false}}
      {{@selector.syncLineCount @selector.rowHeightsOptions.defaultHeight}}
    >
      <div class={{@selector.rowHeightGroupClass}}>
        <EuiButtonGroup
          @legend={{@selector.t "euiDisplaySelector.rowHeightLabel" "Lines per row"}}
          @buttonSize="s"
          @isFullWidth={{true}}
          @options={{@selector.rowHeightButtonOptions}}
          @idSelected={{@selector.rowHeightSelection}}
          @onChange={{@selector.setRowHeight}}
          data-test-subj="rowHeightButtonGroup"
        />
      </div>
      <EuiFieldNumber
        aria-label={{@selector.t "euiDisplaySelector.rowHeightLabel" "Lines per row"}}
        @compressed={{true}}
        @min={{1}}
        @max={{20}}
        @disabled={{if (eqStatic @selector.rowHeightSelection) false true}}
        @value={{@selector.lineCountInput}}
        data-test-subj="lineCountNumber"
        {{on "change" @selector.setLineCountHeight}}
      />
    </EuiFlexGroup>
  </EuiFormRow>
</template>;

/** Reset to default button (upstream `resetButton`). */
const ResetButton: PartSignature = <template>
  <EuiPopoverFooter>
    <EuiFlexGroup @justifyContent="flexEnd" @responsive={{false}}>
      <EuiButtonEmpty
        @flush="both"
        @size="xs"
        data-test-subj="resetDisplaySelector"
        {{on "click" @selector.args.grid.resetDisplayOptions}}
      >{{@selector.t "euiDisplaySelector.resetButtonText" "Reset to default"}}</EuiButtonEmpty>
    </EuiFlexGroup>
  </EuiPopoverFooter>
</template>;

function eqStatic(selection: string): boolean {
  return selection === 'static';
}
