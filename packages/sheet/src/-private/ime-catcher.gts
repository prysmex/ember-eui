/**
 * The composition catcher (V02-DESIGN.md 8.6, V8): an input beside the
 * grid, out of the tab order and hidden from screen readers. On a key that
 * starts a composition (a dead key, an IME) on a cell, the sheet moves it
 * over the cell and focuses it inside that `keydown`, so the composition
 * happens here; the composed text then opens the cell's editor. It counts
 * as an editor surface, so the sheet's key and clipboard handlers leave
 * it alone.
 */
import Component from '@glimmer/component';
import { on } from '@ember/modifier';
import { modifier } from 'ember-modifier';

import type EuiSheet from '../components/eui-sheet.gts';

interface ImeCatcherSignature {
  Args: {
    sheet: EuiSheet<any>;
  };
}

export default class ImeCatcher extends Component<ImeCatcherSignature> {
  register = modifier((element: HTMLInputElement) => {
    this.args.sheet.imeInput = element;
    return () => {
      if (this.args.sheet.imeInput === element) {
        this.args.sheet.imeInput = null;
      }
    };
  });

  onCompositionStart = (): void => this.args.sheet.onImeCompositionStart();
  onCompositionEnd = (event: CompositionEvent): void =>
    this.args.sheet.onImeCompositionEnd(event);
  onInput = (event: Event): void =>
    this.args.sheet.onImeInput(event as InputEvent);
  onKeyDown = (event: KeyboardEvent): void =>
    this.args.sheet.onImeKeyDown(event);
  onBlur = (): void => this.args.sheet.endIme();

  <template>
    <input
      type="text"
      class="euiSheet__ime"
      data-eui-sheet-editor-surface
      data-test-subj="euiSheetImeCatcher"
      aria-hidden="true"
      tabindex="-1"
      autocomplete="off"
      {{this.register}}
      {{on "compositionstart" this.onCompositionStart}}
      {{on "compositionend" this.onCompositionEnd}}
      {{on "input" this.onInput}}
      {{on "keydown" this.onKeyDown}}
      {{on "blur" this.onBlur}}
    />
  </template>
}
