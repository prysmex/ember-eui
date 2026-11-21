/**
 * The barcode editor (V03 10.3.2): the text input, and where scanning is
 * possible (`field.scan`, or `BarcodeDetector` and a camera) a camera
 * button that opens the scan panel. A click on the cell's opener (the
 * camera) opens the editor with the panel already scanning. The first
 * code read is committed and the editor closes. A USB or Bluetooth
 * scanner types into the input like a keyboard and ends with Enter. The
 * panel is a separate chunk, loaded when an editor that can scan opens.
 */
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { modifier } from 'ember-modifier';

import EuiButtonIcon from '@ember-eui/core/components/eui-button-icon';

import { canScan } from './barcode-scan.gts';
import {
  barcodeScanPanel,
  loadBarcodeScanPanel
} from './barcode-scan-loader.ts';
import InputEditor from './input-editor.gts';

import type { BarcodeField } from '../../core/index.ts';
import type Owner from '@ember/owner';
import type { SheetEditorSignature } from '../../types.ts';

export default class BarcodeEditor extends Component<
  SheetEditorSignature<string | null, BarcodeField>
> {
  /** The scan panel is open: from the opener, or the camera button. */
  @tracked scanning = !!this.args.openedByOpener && canScan(this.args.field);

  constructor(
    owner: Owner,
    args: SheetEditorSignature<string | null, BarcodeField>['Args']
  ) {
    super(owner, args);
    // the panel is a lazy chunk: start loading it while the editor opens
    if (canScan(args.field)) void loadBarcodeScanPanel();
  }

  get canScan(): boolean {
    return canScan(this.args.field);
  }

  /** The scan panel's component, once loaded. */
  get BarcodeScan() {
    return barcodeScanPanel();
  }

  get scanLabel(): string {
    return this.args.messages.scanBarcode();
  }

  element: HTMLElement | null = null;

  setup = modifier((element: HTMLElement) => {
    this.element = element;
    return () => (this.element = null);
  });

  openScan = (): void => {
    this.scanning = true;
  };

  /** Cancel in the panel: back to the text input (focus stays in the editor). */
  closeScan = (): void => {
    this.element?.querySelector('input')?.focus();
    this.scanning = false;
  };

  onScanned = (text: string): void => {
    this.args.onCommit({ text });
  };

  <template>
    <div class="euiSheet__barcodeEditor" {{this.setup}}>
      <InputEditor
        @value={{@value}}
        @field={{@field}}
        @record={{@record}}
        @draft={{@draft}}
        @initialKey={{@initialKey}}
        @onDraftChange={{@onDraftChange}}
        @onCommit={{@onCommit}}
        @onCancel={{@onCancel}}
        @messages={{@messages}}
        @themeClass={{@themeClass}}
      />
      {{#if this.canScan}}
        <EuiButtonIcon
          @iconType="videoPlayer"
          @size="xs"
          class="euiSheet__scanButton"
          aria-label={{this.scanLabel}}
          title={{this.scanLabel}}
          data-test-subj="euiSheetScanButton"
          {{on "click" this.openScan}}
        />
      {{/if}}
      {{#if this.scanning}}
        {{#let this.BarcodeScan as |BarcodeScan|}}
          {{#if BarcodeScan}}
            <BarcodeScan
              @field={{@field}}
              @messages={{@messages}}
              @onScanned={{this.onScanned}}
              @onClose={{this.closeScan}}
            />
          {{/if}}
        {{/let}}
      {{/if}}
    </div>
  </template>
}
