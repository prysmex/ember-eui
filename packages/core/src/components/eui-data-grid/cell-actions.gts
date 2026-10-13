import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { service } from '@ember/service';

import { getEuiThemeContext } from '../../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../../utils/eui/styles.ts';
import { euiDataGridCellActionsStyles } from '../../utils/eui/styles.generated.ts';
import EuiButtonEmpty from '../eui-button-empty.gts';
import EuiButtonIcon from '../eui-button-icon.gts';
import EuiFlexGroup from '../eui-flex-group.gts';
import EuiFlexItem from '../eui-flex-item.gts';
import EuiPopoverFooter from '../eui-popover-footer.gts';
import EuiToolTip from '../eui-tool-tip.gts';

import type EuiI18n from '../../services/eui-i18n.ts';
import type {
  EuiDataGridColumn,
  EuiDataGridColumnCellAction
} from '../../utils/data-grid/types.ts';
import type { ComponentLike } from '@glint/template';
import type { TOC } from '@ember/component/template-only';

type CellActionDescriptor = Exclude<EuiDataGridColumnCellAction, ComponentLike<any>>;

/** Descriptor cell actions (Ember convenience) vs. component cell actions. */
export function isCellActionDescriptor(
  action: EuiDataGridColumnCellAction
): action is CellActionDescriptor {
  return (
    typeof action === 'object' &&
    action !== null &&
    'onClick' in action &&
    'iconType' in action
  );
}

/** Upstream `getVisibleCellActions`: primary (shown on hover) and secondary actions. */
export function getVisibleCellActions(
  cellActions?: EuiDataGridColumnCellAction[],
  visibleCellActions = 2
): [EuiDataGridColumnCellAction[], EuiDataGridColumnCellAction[]] {
  if (!cellActions) return [[], []];
  if (cellActions.length <= visibleCellActions) return [cellActions, []];
  return [
    cellActions.slice(0, visibleCellActions),
    cellActions.slice(visibleCellActions)
  ];
}

interface ActionButtonSignature {
  Element: HTMLButtonElement | HTMLAnchorElement;
  Args: { iconType?: string; isDisabled?: boolean };
  Blocks: { default: [] };
}

/**
 * The button cell actions render on hover/focus: an `xs` empty EuiButtonIcon
 * whose size and colors consumers cannot override.
 */
export class EuiDataGridCellActionButtonIcon extends Component<ActionButtonSignature> {
  @cached
  get css() {
    return useEuiBorealisStyles(getEuiThemeContext(this), euiDataGridCellActionsStyles)
      .euiDataGridRowCell__actionButtonIcon;
  }

  <template>
    <EuiButtonIcon
      aria-hidden="true"
      class="euiDataGridRowCell__actionButtonIcon"
      @css={{this.css}}
      @iconType={{@iconType}}
      @isDisabled={{@isDisabled}}
      @size="xs"
      @iconSize="s"
      @display="empty"
      @color="text"
      ...attributes
    />
  </template>
}

/** The button cell actions render in the expansion popover. */
export const EuiDataGridCellPopoverActionButton: TOC<ActionButtonSignature> = <template>
  <EuiButtonEmpty
    @size="s"
    @iconType={{@iconType}}
    @isDisabled={{@isDisabled}}
    ...attributes
  >{{yield}}</EuiButtonEmpty>
</template>;

interface CellActionsSignature {
  Args: {
    column?: EuiDataGridColumn;
    rowIndex: number;
    colIndex: number;
    onExpandClick: () => void;
  };
  Blocks: { popover: [] };
}

/** Cell actions bar shown above a hovered/focused expandable cell. */
export class EuiDataGridCellActions extends Component<CellActionsSignature> {
  @service declare euiI18n: EuiI18n;

