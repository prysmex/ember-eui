/**
 * The browser's scanning parts and whether a barcode field can scan
 * (V03 10.3.2). The scan panel itself (`barcode-scan-panel.gts`) is loaded
 * when an editor that can scan opens (`barcode-scan-loader.ts`), so an app
 * that never scans does not load it.
 */

import type { BarcodeField } from '../../core/index.ts';

/** What `BarcodeDetector` gives per code (the part the sheet reads). */
interface DetectedCode {
  rawValue: string;
}

export interface Detector {
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
