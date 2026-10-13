import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { hash } from '@ember/helper';

import { getEuiThemeContext } from '../../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../../utils/eui/styles.ts';
import { euiDataGridToolbarStyles } from '../../utils/eui/styles.generated.ts';
import EuiScreenReaderOnly from '../eui-screen-reader-only.gts';
import EuiDataGridColumnSelector from './column-selector.gts';
import EuiDataGridColumnSorting from './column-sorting.gts';
import EuiDataGridDisplaySelector from './display-selector.gts';
import EuiDataGridFullScreenSelector from './fullscreen-selector.gts';
import EuiDataGridKeyboardShortcuts from './keyboard-shortcuts.gts';
import {
  checkOrDefaultToolBarDisplayOptions,
  getAdditionalControl
} from '../../utils/data-grid/toolbar.ts';

import type { TOC } from '@ember/component/template-only';
import type EuiDataGrid from '../eui-data-grid.gts';
import type { EuiDataGridCustomToolbarProps } from '../../utils/data-grid/types.ts';
import type { ComponentLike } from '@glint/template';

/** When below this width the grid only shows the right icon buttons. */
export const MINIMUM_WIDTH_FOR_GRID_CONTROLS = 479;

export interface EuiDataGridToolbarSignature {
  Args: { grid: EuiDataGrid; hasCustomToolbarBlock?: boolean };
  Blocks: {
    leftControlsPrepend: [];
    leftControlsAppend: [];
    rightControls: [];
    customToolbar: [EuiDataGridCustomToolbarProps];
  };
}

/** Keyboard shortcuts kept reachable for keyboard and screen reader users. */
const ScreenReaderKeyboardShortcuts: TOC<{ Args: Record<string, never> }> = <template>
  <EuiScreenReaderOnly @showOnFocus={{true}}>
    <span><EuiDataGridKeyboardShortcuts /></span>
  </EuiScreenReaderOnly>
</template>;

/**
 * The grid toolbar: column, sorting, keyboard, display and fullscreen
 * controls, or `@renderCustomToolbar` / the `<:customToolbar>` block given
 * those controls.
 */
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

  @cached
  get additionalControls(): EuiDataGridCustomToolbarProps['additionalControls'] {
    const visibility = this.visibility;
    return {
      leftPrepend: getAdditionalControl(visibility, 'left.prepend'),
      leftAppend: getAdditionalControl(visibility, 'left.append'),
      right: getAdditionalControl(visibility, 'right')
    };
  }

  get hasCustomToolbar(): boolean {
    return !!this.args.grid.args.renderCustomToolbar || !!this.args.hasCustomToolbarBlock;
  }

  get keyboardShortcutsControl(): ComponentLike {
    return this.showKeyboardShortcuts ? EuiDataGridKeyboardShortcuts : ScreenReaderKeyboardShortcuts;
  }

  <template>
    {{#if this.hasCustomToolbar}}
      {{#let
        (hash
          hasRoomForGridControls=this.hasRoomForGridControls
          columnControl=(if
            this.showColumnSelector (component EuiDataGridColumnSelector grid=@grid)
          )
          columnSortingControl=(if
            this.showSortSelector
            (component EuiDataGridColumnSorting grid=@grid sorting=this.sorting)
          )
          keyboardShortcutsControl=this.keyboardShortcutsControl
          displayControl=(if
            this.showDisplaySelector (component EuiDataGridDisplaySelector grid=@grid)
          )
          fullScreenControl=(if
            this.showFullScreenSelector (component EuiDataGridFullScreenSelector grid=@grid)
          )
          additionalControls=this.additionalControls
        )
        as |toolbar|
      }}
        {{#if @grid.args.renderCustomToolbar}}
          {{#let @grid.args.renderCustomToolbar as |CustomToolbar|}}
            <CustomToolbar
              @hasRoomForGridControls={{toolbar.hasRoomForGridControls}}
              @columnControl={{toolbar.columnControl}}
              @columnSortingControl={{toolbar.columnSortingControl}}
              @keyboardShortcutsControl={{toolbar.keyboardShortcutsControl}}
              @displayControl={{toolbar.displayControl}}
              @fullScreenControl={{toolbar.fullScreenControl}}
              @additionalControls={{toolbar.additionalControls}}
            />
          {{/let}}
        {{else}}
          {{yield toolbar to="customToolbar"}}
        {{/if}}
      {{/let}}
    {{else}}
      <div class={{this.classes.controls}} data-test-subj="dataGridControls">
        {{#if this.hasRoomForGridControls}}
          <div class={{this.classes.left}}>
            {{#if this.additionalControls.leftPrepend}}
              {{#let this.additionalControls.leftPrepend as |Control|}}<Control />{{/let}}
            {{/if}}
            {{yield to="leftControlsPrepend"}}
            {{#if this.showColumnSelector}}
              <EuiDataGridColumnSelector @grid={{@grid}} />
            {{/if}}
            {{#if this.showSortSelector}}
              <EuiDataGridColumnSorting @grid={{@grid}} @sorting={{this.sorting}} />
            {{/if}}
            {{#if this.additionalControls.leftAppend}}
              {{#let this.additionalControls.leftAppend as |Control|}}<Control />{{/let}}
            {{/if}}
            {{yield to="leftControlsAppend"}}
          </div>
        {{/if}}
        <div class={{this.classes.right}}>
          {{#if this.additionalControls.right}}
            {{#let this.additionalControls.right as |Control|}}<Control />{{/let}}
          {{/if}}
          {{yield to="rightControls"}}
          {{#if this.showKeyboardShortcuts}}
            <EuiDataGridKeyboardShortcuts />
          {{else}}
            {{! keyboard users can still reach the shortcuts }}
            <ScreenReaderKeyboardShortcuts />
          {{/if}}
          {{#if this.showDisplaySelector}}
            <EuiDataGridDisplaySelector @grid={{@grid}} />
          {{/if}}
          {{#if this.showFullScreenSelector}}
            <EuiDataGridFullScreenSelector @grid={{@grid}} />
          {{/if}}
        </div>
      </div>
    {{/if}}
  </template>
}