  @cached
  get classes() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiDataGridCellActionsStyles);
    return {
      wrapper: `euiDataGridRowCell__actionsWrapper ${euiClass(context, styles.euiDataGridRowCell__actionsWrapper)}`,
      actions: `euiDataGridRowCell__actions ${euiClass(context, styles.euiDataGridRowCell__actions)}`,
      button: styles.euiDataGridRowCell__actionButtonIcon
    };
  }

  get expandButtonTitle(): string {
    return this.euiI18n.lookupToken(
      'euiDataGridCellActions.expandButtonTitle',
      'Click or hit enter to interact with cell content'
    );
  }

  get visibleActions(): EuiDataGridColumnCellAction[] {
    const column = this.args.column;
    if (!column || !Array.isArray(column.cellActions)) return [];
    return getVisibleCellActions(column.cellActions, column.visibleCellActions)[0];
  }

  get actionProps() {
    return {
      rowIndex: this.args.rowIndex,
      colIndex: this.args.colIndex,
      columnId: this.args.column?.id ?? '',
      isExpanded: false
    };
  }

  <template>
    <div class={{this.classes.wrapper}}>
      <div class={{this.classes.actions}}>
        {{#each this.visibleActions as |cellAction|}}
          {{#if (isCellActionDescriptor cellAction)}}
            <EuiDataGridCellActionButtonIcon
              @iconType={{cellAction.iconType}}
              aria-label={{cellAction.label}}
              title={{cellAction.label}}
              data-test-subj={{cellAction.data-test-subj}}
              {{on "click" (fn cellAction.onClick this.actionProps)}}
            />
          {{else}}
            {{#let cellAction as |Action|}}
              <Action
                @rowIndex={{@rowIndex}}
                @colIndex={{@colIndex}}
                @columnId={{this.actionProps.columnId}}
                @Component={{EuiDataGridCellActionButtonIcon}}
                @isExpanded={{false}}
              />
            {{/let}}
          {{/if}}
        {{/each}}
        <EuiToolTip
          @content={{this.expandButtonTitle}}
          @disableScreenReaderOutput={{true}}
          @display="flex"
        >
          <EuiButtonIcon
            aria-hidden="true"
            class="euiDataGridRowCell__actionButtonIcon euiDataGridRowCell__expandCell"
            @color="text"
            @css={{this.classes.button}}
            data-test-subj="euiDataGridCellExpandButton"
            @display="empty"
            @iconSize="s"
            @iconType="maximize"
            {{on "click" @onExpandClick}}
          />
        </EuiToolTip>
      </div>
      {{yield to="popover"}}
    </div>
  </template>
}

interface PopoverActionsSignature {
  Args: {
    column?: EuiDataGridColumn;
    rowIndex: number;
    colIndex: number;
  };
}

/** Primary and secondary cell actions in the expansion popover footer. */
export class EuiDataGridCellPopoverActions extends Component<PopoverActionsSignature> {
  get actions() {
    const column = this.args.column;
    return getVisibleCellActions(column?.cellActions, column?.visibleCellActions);
  }

  get primaryActions() {
    return this.actions[0];
  }

  get secondaryActions() {
    return this.actions[1];
  }

  get actionProps() {
    return {
      rowIndex: this.args.rowIndex,
      colIndex: this.args.colIndex,
      columnId: this.args.column?.id ?? '',
      isExpanded: true
    };
  }

  <template>
    {{#if this.primaryActions.length}}
      <EuiPopoverFooter>
        <EuiFlexGroup @gutterSize="s" @responsive={{false}} @wrap={{true}}>
          {{#each this.primaryActions as |cellAction|}}
            <EuiFlexItem>
              <div><PopoverAction @action={{cellAction}} @props={{this.actionProps}} /></div>
            </EuiFlexItem>
          {{/each}}
        </EuiFlexGroup>
      </EuiPopoverFooter>
    {{/if}}
    {{#if this.secondaryActions.length}}
      <EuiPopoverFooter>
        <EuiFlexGroup @gutterSize="s" @direction="column" @alignItems="flexStart">
          {{#each this.secondaryActions as |cellAction|}}
            <EuiFlexItem>
              <div><PopoverAction @action={{cellAction}} @props={{this.actionProps}} /></div>
            </EuiFlexItem>
          {{/each}}
        </EuiFlexGroup>
      </EuiPopoverFooter>
    {{/if}}
  </template>
}

interface PopoverActionSignature {
  Args: {
    action: EuiDataGridColumnCellAction;
    props: { rowIndex: number; colIndex: number; columnId: string; isExpanded: boolean };
  };
}

/** One cell action rendered with the popover's EuiButtonEmpty. */
const PopoverAction: TOC<PopoverActionSignature> = <template>
  {{#if (isCellActionDescriptor @action)}}
    <EuiDataGridCellPopoverActionButton
      @iconType={{@action.iconType}}
      data-test-subj={{@action.data-test-subj}}
      {{on "click" (fn @action.onClick @props)}}
    >{{@action.label}}</EuiDataGridCellPopoverActionButton>
  {{else}}
    {{#let @action as |Action|}}
      <Action
        @rowIndex={{@props.rowIndex}}
        @colIndex={{@props.colIndex}}
        @columnId={{@props.columnId}}
        @Component={{EuiDataGridCellPopoverActionButton}}
        @isExpanded={{true}}
      />
    {{/let}}
  {{/if}}
</template>;
