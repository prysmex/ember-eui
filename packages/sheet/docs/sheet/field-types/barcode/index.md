---
title: Barcode and camera scan
order: 40
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sheet: barcode and camera scan"/>
<EuiSpacer @size="l" />

<EuiText>

A `barcode` field stores a code as text: typed, pasted, read by a USB
scanner or, where the field can scan, by the camera.

- **Barcode**: the text in a monospace font. Typing or pasting writes it;
  a USB or Bluetooth scanner types it like a keyboard and presses Enter,
  so a column can be scanned row by row. Where the field can scan (its
  own `scan`, for example a zxing wrapper, or the browser's
  `BarcodeDetector`, in Chromium-based browsers on Android, ChromeOS and
  macOS), the cell has a camera icon: it opens the editor with a scan
  panel, which reads the rear camera until a code decodes and saves it;
  Cancel or Escape stop the camera. The camera needs a secure page and
  the user's permission. The symbology is not stored.

## Related

- [All field types](/docs/sheet/docs/sheet/field-types)
- [Buttons](/docs/sheet/docs/sheet/field-types/buttons)
- [API reference](/docs/sheet/docs/sheet/more/api-reference)

</EuiText>
