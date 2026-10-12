import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { getEuiThemeContext } from '../../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../../utils/eui/styles.ts';
import { euiDataGridToolbarStyles } from '../../utils/eui/styles.generated.ts';
import EuiScreenReaderOnly from '../eui-screen-reader-only.gts';
import EuiDataGridColumnSelector from './column-selector.gts';
import EuiDataGridColumnSorting from './column-sorting.gts';
import EuiDataGridDisplaySelector from './display-selector.gts';
import EuiDataGridFullScreenSelector from './fullscreen-selector.gts';
import EuiDataGridKeyboardShortcuts from './keyboard-shortcuts.gts';
import { checkOrDefaultToolBarDisplayOptions } from './toolbar-utils.ts';

import type EuiDataGrid from '../eui-data-grid.gts';

/** When below this width the grid only shows the right icon buttons. */
export const MINIMUM_WIDTH_FOR_GRID_CONTROLS = 479;

export interface EuiDataGridToolbarSignature {
  Args: { grid: EuiDataGrid };
  Blocks: { leftControlsPrepend: []; leftControlsAppend: []; rightControls: [] };
}

/** The grid toolbar: column, sorting, keyboard, display and fullscreen controls. */
export default class EuiDataGridToolbar extends Component<EuiDataGridToolbarSignature> {
  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiDataGridToolbarStyles);
    return {
      controls: `euiDataGrid__controls ${euiClass(context, styles.euiDataGrid__controls)}`,
      left: `euiDataGrid__leftControls ${euiClass(context, styles.euiDataGrid__leftControls)}`,
      right: `euiDataGrid__rightControls ${euiClass(context, styles.euiDataGrid__rightControls)}`
    };
  }

  get visibility() {
    return this.args.grid.args.toolbarVisibility;
  }

  /** Enables/disables the left controls based on available width. */
  get hasRoomForGridControls(): boolean {
    const { grid } = this.args;
    const min = grid.args.minSizeForControls ?? MINIMUM_WIDTH_FOR_GRID_CONTROLS;
    return grid.gridWidth > min || grid.isFullScreen;
  }

  get showColumnSelector(): boolean {
    return checkOrDefaultToolBarDisplayOptions(this.visibility, 'showColumnSelector');
  }

  get showSortSelector(): boolean {
    return (
      !!this.args.grid.args.sorting &&
      checkOrDefaultToolBarDisplayOptions(this.visibility, 'showSortSelector')
    );
  }

  get showKeyboardShortcuts(): boolean {
    return checkOrDefaultToolBarDisplayOptions(this.visibility, 'showKeyboardShortcuts');
  }

  get showDisplaySelector(): boolean {
    return checkOrDefaultToolBarDisplayOptions(this.visibility, 'showDisplaySelector');
  }

  get showFullScreenSelector(): boolean {
    return checkOrDefaultToolBarDisplayOptions(this.visibility, 'showFullScreenSelector');
  }

  get sorting() {
    return this.args.grid.args.sorting!;
  }

  <template>
    <div class={{this.classes.controls}} data-test-subj="dataGridControls">
      {{#if this.hasRoomForGridControls}}
        <div class={{this.classes.left}}>
          {{yield to="leftControlsPrepend"}}
          {{#if this.showColumnSelector}}
            <EuiDataGridColumnSelector @grid={{@grid}} />
          {{/if}}
          {{#if this.showSortSelector}}
            <EuiDataGridColumnSorting @grid={{@grid}} @sorting={{this.sorting}} />
          {{/if}}
          {{yield to="leftControlsAppend"}}
        </div>
      {{/if}}
      <div class={{this.classes.right}}>
        {{yield to="rightControls"}}
        {{#if this.showKeyboardShortcuts}}
          <EuiDataGridKeyboardShortcuts />
        {{else}}
          {{! keyboard users can still reach the shortcuts }}
          <EuiScreenReaderOnly @showOnFocus={{true}}>
            <span><EuiDataGridKeyboardShortcuts /></span>
          </EuiScreenReaderOnly>
        {{/if}}
        {{#if this.showDisplaySelector}}
          <EuiDataGridDisplaySelector @grid={{@grid}} />
        {{/if}}
        {{#if this.showFullScreenSelector}}
          <EuiDataGridFullScreenSelector @grid={{@grid}} />
        {{/if}}
      </div>
    </div>
  </template>
}
