/**
 * What a cell of a group header row shows (V03 8.4, 9.1). Every cell of
 * the row renders the label and its own summary text; the CSS shows the
 * label in the row's first rendered cell only (sticky, wide) and the
 * summaries in the others, so the label stays at the left edge whichever
 * columns the grid has rendered.
 */
import Component from '@glimmer/component';
import { htmlSafe } from '@ember/template';

import type { SheetGroup } from '../core/index.ts';

/** Indent per level of a nested group, in px. */
const GROUP_INDENT = 16;

interface GroupLabelSignature {
  Args: {
    group: SheetGroup;
    /** The cell's field; absent on the row-number cell (no summary there). */
    fieldId?: string;
  };
}

export default class GroupLabel extends Component<GroupLabelSignature> {
  get label(): string {
    const { label, value } = this.args.group;
    if (label !== undefined) return label;
    // stage 3: the grouped field's `type.format(value)`, `messages.groupEmpty()`
    return typeof value === 'string' ||
      typeof value === 'number' ||
      typeof value === 'boolean'
      ? String(value)
      : '';
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
    ><span class="euiSheet__groupTitle">{{this.label}}</span><span
        class="euiSheet__groupCount"
      >{{@group.count}}</span></span>
    {{#if this.summary}}
      <span
        class="euiSheet__groupSummary"
        data-test-subj="euiSheetGroupSummary"
      >{{this.summary}}</span>
    {{/if}}
  </template>
}
