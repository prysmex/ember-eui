import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { service } from '@ember/service';
import { htmlSafe } from '@ember/template';

import { getEuiThemeContext } from '../../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../../utils/eui/styles.ts';
import EuiButtonIcon from '../eui-button-icon.gts';

import type EuiI18n from '../../services/eui-i18n.ts';
import type EuiDataGrid from '../eui-data-grid.gts';
import type { EuiBorealisContext } from '../../utils/eui/theme.ts';
import type { RowTreeVisibleRow } from '../../utils/data-grid/row-tree.ts';

/** Ember EUI extension styles (no upstream equivalent). */
const euiDataGridTreeCellStyles = ({ euiTheme }: EuiBorealisContext) => ({
  // keeps the 24px button from growing the cell's line box
  toggle: {
    display: 'inline-flex',
    verticalAlign: 'middle',
    marginBlock: `calc(${euiTheme.size.xs} * -1)`,
    marginInlineEnd: euiTheme.size.xs,
    label: 'euiDataGridTreeCell__toggle'
  },
  spacer: {
    display: 'inline-block',
    inlineSize: euiTheme.size.l,
    marginInlineEnd: euiTheme.size.xs,
    label: 'euiDataGridTreeCell__spacer'
  },
  groupLabel: {
    fontWeight: euiTheme.font.weight.semiBold,
    label: 'euiDataGridGroupCell__label'
  },
  groupCount: {
    marginInlineStart: euiTheme.size.xs,
    color: euiTheme.colors.textSubdued,
    label: 'euiDataGridGroupCell__count'
  },
  indentSize: euiTheme.size.l
});

export interface EuiDataGridTreeCellSignature {
  Args: {
    grid: EuiDataGrid;
    row: RowTreeVisibleRow;
    columnId: string;
    colIndex: number;
    isToggleCell: boolean;
  };
}

/**
 * Tree/group parts of a cell (Ember EUI extension): in the toggle column the
 * depth indentation and the expand toggle; in group rows the group content.
 */
export default class EuiDataGridTreeCell extends Component<EuiDataGridTreeCellSignature> {
  @service declare euiI18n: EuiI18n;

  @cached
  get styles() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiDataGridTreeCellStyles);
    return {
      indentSize: styles.indentSize,
      toggle: `euiDataGridTreeCell__toggle ${euiClass(context, styles.toggle)}`,
      spacer: `euiDataGridTreeCell__spacer ${euiClass(context, styles.spacer)}`,
      groupLabel: `euiDataGridGroupCell__label ${euiClass(context, styles.groupLabel)}`,
      groupCount: `euiDataGridGroupCell__count ${euiClass(context, styles.groupCount)}`
    };
  }

  get indentStyle() {
    const depth = this.args.row.depth;
    return depth
      ? htmlSafe(`margin-inline-start:calc(${this.styles.indentSize} * ${depth})`)
      : undefined;
  }

  get toggleLabel(): string {
    return this.args.row.isExpanded
      ? this.euiI18n.lookupToken('euiDataGridRowToggle.collapse', 'Collapse row')
      : this.euiI18n.lookupToken('euiDataGridRowToggle.expand', 'Expand row');
  }

  get group() {
    return this.args.row.group;
  }

  get groupLabel(): string {
    const value = this.group?.value;
    if (value == null || value === '') {
      return this.euiI18n.lookupToken('euiDataGridGroupRow.emptyValue', '(empty)');
    }
    return value instanceof Date ? value.toLocaleString() : String(value as string);
  }

  get renderGroupCell() {
    return this.args.grid.args.grouping?.renderGroupCell;
  }

  @action
  toggle(): void {
    this.args.grid.toggleRow(this.args.row);
  }

  <template>
    {{#if @isToggleCell}}
      <span class={{if @row.hasChildren this.styles.toggle this.styles.spacer}} style={{this.indentStyle}}>
        {{#if @row.hasChildren}}
          {{! tabindex -1: not an interactive child of the cell (Space/Enter toggle) }}
          <EuiButtonIcon
            @iconType={{if @row.isExpanded "arrowDown" "arrowRight"}}
            @size="xs"
            @color="text"
            aria-label={{this.toggleLabel}}
            aria-expanded={{if @row.isExpanded "true" "false"}}
            tabindex="-1"
            data-test-subj="euiDataGridRowToggle"
            {{on "click" this.toggle}}
          />
        {{/if}}
      </span>
    {{/if}}
    {{#if this.group}}
      {{#if this.renderGroupCell}}
        {{#let this.renderGroupCell as |GroupCell|}}
          <GroupCell
            @group={{this.group}}
            @groupId={{@row.id}}
            @columnId={{@columnId}}
            @colIndex={{@colIndex}}
            @isToggleCell={{@isToggleCell}}
            @isExpanded={{@row.isExpanded}}
            @depth={{@row.depth}}
          />
        {{/let}}
      {{else if @isToggleCell}}
        <span class={{this.styles.groupLabel}}>{{this.groupLabel}}</span><span
          class={{this.styles.groupCount}}
        >({{this.group.count}})</span>
      {{/if}}
    {{/if}}
  </template>
}
