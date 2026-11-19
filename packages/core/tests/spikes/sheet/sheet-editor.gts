/**
 * EuiSheet spike (DESIGN.md, section 5.7): the overlay editor, a sibling of
 * the grid inside the sheet's wrapper. One input that focuses itself on
 * insert; the sheet handles its keys from the wrapper's capture listener.
 */
import Component from '@glimmer/component';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { htmlSafe } from '@ember/template';
import { modifier } from 'ember-modifier';

export interface SheetEditorRect {
  top: number;
  left: number;
  width: number;
  height: number;
}

interface SheetEditorSignature {
  Args: {
    rect: SheetEditorRect;
    value: string;
    onInput: (value: string) => void;
    onBlur: (event: FocusEvent) => void;
  };
}

export default class SheetEditor extends Component<SheetEditorSignature> {
  get style() {
    const { top, left, width, height } = this.args.rect;
    return htmlSafe(
      `position:absolute;z-index:2;top:${top}px;left:${left}px;width:${width}px;height:${height}px;`
    );
  }

  @action
  onInput(event: Event): void {
    this.args.onInput((event.target as HTMLInputElement).value);
  }

  focusOnInsert = modifier((element: HTMLInputElement) => {
    element.focus();
    const end = element.value.length;
    element.setSelectionRange(end, end);
  });

  <template>
    <div
      class="euiSheetSpike__editor"
      data-test-subj="euiSheetEditor"
      style={{this.style}}
    >
      <input
        aria-label="Edit cell"
        style="display:block;box-sizing:border-box;width:100%;height:100%;margin:0;"
        value={{@value}}
        {{on "input" this.onInput}}
        {{on "blur" @onBlur}}
        {{this.focusOnInsert}}
      />
    </div>
  </template>
}
