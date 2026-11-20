/**
 * What a cell of a group header row shows (V03 8.4, 9.1). Every cell of
 * the row renders the label and its own summary text; the CSS shows the
 * label in the row's first rendered cell only (sticky, wide) and the
 * summaries in the others, so the label stays at the left edge whichever
 * columns the grid has rendered.
 */
import Component from '@glimmer/component';
import { htmlSafe } from '@ember/template';

import EuiIcon from '@ember-eui/core/components/eui-icon';

import type EuiSheet from '../components/eui-sheet.gts';
import type { SheetGroup } from '../core/index.ts';

/** Indent per level of a nested group, in px. */
const GROUP_INDENT = 16;

interface GroupLabelSignature {
  Args: {
    sheet: EuiSheet<any>;
    group: SheetGroup;
    /** The cell's field; absent on the row-number cell (no summary there). */
    fieldId?: string;
  };
}

export default class GroupLabel extends Component<GroupLabelSignature> {
  /** `label`, else the field type's `format(value)`, or "(Empty)". */
  get title(): string {
    return this.args.sheet.groupHeaders.groupTitleOf(this.args.group);
  }

  get count(): string {
    return this.args.sheet.messages.groupCount(this.args.group.count);
  }

  get continued(): string | undefined {
    return this.args.group.continued
      ? this.args.sheet.messages.groupContinued()
      : undefined;
  }

  /** The chevron: only with `@onGroupToggle` (D2). */
  get canToggle(): boolean {
    return this.args.sheet.groupHeaders.canToggleGroups;
  }

  get chevron(): string {
    return this.args.group.collapsed ? 'arrowRight' : 'arrowDown';
  }

  get toggleLabel(): string {
    const messages = this.args.sheet.messages;
    return this.args.group.collapsed
      ? messages.expandGroup()
      : messages.collapseGroup();
  }

  get indent(): ReturnType<typeof htmlSafe> | undefined {
    const depth = Math.max(0, Math.floor(this.args.group.depth));
    return depth
      ? htmlSafe(`padding-inline-start:${depth * GROUP_INDENT}px`)
      : undefined;
  }

  get summary(): string | undefined {
    const fieldId = this.args.fieldId;
    return fieldId === undefined
      ? undefined
      : this.args.group.summary?.[fieldId];
  }

  <template>
    <span
      class="euiSheet__groupLabel"
      style={{this.indent}}
      data-test-subj="euiSheetGroupLabel"
    >
      {{~#if this.canToggle~}}
        {{! not focusable (P9): the sheet handles its click, and Enter or Space on the cell }}
        <span
          class="euiSheet__groupToggle"
          data-eui-sheet-group-toggle
          data-test-subj="euiSheetGroupToggle"
          title={{this.toggleLabel}}
          aria-hidden="true"
        ><EuiIcon @type={{this.chevron}} @size="s" /></span>
      {{~/if~}}
      <span
        class="euiSheet__groupTitle"
        data-test-subj="euiSheetGroupTitle"
        data-eui-sheet-group-toggle={{if this.canToggle "true"}}
      >{{this.title}}</span><span
        class="euiSheet__groupCount"
        data-test-subj="euiSheetGroupCount"
      >{{this.count}}</span>
      {{~#if this.continued~}}
        <span
          class="euiSheet__groupContinued"
          data-test-subj="euiSheetGroupContinued"
        >{{this.continued}}</span>
      {{~/if~}}
    </span>
    {{#if this.summary}}
      <span
        class="euiSheet__groupSummary"
        data-test-subj="euiSheetGroupSummary"
      >{{this.summary}}</span>
    {{/if}}
  </template>
}
