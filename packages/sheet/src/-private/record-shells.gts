/**
 * The two shells of the expanded record (V02-DESIGN.md 5.7): an
 * `EuiFlyout` (default) or an `EuiModal`, each with a header (title,
 * previous/next; the close button is the shell's own) and the same
 * `RecordForm` as body. Both are portaled, so they carry the sheet's
 * theme class themselves.
 */
import Component from '@glimmer/component';
import { on } from '@ember/modifier';
import { guidFor } from '@ember/object/internals';

import EuiButtonIcon from '@ember-eui/core/components/eui-button-icon';
import EuiFlyout from '@ember-eui/core/components/eui-flyout';
import EuiFlyoutBody from '@ember-eui/core/components/eui-flyout-body';
import EuiFlyoutHeader from '@ember-eui/core/components/eui-flyout-header';
import EuiModal from '@ember-eui/core/components/eui-modal';
import EuiModalBody from '@ember-eui/core/components/eui-modal-body';
import EuiModalHeader from '@ember-eui/core/components/eui-modal-header';
import EuiModalHeaderTitle from '@ember-eui/core/components/eui-modal-header-title';

import RecordForm from './record-form.gts';

import type EuiSheet from '../components/eui-sheet.gts';

interface RecordShellSignature {
  Args: {
    sheet: EuiSheet<any>;
    record: unknown;
  };
}

class RecordShell extends Component<RecordShellSignature> {
  titleId = `${guidFor(this)}-title`;
  shellId = `${guidFor(this)}-shell`;

  /**
   * Where the focus trap puts focus when it starts, and again when it
   * resumes after a form editor closed: the element in the shell that has
   * focus (the next box), else the shell.
   */
  initialFocus = (): HTMLElement => {
    const shell = document.getElementById(this.shellId)!;
    const active = document.activeElement;
    return active instanceof HTMLElement && shell.contains(active)
      ? active
      : shell;
  };

  /**
   * The flyout's own defaults (it replaces them when given options), with
   * no focus return (the sheet focuses the cell the record was opened
   * from) and the initial focus above.
   */
  flyoutFocusTrapOptions = {
    allowOutsideClick: true,
    clickOutsideDeactivates: false,
    escapeDeactivates: false,
    returnFocusOnDeactivate: false,
    initialFocus: this.initialFocus,
    fallbackFocus: () => document.getElementById(this.shellId)!
  };

  get sheet(): EuiSheet<any> {
    return this.args.sheet;
  }

  get title(): string {
    return this.sheet.expanded.recordTitleOf(this.args.record);
  }

  get hasPrevious(): boolean {
    return this.sheet.expanded.expandedStep(-1) !== null;
  }

  get hasNext(): boolean {
    return this.sheet.expanded.expandedStep(1) !== null;
  }

  get closeLabel(): string {
    return this.sheet.messages.close();
  }

  get previousLabel(): string {
    return this.sheet.messages.previousRecord();
  }

  get nextLabel(): string {
    return this.sheet.messages.nextRecord();
  }

  previous = (): void => this.sheet.expanded.stepExpanded(-1);
  next = (): void => this.sheet.expanded.stepExpanded(1);
  close = (): void => this.sheet.expanded.closeExpanded();
}

export class RecordFlyout extends RecordShell {
  <template>
    <EuiFlyout
      @onClose={{this.close}}
      @size="m"
      @ownFocus={{true}}
      @closeButtonAriaLabel={{this.closeLabel}}
      @focusTrapOptions={{this.flyoutFocusTrapOptions}}
      @isFocusTrapActive={{if this.sheet.expanded.formEditorOpen false true}}
      id={{this.shellId}}
      class="euiSheetRecord {{this.sheet.themeClass}}"
      aria-labelledby={{this.titleId}}
      data-test-subj="euiSheetRecord"
      data-eui-sheet-record="flyout"
    >
      <EuiFlyoutHeader @hasBorder={{true}}>
        <div class="euiSheetRecord__header">
          <h2
            class="euiSheetRecord__title"
            id={{this.titleId}}
            data-test-subj="euiSheetRecordTitle"
          >{{this.title}}</h2>
          <EuiButtonIcon
            @iconType="arrowUp"
            @color="text"
            @isDisabled={{if this.hasPrevious false true}}
            aria-label={{this.previousLabel}}
            data-test-subj="euiSheetRecordPrevious"
            {{on "click" this.previous}}
          />
          <EuiButtonIcon
            @iconType="arrowDown"
            @color="text"
            @isDisabled={{if this.hasNext false true}}
            aria-label={{this.nextLabel}}
            data-test-subj="euiSheetRecordNext"
            {{on "click" this.next}}
          />
        </div>
      </EuiFlyoutHeader>
      <EuiFlyoutBody>
        <RecordForm @sheet={{@sheet}} @record={{@record}} />
      </EuiFlyoutBody>
    </EuiFlyout>
  </template>
}

export class RecordModal extends RecordShell {
  <template>
    <EuiModal
      @onClose={{this.close}}
      @closeButtonAriaLabel={{this.closeLabel}}
      @initialFocus={{this.initialFocus}}
      @isFocusTrapPaused={{this.sheet.expanded.formEditorOpen}}
      id={{this.shellId}}
      class="euiSheetRecord euiSheetRecord--modal {{this.sheet.themeClass}}"
      data-test-subj="euiSheetRecord"
      data-eui-sheet-record="modal"
    >
      <EuiModalHeader>
        <div class="euiSheetRecord__header">
          <EuiModalHeaderTitle
            class="euiSheetRecord__title"
            data-test-subj="euiSheetRecordTitle"
          >{{this.title}}</EuiModalHeaderTitle>
          <EuiButtonIcon
            @iconType="arrowUp"
            @color="text"
            @isDisabled={{if this.hasPrevious false true}}
            aria-label={{this.previousLabel}}
            data-test-subj="euiSheetRecordPrevious"
            {{on "click" this.previous}}
          />
          <EuiButtonIcon
            @iconType="arrowDown"
            @color="text"
            @isDisabled={{if this.hasNext false true}}
            aria-label={{this.nextLabel}}
            data-test-subj="euiSheetRecordNext"
            {{on "click" this.next}}
          />
        </div>
      </EuiModalHeader>
      <EuiModalBody>
        <RecordForm @sheet={{@sheet}} @record={{@record}} />
      </EuiModalBody>
    </EuiModal>
  </template>
}
