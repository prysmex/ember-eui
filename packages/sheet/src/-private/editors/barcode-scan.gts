/**
 * The barcode editor's scan panel (V03 10.3.2): `field.scan` when the app
 * gives one, else the browser's `BarcodeDetector` on the rear camera
 * (`getUserMedia({ video: { facingMode: 'environment' } })`), reading
 * frames until one decodes. The first code read is passed to `@onScanned`;
 * Cancel, Escape (the editor closes) or leaving stops the stream and
 * aborts `field.scan`'s signal. A refused camera shows `cameraDenied`.
 */
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { isDestroyed, isDestroying } from '@ember/destroyable';
import { modifier } from 'ember-modifier';

import EuiButtonEmpty from '@ember-eui/core/components/eui-button-empty';

import type { BarcodeField, SheetMessages } from '../../core/index.ts';

/** What `BarcodeDetector` gives per code (the part the sheet reads). */
interface DetectedCode {
  rawValue: string;
}

interface Detector {
  detect(source: HTMLVideoElement): Promise<DetectedCode[]>;
}

type DetectorClass = new (options?: { formats?: string[] }) => Detector;

/**
 * The browser's scanning parts, replaceable by tests (as `frames` of the
 * auto-scroll): `BarcodeDetector`, and the camera.
 */
export const barcodeDevice = {
  detector: (): DetectorClass | undefined =>
    (globalThis as { BarcodeDetector?: DetectorClass }).BarcodeDetector,
  camera: (): MediaDevices['getUserMedia'] | undefined => {
    const devices =
      typeof navigator === 'undefined' ? undefined : navigator.mediaDevices;
    return devices?.getUserMedia
      ? (constraints) => devices.getUserMedia(constraints)
      : undefined;
  }
};

/** Whether a field can scan here: its own `scan`, or `BarcodeDetector` and a camera API. */
export function canScan(field: BarcodeField): boolean {
  if (typeof field.scan === 'function') return true;
  return !!barcodeDevice.detector() && !!barcodeDevice.camera();
}

/** Time between two decode attempts of the camera's frames, ms. */
const DETECT_EVERY = 150;

interface BarcodeScanSignature {
  Args: {
    field: BarcodeField;
    messages: SheetMessages;
    onScanned: (text: string) => void;
    onClose: () => void;
  };
}

export default class BarcodeScan extends Component<BarcodeScanSignature> {
  @tracked error: string | null = null;
  /** The detector path draws the camera's picture. */
  @tracked showVideo = false;
  controller = new AbortController();
  stream: MediaStream | null = null;
  timer: ReturnType<typeof setTimeout> | null = null;

  get gone(): boolean {
    return (
      this.controller.signal.aborted || isDestroying(this) || isDestroyed(this)
    );
  }

  /** Starts once the panel is in the page. */
  start = modifier((element: HTMLElement) => {
    const video = element.querySelector('video');
    void this.run(video);
    return () => this.stop();
  });

  async run(video: HTMLVideoElement | null): Promise<void> {
    // after the render that installed the panel: it may set tracked state
    await Promise.resolve();
    if (this.gone) return;
    const field = this.args.field;
    const formats = field.formats;
    try {
      if (typeof field.scan === 'function') {
        const text = await field.scan({
          formats,
          signal: this.controller.signal
        });
        if (this.gone) return;
        if (text) this.args.onScanned(text);
        else this.args.onClose();
        return;
      }
      const Detector = barcodeDevice.detector();
      const camera = barcodeDevice.camera();
      if (!Detector || !camera || !video) return;
      const detector = new Detector(formats ? { formats } : undefined);
      this.showVideo = true;
      this.stream = await camera({ video: { facingMode: 'environment' } });
      if (this.gone) {
        this.stop();
        return;
      }
      video.srcObject = this.stream;
      await video.play();
      this.detect(detector, video);
    } catch (error) {
      if (this.gone) return;
      this.error =
        error instanceof DOMException &&
        (error.name === 'NotAllowedError' || error.name === 'SecurityError')
          ? this.args.messages.cameraDenied()
          : error instanceof Error
            ? error.message
            : String(error);
    }
  }

  /** Reads frames until one decodes. */
  detect(detector: Detector, video: HTMLVideoElement): void {
    this.timer = setTimeout(() => {
      this.timer = null;
      if (this.gone) return;
      detector.detect(video).then(
        (codes) => {
          if (this.gone) return;
          const text = codes.find((code) => code.rawValue)?.rawValue;
          if (text) this.args.onScanned(text);
          else this.detect(detector, video);
        },
        () => !this.gone && this.detect(detector, video)
      );
    }, DETECT_EVERY);
  }

  /** Ends the stream and aborts the app's scan. */
  stop(): void {
    if (!this.controller.signal.aborted) this.controller.abort();
    if (this.timer) clearTimeout(this.timer);
    this.timer = null;
    for (const track of this.stream?.getTracks() ?? []) track.stop();
    this.stream = null;
  }

  cancel = (): void => {
    this.stop();
    this.args.onClose();
  };

  willDestroy(): void {
    super.willDestroy();
    this.stop();
  }

  <template>
    <div
      class="euiSheet__scan"
      role="dialog"
      aria-label={{(@messages.scanBarcode)}}
      data-test-subj="euiSheetScan"
      {{this.start}}
    >
      <div class="euiSheet__scanTitle">{{@messages.scanBarcode}}</div>
      <video
        class="euiSheet__scanVideo
          {{unless this.showVideo 'euiSheet__scanVideo--off'}}"
        muted
        playsinline
        data-test-subj="euiSheetScanVideo"
      ></video>
      {{#if this.error}}
        <div
          class="euiSheet__scanError"
          role="alert"
          data-test-subj="euiSheetScanError"
        >{{this.error}}</div>
      {{/if}}
      <EuiButtonEmpty
        @size="xs"
        data-test-subj="euiSheetScanCancel"
        {{on "click" this.cancel}}
      >{{@messages.cancel}}</EuiButtonEmpty>
    </div>
  </template>
}
