import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { htmlSafe } from '@ember/template';

import { getEuiThemeContext } from '../../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../../utils/eui/styles.ts';
import { euiDataGridColumnResizerStyles } from '../../utils/eui/styles.generated.ts';
import EuiPortal from '../eui-portal.gts';

const MINIMUM_COLUMN_WIDTH = 40;

export interface EuiDataGridColumnResizerSignature {
  Args: {
    columnId: string;
    columnWidth: number;
    setColumnWidth: (columnId: string, width: number) => void;
    isLastColumn: boolean;
  };
}

/** Drag handle on a header cell's inline-end edge resizing its column. */
export default class EuiDataGridColumnResizer extends Component<EuiDataGridColumnResizerSignature> {
  @tracked offset = 0;
  private initialX = 0;

  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiDataGridColumnResizerStyles);
    return `euiDataGridColumnResizer ${euiClass(
      context,
      styles.euiDataGridColumnResizer,
      this.args.isLastColumn && styles.isLastColumn,
      this.offset !== 0 && styles.isDragging
    )}`;
  }

  get style() {
    return this.offset ? htmlSafe(`margin-inline-end:${-this.offset}px`) : undefined;
  }

  onMouseMove = (event: MouseEvent): void => {
    this.offset = Math.max(
      event.pageX - this.initialX,
      -(this.args.columnWidth - MINIMUM_COLUMN_WIDTH)
    );
  };

  onMouseUp = (): void => {
    this.args.setColumnWidth(
      this.args.columnId,
      Math.max(MINIMUM_COLUMN_WIDTH, this.args.columnWidth + this.offset)
    );
    this.offset = 0;
    this.removeListeners();
  };

  removeListeners(): void {
    window.removeEventListener('mouseup', this.onMouseUp);
    window.removeEventListener('blur', this.onMouseUp);
    window.removeEventListener('mousemove', this.onMouseMove);
  }

  @action
  onMouseDown(event: MouseEvent): void {
    this.initialX = event.pageX;
    window.addEventListener('mouseup', this.onMouseUp);
    window.addEventListener('blur', this.onMouseUp);
    window.addEventListener('mousemove', this.onMouseMove);
    // don't let this action steal focus
    event.preventDefault();
  }

  willDestroy(): void {
    super.willDestroy();
    // clean up listeners if unmounted mid-drag
    this.removeListeners();
  }

  <template>
    {{! template-lint-disable no-invalid-interactive }}
    <div
      class={{this.classes}}
      data-test-subj="dataGridColumnResizer"
      style={{this.style}}
      {{on "mousedown" this.onMouseDown}}
    >
      {{#if this.offset}}
        <EuiPortal>
          <div style="position:fixed;inset:0;cursor:ew-resize;z-index:9999"></div>
        </EuiPortal>
      {{/if}}
    </div>
  </template>
}
